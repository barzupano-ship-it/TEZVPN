package ru.tezvpn.app.ui

import android.app.Application
import android.net.Uri
import android.net.VpnService
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.isActive
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import ru.tezvpn.app.TezApp
import ru.tezvpn.app.api.ShopApi
import ru.tezvpn.app.api.ShopState
import ru.tezvpn.app.vpn.VpnController

data class UiState(
    val loading: Boolean = true,
    val busy: Boolean = false,
    val shop: ShopState = ShopState(),
    val vpnOn: Boolean = false,
    val connecting: Boolean = false,
    val message: String? = null,
    val error: String? = null,
    val nameDraft: String = "",
    val loginDraft: String = "",
    val screen: String = "home",
)

class ShopViewModel(app: Application) : AndroidViewModel(app) {
    private val api = ShopApi(app)
    val vpn = VpnController(app)

    private val _ui = MutableStateFlow(UiState())
    val ui: StateFlow<UiState> = _ui

    private var pollJob: Job? = null

    init {
        refresh()
    }

    fun refresh() {
        viewModelScope.launch {
            _ui.update { it.copy(loading = true, error = null) }
            try {
                val shop = api.state()
                applyShop(shop, loading = false)
                maybeAutoConnect(shop)
            } catch (e: Exception) {
                _ui.update { it.copy(loading = false, error = e.message?.ifBlank { null } ?: "Нет связи с сервером") }
            }
        }
    }

    fun buy(planId: String) {
        viewModelScope.launch {
            _ui.update { it.copy(busy = true, error = null) }
            try {
                api.startOrder(planId)
                val shop = api.state()
                applyShop(shop, busy = false, screen = "order")
            } catch (e: Exception) {
                _ui.update { it.copy(busy = false, error = e.message) }
            }
        }
    }

    fun setNameDraft(v: String) = _ui.update { it.copy(nameDraft = v) }
    fun setLoginDraft(v: String) = _ui.update { it.copy(loginDraft = v) }
    fun go(screen: String) = _ui.update { it.copy(screen = screen) }

    fun submitName() {
        val name = _ui.value.nameDraft.trim()
        if (name.length < 2) {
            _ui.update { it.copy(error = "Введите имя") }
            return
        }
        viewModelScope.launch {
            _ui.update { it.copy(busy = true, error = null) }
            try {
                api.setName(name)
                val shop = api.state()
                applyShop(shop, busy = false, screen = "pay")
            } catch (e: Exception) {
                _ui.update { it.copy(busy = false, error = e.message) }
            }
        }
    }

    fun uploadReceipt(uri: Uri) {
        viewModelScope.launch {
            _ui.update { it.copy(busy = true, error = null, message = "Отправляем чек…") }
            try {
                val bytes = getApplication<TezApp>().contentResolver.openInputStream(uri)?.use { it.readBytes() }
                    ?: throw IllegalStateException("Не удалось прочитать файл")
                val name = uri.lastPathSegment?.substringAfterLast('/') ?: "receipt.jpg"
                api.uploadReceipt(bytes, name)
                val shop = api.state()
                applyShop(shop, busy = false, screen = "order", message = "Чек отправлен. Ждём подтверждение — VPN включится сам.")
                startPolling()
            } catch (e: Exception) {
                _ui.update { it.copy(busy = false, error = e.message, message = null) }
            }
        }
    }

    fun login() {
        val code = _ui.value.loginDraft.trim()
        viewModelScope.launch {
            _ui.update { it.copy(busy = true, error = null) }
            try {
                val shop = api.login(code)
                applyShop(shop, busy = false, screen = "home", message = "Вход выполнен")
                maybeAutoConnect(shop)
            } catch (e: Exception) {
                _ui.update { it.copy(busy = false, error = e.message) }
            }
        }
    }

    fun toggleVpn() {
        val shop = _ui.value.shop
        val conf = shop.config?.devices?.firstOrNull()?.conf
        viewModelScope.launch {
            try {
                if (vpn.isUp()) {
                    vpn.disconnect()
                    _ui.update { it.copy(vpnOn = false, message = "VPN выключен") }
                } else {
                    if (conf.isNullOrBlank()) {
                        _ui.update { it.copy(error = "Сначала купите тариф") }
                        return@launch
                    }
                    _ui.update { it.copy(connecting = true, error = null) }
                    vpn.connect(conf)
                    _ui.update { it.copy(connecting = false, vpnOn = true, screen = "vpn", message = "VPN включён") }
                }
            } catch (e: Exception) {
                _ui.update { it.copy(connecting = false, error = e.message) }
            }
        }
    }

    fun connectAfterPermission() {
        val conf = _ui.value.shop.config?.devices?.firstOrNull()?.conf ?: vpn.lastConf
        if (conf.isBlank()) return
        viewModelScope.launch {
            _ui.update { it.copy(connecting = true, error = null) }
            try {
                vpn.connect(conf)
                _ui.update { it.copy(connecting = false, vpnOn = true, screen = "vpn", message = "VPN включён") }
            } catch (e: Exception) {
                _ui.update { it.copy(connecting = false, error = e.message) }
            }
        }
    }

    private fun startPolling() {
        pollJob?.cancel()
        pollJob = viewModelScope.launch {
            repeat(80) {
                if (!isActive) return@launch
                delay(4000)
                try {
                    val shop = api.state()
                    applyShop(shop)
                    if (maybeAutoConnect(shop)) return@launch
                    val st = shop.order?.status
                    if (st in listOf("rejected", "disabled", "expired", "failed")) return@launch
                } catch (_: Exception) {
                }
            }
        }
    }

    private suspend fun maybeAutoConnect(shop: ShopState): Boolean {
        val conf = shop.config?.devices?.firstOrNull()?.conf
        val ready = shop.order?.ready == true && !conf.isNullOrBlank()
        if (!ready || vpn.isUp()) return ready
        if (VpnService.prepare(getApplication()) != null) {
            _ui.update {
                it.copy(
                    connecting = false,
                    screen = "vpn",
                    message = "Оплата принята. Нажмите кнопку и разрешите VPN — подключение сразу.",
                )
            }
            return false
        }
        _ui.update { it.copy(connecting = true, screen = "vpn", message = "Оплата принята. Подключаем VPN…") }
        return try {
            vpn.connect(conf!!)
            _ui.update { it.copy(connecting = false, vpnOn = true, message = "VPN включён") }
            true
        } catch (e: Exception) {
            _ui.update { it.copy(connecting = false, error = e.message, screen = "vpn") }
            false
        }
    }

    private fun applyShop(
        shop: ShopState,
        loading: Boolean = false,
        busy: Boolean = false,
        screen: String? = null,
        message: String? = _ui.value.message,
    ) {
        val nextScreen = screen ?: when {
            shop.order?.ready == true -> "vpn"
            shop.order?.status == "pending" -> "pay"
            shop.order?.status == "awaiting_name" -> "order"
            shop.order?.status in listOf("waiting_review", "paid") -> "order"
            else -> _ui.value.screen
        }
        _ui.update {
            it.copy(
                loading = loading,
                busy = busy,
                shop = shop,
                vpnOn = vpn.isUp(),
                screen = nextScreen,
                message = message ?: shop.flash,
                nameDraft = it.nameDraft.ifBlank { shop.order?.name.orEmpty() },
            )
        }
        if (shop.order?.status in listOf("waiting_review", "paid") && pollJob?.isActive != true) {
            startPolling()
        }
    }
}

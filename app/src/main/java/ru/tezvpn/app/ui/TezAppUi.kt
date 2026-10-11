package ru.tezvpn.app.ui

import android.content.Intent
import android.net.Uri
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.RowScope
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.PowerSettingsNew
import androidx.compose.material.icons.outlined.CreditCard
import androidx.compose.material.icons.outlined.HelpOutline
import androidx.compose.material.icons.outlined.Person
import androidx.compose.material.icons.outlined.ShoppingBag
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.NavigationBarItemDefaults
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.OutlinedTextFieldDefaults
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import ru.tezvpn.app.BuildConfig
import ru.tezvpn.app.api.Order
import ru.tezvpn.app.api.Plan

@Composable
fun TezAppUi(
    vm: ShopViewModel,
    onPickReceipt: () -> Unit,
    onPower: () -> Unit,
) {
    val ui by vm.ui.collectAsState()
    val gold = Color(0xFFF5C518)
    Scaffold(
        containerColor = Color(0xFF0C2438),
        bottomBar = {
            NavigationBar(containerColor = Color(0xFF16324F)) {
                Nav("vpn", "VPN", ui.screen) { vm.go("vpn") }
                Nav("home", "Тарифы", ui.screen) { vm.go("home") }
                Nav("pay", "Оплата", ui.screen) { vm.go("pay") }
                Nav("account", "Кабинет", ui.screen) { vm.go("account") }
            }
        },
    ) { pad ->
        Column(
            Modifier
                .fillMaxSize()
                .padding(pad)
                .padding(16.dp)
                .verticalScroll(rememberScrollState()),
        ) {
            Text("TEZVPN", fontSize = 28.sp, fontWeight = FontWeight.ExtraBold, color = gold)
            Text("VPN включается в этом приложении сразу после оплаты", color = Color(0xFF9DB0C3))
            Spacer(Modifier.height(12.dp))
            if (ui.loading) {
                CircularProgressIndicator(color = gold)
                return@Column
            }
            ui.error?.let { Text(it, color = Color(0xFFFF8A80), modifier = Modifier.padding(bottom = 8.dp)) }
            ui.message?.let { Text(it, color = gold, modifier = Modifier.padding(bottom = 8.dp)) }
            if (ui.busy || ui.connecting) {
                CircularProgressIndicator(color = gold, modifier = Modifier.size(28.dp))
                Spacer(Modifier.height(8.dp))
            }
            when (ui.screen) {
                "vpn" -> VpnScreen(ui, vm, onPower)
                "home" -> PlansScreen(ui, vm)
                "pay" -> PayScreen(ui, vm, onPickReceipt)
                "order" -> OrderScreen(ui, vm, onPickReceipt)
                "account" -> AccountScreen(ui, vm)
                else -> PlansScreen(ui, vm)
            }
        }
    }
}

@Composable
private fun RowScope.Nav(id: String, label: String, current: String, onClick: () -> Unit) {
    NavigationBarItem(
        selected = current == id || (id == "home" && current == "order"),
        onClick = onClick,
        icon = {
            Icon(
                when (id) {
                    "vpn" -> Icons.Filled.PowerSettingsNew
                    "pay" -> Icons.Outlined.CreditCard
                    "account" -> Icons.Outlined.Person
                    else -> Icons.Outlined.ShoppingBag
                },
                contentDescription = label,
            )
        },
        label = { Text(label) },
        colors = NavigationBarItemDefaults.colors(
            selectedIconColor = Color(0xFF111111),
            selectedTextColor = Color(0xFFF5C518),
            indicatorColor = Color(0xFFF5C518),
            unselectedIconColor = Color(0xFF9DB0C3),
            unselectedTextColor = Color(0xFF9DB0C3),
        ),
    )
}

@Composable
private fun VpnScreen(ui: UiState, vm: ShopViewModel, onPower: () -> Unit) {
    val ready = ui.shop.config?.devices?.firstOrNull()?.conf?.isNotBlank() == true
    val order = ui.shop.order
    Column(horizontalAlignment = Alignment.CenterHorizontally, modifier = Modifier.fillMaxWidth()) {
        Spacer(Modifier.height(24.dp))
        Button(
            onClick = {
                if (!ready && !ui.vpnOn) vm.go("home")
                else onPower()
            },
            modifier = Modifier.size(160.dp),
            shape = CircleShape,
            colors = ButtonDefaults.buttonColors(
                containerColor = if (ui.vpnOn) Color(0xFF1FA971) else Color(0xFFF5C518),
                contentColor = Color(0xFF111111),
            ),
        ) {
            Column(horizontalAlignment = Alignment.CenterHorizontally) {
                Icon(Icons.Filled.PowerSettingsNew, null, modifier = Modifier.size(48.dp))
                Text(if (ui.vpnOn) "ВКЛ" else if (ready) "ВКЛЮЧИТЬ" else "КУПИТЬ", fontWeight = FontWeight.ExtraBold)
            }
        }
        Spacer(Modifier.height(16.dp))
        Text(
            when {
                ui.connecting -> "Подключаем…"
                ui.vpnOn -> "Интернет идёт через TEZVPN"
                ready -> "Конфиг готов — нажмите, чтобы включить"
                order?.status == "waiting_review" -> "Чек на проверке. VPN включится сам."
                else -> "Купите тариф — VPN подключится сразу после оплаты"
            },
            color = Color.White,
            fontWeight = FontWeight.Bold,
        )
        if (ready) {
            Text(
                ui.shop.config?.devices?.firstOrNull()?.name ?: "",
                color = Color(0xFF9DB0C3),
                modifier = Modifier.padding(top = 8.dp),
            )
        }
        if (order != null && !ready) {
            StatusCard(order)
        }
    }
}

@Composable
private fun PlansScreen(ui: UiState, vm: ShopViewModel) {
    Text("Тарифы", fontSize = 20.sp, fontWeight = FontWeight.Bold, color = Color.White)
    Spacer(Modifier.height(8.dp))
    ui.shop.plans.forEach { plan ->
        PlanCard(plan) { vm.buy(plan.id) }
        Spacer(Modifier.height(10.dp))
    }
    if (ui.shop.plans.isEmpty()) {
        Text("Не загрузились тарифы. Проверьте интернет.", color = Color(0xFF9DB0C3))
        Button(onClick = { vm.refresh() }) { Text("Обновить") }
    }
}

@Composable
private fun PlanCard(plan: Plan, onBuy: () -> Unit) {
    Column(
        Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(16.dp))
            .background(Color(0xFF16324F))
            .padding(16.dp),
    ) {
        Text(plan.title, fontWeight = FontWeight.ExtraBold, color = Color.White, fontSize = 18.sp)
        Text(
            "${plan.tjs.toInt()} смн · ¥${plan.cny.toInt()} · ${plan.devices} устр.",
            color = Color(0xFFF5C518),
        )
        Spacer(Modifier.height(8.dp))
        Button(
            onClick = onBuy,
            colors = ButtonDefaults.buttonColors(containerColor = Color(0xFFF5C518), contentColor = Color(0xFF111111)),
        ) { Text("Купить", fontWeight = FontWeight.Bold) }
    }
}

@Composable
private fun OrderScreen(ui: UiState, vm: ShopViewModel, onPickReceipt: () -> Unit) {
    val o = ui.shop.order
    Text("Заказ", fontSize = 20.sp, fontWeight = FontWeight.Bold, color = Color.White)
    Spacer(Modifier.height(8.dp))
    if (o == null) {
        Text("Заказа нет. Выберите тариф.", color = Color(0xFF9DB0C3))
        Button(onClick = { vm.go("home") }) { Text("К тарифам") }
        return
    }
    StatusCard(o)
    Spacer(Modifier.height(12.dp))
    when (o.status) {
        "awaiting_name" -> {
            OutlinedTextField(
                value = ui.nameDraft,
                onValueChange = vm::setNameDraft,
                label = { Text("Ваше имя") },
                modifier = Modifier.fillMaxWidth(),
                colors = fieldColors(),
            )
            Spacer(Modifier.height(8.dp))
            Button(onClick = { vm.submitName() }) { Text("Продолжить") }
        }
        "pending" -> {
            Text("Переведите по реквизитам и загрузите фото чека.", color = Color.White)
            Spacer(Modifier.height(8.dp))
            Button(onClick = { vm.go("pay") }) { Text("Реквизиты") }
            Spacer(Modifier.height(8.dp))
            Button(onClick = onPickReceipt) { Text("Загрузить чек") }
        }
        "waiting_review", "paid" -> {
            Text("Ждём подтверждение администратора. VPN включится автоматически.", color = Color.White)
            OutlinedButton(onClick = { vm.refresh() }) { Text("Обновить статус") }
        }
        "fulfilled" -> {
            Text("Готово. Можно включать VPN.", color = Color(0xFFF5C518))
            Button(onClick = { vm.go("vpn") }) { Text("Открыть VPN") }
        }
        "rejected" -> {
            Text("Чек отклонён. Выберите тариф заново.", color = Color(0xFFFF8A80))
            Button(onClick = { vm.go("home") }) { Text("К тарифам") }
        }
        "disabled" -> Text("Доступ отключён администратором.", color = Color(0xFFFF8A80))
    }
}

@Composable
private fun PayScreen(ui: UiState, vm: ShopViewModel, onPickReceipt: () -> Unit) {
    val pay = ui.shop.pay
    val ctx = LocalContext.current
    Text("Оплата", fontSize = 20.sp, fontWeight = FontWeight.Bold, color = Color.White)
    Spacer(Modifier.height(8.dp))
    Column(
        Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(16.dp))
            .background(Color(0xFF16324F))
            .padding(16.dp),
    ) {
        if (pay.payee.isNotBlank()) Text("Получатель: ${pay.payee}", color = Color.White)
        if (pay.alif.isNotBlank()) Text("Alif: ${pay.alif}", color = Color.White, modifier = Modifier.padding(top = 8.dp))
        if (pay.dc.isNotBlank()) Text("DC: ${pay.dc}", color = Color.White, modifier = Modifier.padding(top = 8.dp))
        if (pay.payee.isBlank() && pay.alif.isBlank()) Text("Реквизиты загружаются…", color = Color(0xFF9DB0C3))
    }
    Spacer(Modifier.height(10.dp))
    if (pay.wechat) {
        TextButton(onClick = {
            ctx.startActivity(Intent(Intent.ACTION_VIEW, Uri.parse("${ru.tezvpn.app.BuildConfig.SHOP_URL}/pay/wechat.png")))
        }) { Text("QR WeChat") }
    }
    if (pay.alipay) {
        TextButton(onClick = {
            ctx.startActivity(Intent(Intent.ACTION_VIEW, Uri.parse("${ru.tezvpn.app.BuildConfig.SHOP_URL}/pay/alipay.png")))
        }) { Text("QR Alipay") }
    }
    Button(onClick = onPickReceipt) { Text("Я оплатил — загрузить чек") }
    Spacer(Modifier.height(8.dp))
    SupportLink(ui.shop.meta.support.ifBlank { BuildConfig.SUPPORT })
}

@Composable
private fun AccountScreen(ui: UiState, vm: ShopViewModel) {
    Text("Кабинет", fontSize = 20.sp, fontWeight = FontWeight.Bold, color = Color.White)
    Spacer(Modifier.height(8.dp))
    Text("Код доступа: ${ui.shop.account?.code ?: "—"}", color = Color.White)
    Text("Сохраните код, чтобы войти с другого телефона.", color = Color(0xFF9DB0C3))
    Spacer(Modifier.height(12.dp))
    OutlinedTextField(
        value = ui.loginDraft,
        onValueChange = vm::setLoginDraft,
        label = { Text("Войти по коду") },
        modifier = Modifier.fillMaxWidth(),
        colors = fieldColors(),
    )
    Spacer(Modifier.height(8.dp))
    Button(onClick = { vm.login() }) { Text("Войти") }
    Spacer(Modifier.height(16.dp))
    SupportLink(ui.shop.meta.support.ifBlank { BuildConfig.SUPPORT })
}

@Composable
private fun StatusCard(o: Order) {
    Column(
        Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(16.dp))
            .background(Color(0xFF16324F))
            .padding(16.dp),
    ) {
        Text(o.title.ifBlank { o.plan }, fontWeight = FontWeight.Bold, color = Color.White)
        Text(o.statusLabel.ifBlank { o.status }, color = Color(0xFFF5C518))
        if (o.amount.isNotBlank()) Text("${o.amount} смн", color = Color(0xFF9DB0C3))
        if (o.name.isNotBlank()) Text(o.name, color = Color(0xFF9DB0C3))
    }
}

@Composable
private fun SupportLink(user: String) {
    val ctx = LocalContext.current
    TextButton(onClick = {
        ctx.startActivity(Intent(Intent.ACTION_VIEW, Uri.parse("https://t.me/${user.trimStart('@')}")) )
    }) {
        Icon(Icons.Outlined.HelpOutline, null)
        Text("  Поддержка @$user")
    }
}

@Composable
private fun fieldColors() = OutlinedTextFieldDefaults.colors(
    focusedTextColor = Color.White,
    unfocusedTextColor = Color.White,
    focusedBorderColor = Color(0xFFF5C518),
    unfocusedBorderColor = Color(0xFF9DB0C3),
    focusedLabelColor = Color(0xFFF5C518),
    unfocusedLabelColor = Color(0xFF9DB0C3),
)

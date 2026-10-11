package ru.tezvpn.app.api

data class ShopState(
    val plans: List<Plan> = emptyList(),
    val pay: PayInfo = PayInfo(),
    val order: Order? = null,
    val orders: List<Order> = emptyList(),
    val config: VpnConfig? = null,
    val account: Account? = null,
    val meta: Meta = Meta(),
    val flash: String? = null,
)

data class Plan(
    val id: String,
    val title: String,
    val tjs: Double,
    val cny: Double,
    val devices: Int,
    val expires: String = "",
)

data class PayInfo(
    val alif: String = "",
    val dc: String = "",
    val payee: String = "",
    val support: String = "",
    val wechat: Boolean = false,
    val alipay: Boolean = false,
)

data class Order(
    val id: String,
    val plan: String,
    val title: String = "",
    val amount: String = "",
    val status: String = "",
    val statusLabel: String = "",
    val name: String = "",
    val ready: Boolean = false,
)

data class Account(
    val code: String = "",
)

data class Meta(
    val title: String = "TEZVPN",
    val bot: String = "teztezvpn_bot",
    val support: String = "BarzuRizoev",
)

data class VpnConfig(
    val sid: String = "",
    val devices: List<VpnDevice> = emptyList(),
)

data class VpnDevice(
    val name: String,
    val conf: String,
    val vpnuri: String = "",
)

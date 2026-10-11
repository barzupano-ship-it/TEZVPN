import Foundation

struct ShopState {
    var plans: [Plan] = []
    var pay: PayInfo = PayInfo()
    var order: Order?
    var orders: [Order] = []
    var config: VpnConfig?
    var account: Account?
    var meta: Meta = Meta()
    var flash: String?
}

struct Plan: Identifiable {
    let id: String
    let title: String
    let tjs: Double
    let cny: Double
    let devices: Int
}

struct PayInfo {
    var alif = ""
    var dc = ""
    var payee = ""
    var support = ""
    var wechat = false
    var alipay = false
}

struct Order: Identifiable {
    let id: String
    var plan = ""
    var title = ""
    var amount = ""
    var status = ""
    var statusLabel = ""
    var name = ""
    var ready = false
}

struct Account {
    var code = ""
}

struct Meta {
    var title = "TEZVPN"
    var bot = "teztezvpn_bot"
    var support = "BarzuRizoev"
}

struct VpnConfig {
    var sid = ""
    var devices: [VpnDevice] = []
}

struct VpnDevice {
    var name: String
    var conf: String
    var vpnuri: String = ""
}

enum ShopConfig {
    static let shopURL = "https://188-116-24-47.sslip.io"
    static let support = "BarzuRizoev"
    static let appGroup = "group.ru.tezvpn.app"
    static let tunnelId = "ru.tezvpn.app.tunnel"
}

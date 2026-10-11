import Foundation
import SwiftUI

@MainActor
final class ShopStore: ObservableObject {
    @Published var shop = ShopState()
    @Published var loading = true
    @Published var busy = false
    @Published var connecting = false
    @Published var error: String?
    @Published var message: String?
    @Published var nameDraft = ""
    @Published var loginDraft = ""
    @Published var tab = "vpn"

    let api = ShopApi()
    let vpn = VpnManager()
    private var polling = false

    func refresh() async {
        loading = true
        error = nil
        do {
            shop = try await api.state()
            apply(shop)
            await maybeAutoConnect()
        } catch {
            self.error = error.localizedDescription
        }
        loading = false
    }

    func buy(_ planId: String) async {
        busy = true
        error = nil
        do {
            _ = try await api.startOrder(planId: planId)
            shop = try await api.state()
            apply(shop, tab: "order")
        } catch {
            self.error = error.localizedDescription
        }
        busy = false
    }

    func submitName() async {
        let name = nameDraft.trimmingCharacters(in: .whitespaces)
        guard name.count >= 2 else { error = "Введите имя"; return }
        busy = true
        do {
            _ = try await api.setName(name)
            shop = try await api.state()
            apply(shop, tab: "pay")
        } catch {
            self.error = error.localizedDescription
        }
        busy = false
    }

    func uploadReceipt(data: Data, filename: String) async {
        busy = true
        message = "Отправляем чек…"
        do {
            shop = try await api.uploadReceipt(data: data, filename: filename)
            apply(shop, tab: "order")
            message = "Чек отправлен. Ждём подтверждение — VPN включится сам."
            Task { await poll() }
        } catch {
            self.error = error.localizedDescription
            message = nil
        }
        busy = false
    }

    func login() async {
        busy = true
        do {
            shop = try await api.login(code: loginDraft.trimmingCharacters(in: .whitespaces))
            apply(shop, tab: "vpn")
            message = "Вход выполнен"
            await maybeAutoConnect()
        } catch {
            self.error = error.localizedDescription
        }
        busy = false
    }

    func toggleVpn() async {
        error = nil
        if vpn.isOn {
            await vpn.disconnect()
            message = "VPN выключен"
            return
        }
        guard let conf = shop.config?.devices.first?.conf, !conf.isEmpty else {
            error = "Сначала купите тариф"
            tab = "home"
            return
        }
        connecting = true
        do {
            try await vpn.connect(conf: conf)
            tab = "vpn"
            message = "VPN включён"
        } catch {
            self.error = error.localizedDescription
        }
        connecting = false
    }

    private func poll() async {
        if polling { return }
        polling = true
        for _ in 0..<80 {
            try? await Task.sleep(nanoseconds: 4_000_000_000)
            do {
                shop = try await api.state()
                apply(shop)
                if await maybeAutoConnect() { break }
                if ["rejected", "disabled", "expired", "failed"].contains(shop.order?.status ?? "") { break }
            } catch {}
        }
        polling = false
    }

    @discardableResult
    private func maybeAutoConnect() async -> Bool {
        let conf = shop.config?.devices.first?.conf
        let ready = shop.order?.ready == true && !(conf ?? "").isEmpty
        guard ready, !vpn.isOn, let conf else { return ready }
        connecting = true
        tab = "vpn"
        message = "Оплата принята. Подключаем VPN…"
        do {
            try await vpn.connect(conf: conf)
            message = "VPN включён"
            connecting = false
            return true
        } catch {
            self.error = error.localizedDescription
            connecting = false
            return false
        }
    }

    private func apply(_ shop: ShopState, tab: String? = nil) {
        self.shop = shop
        if nameDraft.isEmpty { nameDraft = shop.order?.name ?? "" }
        if let tab {
            self.tab = tab
            return
        }
        switch shop.order?.status {
        case "fulfilled": self.tab = "vpn"
        case "pending": self.tab = "pay"
        case "awaiting_name": self.tab = "order"
        case "waiting_review", "paid":
            self.tab = "order"
            if !polling { Task { await poll() } }
        default: break
        }
        if let flash = shop.flash { message = flash }
    }
}

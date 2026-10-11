import SwiftUI
import PhotosUI

struct ContentView: View {
    @EnvironmentObject var store: ShopStore

    var body: some View {
        TabView(selection: $store.tab) {
            VpnTab().tag("vpn").tabItem { Label("VPN", systemImage: "power") }
            PlansTab().tag("home").tabItem { Label("Тарифы", systemImage: "bag") }
            PayTab().tag("pay").tabItem { Label("Оплата", systemImage: "creditcard") }
            OrderTab().tag("order").tabItem { Label("Заказ", systemImage: "list.bullet") }
            AccountTab().tag("account").tabItem { Label("Кабинет", systemImage: "person") }
        }
        .tint(Color(red: 0.96, green: 0.77, blue: 0.09))
        .task { await store.refresh() }
    }
}

struct Header: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("TEZVPN").font(.largeTitle.weight(.heavy))
                .foregroundStyle(Color(red: 0.96, green: 0.77, blue: 0.09))
            Text("VPN включается в этом приложении сразу после оплаты")
                .foregroundStyle(Color(red: 0.62, green: 0.69, blue: 0.76))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, 8)
    }
}

struct VpnTab: View {
    @EnvironmentObject var store: ShopStore
    var ready: Bool { !(store.shop.config?.devices.first?.conf ?? "").isEmpty }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Header()
                alerts
                Button {
                    Task { await store.toggleVpn() }
                } label: {
                    VStack {
                        Image(systemName: "power").font(.system(size: 44, weight: .bold))
                        Text(store.vpn.isOn ? "ВКЛ" : (ready ? "ВКЛЮЧИТЬ" : "КУПИТЬ"))
                            .font(.headline.weight(.heavy))
                    }
                    .foregroundStyle(Color(red: 0.07, green: 0.07, blue: 0.07))
                    .frame(width: 160, height: 160)
                    .background(store.vpn.isOn ? Color(red: 0.12, green: 0.66, blue: 0.44) : Color(red: 0.96, green: 0.77, blue: 0.09), in: Circle())
                }
                Text(statusText).font(.headline).multilineTextAlignment(.center)
                if let o = store.shop.order, !ready { OrderCard(order: o) }
            }
            .padding()
        }
        .background(Color(red: 0.05, green: 0.14, blue: 0.22).ignoresSafeArea())
    }

    var statusText: String {
        if store.connecting { return "Подключаем…" }
        if store.vpn.isOn { return "Интернет идёт через TEZVPN" }
        if ready { return "Конфиг готов — нажмите, чтобы включить" }
        if store.shop.order?.status == "waiting_review" { return "Чек на проверке. VPN включится сам." }
        return "Купите тариф — VPN подключится сразу после оплаты"
    }

    @ViewBuilder var alerts: some View {
        if store.loading || store.busy { ProgressView().tint(.yellow) }
        if let e = store.error { Text(e).foregroundStyle(.red) }
        if let m = store.message { Text(m).foregroundStyle(Color(red: 0.96, green: 0.77, blue: 0.09)) }
    }
}

struct PlansTab: View {
    @EnvironmentObject var store: ShopStore
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Header()
                Text("Тарифы").font(.title2.bold())
                ForEach(store.shop.plans) { p in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(p.title).font(.headline)
                        Text("\(Int(p.tjs)) смн · ¥\(Int(p.cny)) · \(p.devices) устр.")
                            .foregroundStyle(Color(red: 0.96, green: 0.77, blue: 0.09))
                        Button("Купить") { Task { await store.buy(p.id) } }
                            .buttonStyle(.borderedProminent)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(red: 0.09, green: 0.20, blue: 0.31), in: RoundedRectangle(cornerRadius: 16))
                }
                if store.shop.plans.isEmpty {
                    Text("Не загрузились тарифы. Проверьте интернет.")
                    Button("Обновить") { Task { await store.refresh() } }
                }
            }
            .padding()
        }
        .background(Color(red: 0.05, green: 0.14, blue: 0.22).ignoresSafeArea())
    }
}

struct OrderTab: View {
    @EnvironmentObject var store: ShopStore
    @State private var pick: PhotosPickerItem?
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Header()
                Text("Заказ").font(.title2.bold())
                if let o = store.shop.order {
                    OrderCard(order: o)
                    switch o.status {
                    case "awaiting_name":
                        TextField("Ваше имя", text: $store.nameDraft)
                            .textFieldStyle(.roundedBorder)
                        Button("Продолжить") { Task { await store.submitName() } }
                            .buttonStyle(.borderedProminent)
                    case "pending":
                        Text("Переведите по реквизитам и загрузите фото чека.")
                        Button("Реквизиты") { store.tab = "pay" }
                        PhotosPicker("Загрузить чек", selection: $pick, matching: .images)
                    case "waiting_review", "paid":
                        Text("Ждём подтверждение администратора. VPN включится автоматически.")
                        Button("Обновить статус") { Task { await store.refresh() } }
                    case "fulfilled":
                        Text("Готово. Можно включать VPN.").foregroundStyle(Color(red: 0.96, green: 0.77, blue: 0.09))
                        Button("Открыть VPN") { store.tab = "vpn" }
                    case "rejected":
                        Text("Чек отклонён. Выберите тариф заново.").foregroundStyle(.red)
                    case "disabled":
                        Text("Доступ отключён администратором.").foregroundStyle(.red)
                    default:
                        EmptyView()
                    }
                } else {
                    Text("Заказа нет. Выберите тариф.")
                    Button("К тарифам") { store.tab = "home" }
                }
            }
            .padding()
        }
        .background(Color(red: 0.05, green: 0.14, blue: 0.22).ignoresSafeArea())
        .onChange(of: pick) { _, item in
            Task {
                guard let item, let data = try? await item.loadTransferable(type: Data.self) else { return }
                await store.uploadReceipt(data: data, filename: "receipt.jpg")
            }
        }
    }
}

struct PayTab: View {
    @EnvironmentObject var store: ShopStore
    @State private var pick: PhotosPickerItem?
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Header()
                Text("Оплата").font(.title2.bold())
                VStack(alignment: .leading, spacing: 8) {
                    if !store.shop.pay.payee.isEmpty { Text("Получатель: \(store.shop.pay.payee)") }
                    if !store.shop.pay.alif.isEmpty { Text("Alif: \(store.shop.pay.alif)") }
                    if !store.shop.pay.dc.isEmpty { Text("DC: \(store.shop.pay.dc)") }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(red: 0.09, green: 0.20, blue: 0.31), in: RoundedRectangle(cornerRadius: 16))
                PhotosPicker("Я оплатил — загрузить чек", selection: $pick, matching: .images)
                if let url = URL(string: "https://t.me/\(store.shop.meta.support)") {
                    Link("Поддержка @\(store.shop.meta.support)", destination: url)
                }
            }
            .padding()
        }
        .background(Color(red: 0.05, green: 0.14, blue: 0.22).ignoresSafeArea())
        .onChange(of: pick) { _, item in
            Task {
                guard let item, let data = try? await item.loadTransferable(type: Data.self) else { return }
                await store.uploadReceipt(data: data, filename: "receipt.jpg")
            }
        }
    }
}

struct AccountTab: View {
    @EnvironmentObject var store: ShopStore
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Header()
                Text("Кабинет").font(.title2.bold())
                Text("Код доступа: \(store.shop.account?.code ?? "—")")
                Text("Сохраните код, чтобы войти с другого телефона.")
                    .foregroundStyle(Color(red: 0.62, green: 0.69, blue: 0.76))
                TextField("Войти по коду", text: $store.loginDraft)
                    .textFieldStyle(.roundedBorder)
                Button("Войти") { Task { await store.login() } }
                    .buttonStyle(.borderedProminent)
                if let url = URL(string: "https://t.me/\(store.shop.meta.support)") {
                    Link("Поддержка @\(store.shop.meta.support)", destination: url)
                }
            }
            .padding()
        }
        .background(Color(red: 0.05, green: 0.14, blue: 0.22).ignoresSafeArea())
    }
}

struct OrderCard: View {
    let order: Order
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(order.title.isEmpty ? order.plan : order.title).bold()
            Text(order.statusLabel.isEmpty ? order.status : order.statusLabel)
                .foregroundStyle(Color(red: 0.96, green: 0.77, blue: 0.09))
            if !order.amount.isEmpty { Text("\(order.amount) смн").foregroundStyle(.secondary) }
            if !order.name.isEmpty { Text(order.name).foregroundStyle(.secondary) }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(red: 0.09, green: 0.20, blue: 0.31), in: RoundedRectangle(cornerRadius: 16))
    }
}

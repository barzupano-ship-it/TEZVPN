import Foundation

final class ShopApi {
    private let session: URLSession
    private let defaults = UserDefaults.standard

    var deviceFp: String {
        if let id = defaults.string(forKey: "fp"), !id.isEmpty { return id }
        let id = UUID().uuidString.replacingOccurrences(of: "-", with: "").lowercased()
        defaults.set(id, forKey: "fp")
        return id
    }

    init() {
        let cfg = URLSessionConfiguration.default
        cfg.httpCookieStorage = HTTPCookieStorage.shared
        cfg.httpCookieAcceptPolicy = .always
        cfg.timeoutIntervalForRequest = 40
        session = URLSession(configuration: cfg)
    }

    func state() async throws -> ShopState {
        try parseState(await request("/api/state"))
    }

    func startOrder(planId: String) async throws -> ShopState {
        try parseState(await request("/api/order", method: "POST", json: ["plan": planId]))
    }

    func setName(_ name: String) async throws -> ShopState {
        try parseState(await request("/api/name", method: "POST", json: ["name": name]))
    }

    func login(code: String) async throws -> ShopState {
        _ = try await request("/api/login", method: "POST", json: ["code": code])
        try await state()
    }

    func loadConfig(oid: String) async throws -> VpnConfig? {
        let obj = try await request("/api/config?oid=\(oid)")
        return parseConfig(obj["config"] as? [String: Any])
    }

    func uploadReceipt(data: Data, filename: String) async throws -> ShopState {
        let url = URL(string: ShopConfig.shopURL + "/api/receipt")!
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue(deviceFp, forHTTPHeaderField: "X-Tez-FP")
        let boundary = "tez\(UUID().uuidString)"
        req.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
        let mime = filename.lowercased().hasSuffix(".pdf") ? "application/pdf" : "image/jpeg"
        body.append("Content-Type: \(mime)\r\n\r\n".data(using: .utf8)!)
        body.append(data)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        req.httpBody = body
        let (bytes, resp) = try await session.data(for: req)
        try throwIfFailed(resp, bytes)
        return try await state()
    }

    private func request(_ path: String, method: String = "GET", json: [String: Any]? = nil) async throws -> [String: Any] {
        let url = URL(string: ShopConfig.shopURL + path)!
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        req.setValue(deviceFp, forHTTPHeaderField: "X-Tez-FP")
        if let json {
            req.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
            req.httpBody = try JSONSerialization.data(withJSONObject: json)
        }
        let (bytes, resp) = try await session.data(for: req)
        try throwIfFailed(resp, bytes)
        return (try JSONSerialization.jsonObject(with: bytes) as? [String: Any]) ?? [:]
    }

    private func throwIfFailed(_ resp: URLResponse, _ bytes: Data) throws {
        let code = (resp as? HTTPURLResponse)?.statusCode ?? 0
        let obj = (try? JSONSerialization.jsonObject(with: bytes) as? [String: Any]) ?? [:]
        if code >= 400 {
            throw NSError(domain: "TEZVPN", code: code, userInfo: [
                NSLocalizedDescriptionKey: (obj["error"] as? String).flatMap { $0.isEmpty ? nil : $0 } ?? "Ошибка \(code)"
            ])
        }
    }

    private func parseState(_ obj: [String: Any]) -> ShopState {
        let plans = (obj["plans"] as? [[String: Any]] ?? []).compactMap(plan)
        let orders = (obj["orders"] as? [[String: Any]] ?? []).compactMap(order)
        let one = order(obj["order"] as? [String: Any] ?? [:])
        let pay = obj["pay"] as? [String: Any] ?? [:]
        let meta = obj["meta"] as? [String: Any] ?? [:]
        let acc = obj["account"] as? [String: Any]
        return ShopState(
            plans: plans,
            pay: PayInfo(
                alif: pay["alif"] as? String ?? "",
                dc: pay["dc"] as? String ?? "",
                payee: pay["payee"] as? String ?? "",
                support: pay["support"] as? String ?? "",
                wechat: pay["wechat"] as? Bool ?? false,
                alipay: pay["alipay"] as? Bool ?? false
            ),
            order: one,
            orders: orders.isEmpty ? [one].compactMap { $0 } : orders,
            config: parseConfig(obj["config"] as? [String: Any]),
            account: acc.map { Account(code: $0["code"] as? String ?? "") },
            meta: Meta(
                title: (meta["title"] as? String).flatMap { $0.isEmpty ? nil : $0 } ?? "TEZVPN",
                bot: (meta["bot"] as? String).flatMap { $0.isEmpty ? nil : $0 } ?? "teztezvpn_bot",
                support: (meta["support"] as? String).flatMap { $0.isEmpty ? nil : $0 } ?? ShopConfig.support
            ),
            flash: (obj["flash"] as? String).flatMap { $0.isEmpty ? nil : $0 }
        )
    }

    private func plan(_ o: [String: Any]) -> Plan? {
        guard let id = o["id"] as? String else { return nil }
        return Plan(
            id: id,
            title: o["title"] as? String ?? id,
            tjs: (o["tjs"] as? NSNumber)?.doubleValue ?? 0,
            cny: (o["cny"] as? NSNumber)?.doubleValue ?? 0,
            devices: (o["devices"] as? NSNumber)?.intValue ?? 1
        )
    }

    private func order(_ o: [String: Any]) -> Order? {
        guard let id = o["id"] as? String, !id.isEmpty else { return nil }
        let st = o["status"] as? String ?? ""
        return Order(
            id: id,
            plan: o["plan"] as? String ?? "",
            title: o["title"] as? String ?? "",
            amount: "\(o["amount"] ?? "")".replacingOccurrences(of: ".0", with: ""),
            status: st,
            statusLabel: o["status_label"] as? String ?? st,
            name: o["name"] as? String ?? "",
            ready: (o["ready"] as? Bool ?? false) || st == "fulfilled"
        )
    }

    private func parseConfig(_ obj: [String: Any]?) -> VpnConfig? {
        guard let obj else { return nil }
        let devices = (obj["devices"] as? [[String: Any]] ?? []).compactMap { d -> VpnDevice? in
            let conf = d["conf"] as? String ?? ""
            guard !conf.isEmpty else { return nil }
            return VpnDevice(name: d["name"] as? String ?? "", conf: conf, vpnuri: d["vpnuri"] as? String ?? "")
        }
        guard !devices.isEmpty else { return nil }
        return VpnConfig(sid: obj["sid"] as? String ?? "", devices: devices)
    }
}

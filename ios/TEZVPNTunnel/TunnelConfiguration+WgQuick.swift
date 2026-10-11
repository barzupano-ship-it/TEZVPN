import Foundation
import WireGuardKit

extension String {
    func splitToArray(separator: Character = ",", trimmingCharacters: CharacterSet? = nil) -> [String] {
        split(separator: separator).map {
            if let charSet = trimmingCharacters {
                return $0.trimmingCharacters(in: charSet)
            }
            return String($0)
        }
    }
}

extension TunnelConfiguration {
    convenience init(fromWgQuickConfig wgQuickConfig: String, called name: String? = nil) throws {
        self.init(name: name, interface: try Self.parse(wgQuickConfig), peers: try Self.parsePeers(wgQuickConfig))
    }

    private static func parse(_ raw: String) throws -> InterfaceConfiguration {
        let iface = section(raw, name: "Interface")
        guard let pk = attr(iface, "PrivateKey").flatMap({ PrivateKey(base64Key: $0) }) else {
            throw NSError(domain: "TEZVPN", code: 2, userInfo: [NSLocalizedDescriptionKey: "Нет PrivateKey"])
        }
        var cfg = InterfaceConfiguration(privateKey: pk)
        if let a = attr(iface, "Address") {
            cfg.addresses = a.splitToArray(trimmingCharacters: .whitespaces).compactMap { IPAddressRange(from: $0) }
        }
        if let d = attr(iface, "DNS") {
            cfg.dns = d.splitToArray(trimmingCharacters: .whitespaces).compactMap { DNSServer(from: $0) }
        }
        if let m = attr(iface, "MTU"), let v = UInt16(m) { cfg.mtu = v }
        if let v = attr(iface, "Jc").flatMap(UInt16.init) { cfg.junkPacketCount = v }
        if let v = attr(iface, "Jmin").flatMap(UInt16.init) { cfg.junkPacketMinSize = v }
        if let v = attr(iface, "Jmax").flatMap(UInt16.init) { cfg.junkPacketMaxSize = v }
        if let v = attr(iface, "S1").flatMap(UInt16.init) { cfg.initPacketJunkSize = v }
        if let v = attr(iface, "S2").flatMap(UInt16.init) { cfg.responsePacketJunkSize = v }
        if let v = attr(iface, "S3").flatMap(UInt16.init) { cfg.cookieReplyPacketJunkSize = v }
        if let v = attr(iface, "S4").flatMap(UInt16.init) { cfg.transportPacketJunkSize = v }
        if let h = attr(iface, "H1") { cfg.initPacketMagicHeader = h }
        if let h = attr(iface, "H2") { cfg.responsePacketMagicHeader = h }
        if let h = attr(iface, "H3") { cfg.underloadPacketMagicHeader = h }
        if let h = attr(iface, "H4") { cfg.transportPacketMagicHeader = h }
        if let v = attr(iface, "I1") { cfg.specialJunk1 = v }
        if let v = attr(iface, "I2") { cfg.specialJunk2 = v }
        if let v = attr(iface, "I3") { cfg.specialJunk3 = v }
        if let v = attr(iface, "I4") { cfg.specialJunk4 = v }
        if let v = attr(iface, "I5") { cfg.specialJunk5 = v }
        return cfg
    }

    private static func parsePeers(_ raw: String) throws -> [PeerConfiguration] {
        raw.components(separatedBy: "[Peer]")
            .dropFirst()
            .compactMap { block -> PeerConfiguration? in
                guard let pub = attr(block, "PublicKey").flatMap({ PublicKey(base64Key: $0) }) else { return nil }
                var peer = PeerConfiguration(publicKey: pub)
                if let psk = attr(block, "PresharedKey") {
                    peer.preSharedKey = PreSharedKey(base64Key: psk)
                }
                if let a = attr(block, "AllowedIPs") {
                    peer.allowedIPs = a.splitToArray(trimmingCharacters: .whitespaces).compactMap { IPAddressRange(from: $0) }
                }
                if let e = attr(block, "Endpoint") {
                    peer.endpoint = Endpoint(from: e)
                }
                if let k = attr(block, "PersistentKeepalive"), let n = UInt16(k) {
                    peer.persistentKeepAlive = n
                }
                return peer
            }
    }

    private static func section(_ raw: String, name: String) -> String {
        let parts = raw.components(separatedBy: "[\(name)]")
        guard parts.count > 1 else { return "" }
        return parts[1].components(separatedBy: "[")[0]
    }

    private static func attr(_ block: String, _ key: String) -> String? {
        for line in block.split(whereSeparator: \.isNewline) {
            let t = line.trimmingCharacters(in: .whitespaces)
            let p = t.split(separator: "=", maxSplits: 1).map { $0.trimmingCharacters(in: .whitespaces) }
            if p.count == 2, p[0].lowercased() == key.lowercased() { return p[1] }
        }
        return nil
    }
}

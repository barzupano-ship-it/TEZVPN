import Foundation
import NetworkExtension

@MainActor
final class VpnBridge {
    static let tunnelId = "ru.tezvpn.app.tunnel"

    func connect(conf: String) async throws {
        let all = try await NETunnelProviderManager.loadAllFromPreferences()
        let mgr = all.first ?? NETunnelProviderManager()
        let proto = NETunnelProviderProtocol()
        proto.providerBundleIdentifier = Self.tunnelId
        proto.serverAddress = "TEZVPN"
        proto.providerConfiguration = ["wg-quick": conf]
        mgr.protocolConfiguration = proto
        mgr.localizedDescription = "TEZVPN"
        mgr.isEnabled = true
        mgr.isOnDemandEnabled = false
        try await mgr.saveToPreferences()
        try await mgr.loadFromPreferences()
        try mgr.connection.startVPNTunnel()
    }

    func disconnect() async {
        let all = (try? await NETunnelProviderManager.loadAllFromPreferences()) ?? []
        for mgr in all {
            mgr.connection.stopVPNTunnel()
        }
    }

    func isUp() async -> Bool {
        let all = (try? await NETunnelProviderManager.loadAllFromPreferences()) ?? []
        return all.contains { $0.connection.status == .connected || $0.connection.status == .connecting }
    }
}

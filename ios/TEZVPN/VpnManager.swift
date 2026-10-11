import Foundation
import NetworkExtension

@MainActor
final class VpnManager: ObservableObject {
    @Published var isOn = false
    @Published var lastConf = ""

    func connect(conf: String) async throws {
        lastConf = conf
        let all = try await NETunnelProviderManager.loadAllFromPreferences()
        let mgr = all.first ?? NETunnelProviderManager()
        let proto = NETunnelProviderProtocol()
        proto.providerBundleIdentifier = ShopConfig.tunnelId
        proto.serverAddress = "TEZVPN"
        proto.providerConfiguration = ["wg-quick": conf]
        mgr.protocolConfiguration = proto
        mgr.localizedDescription = "TEZVPN"
        mgr.isEnabled = true
        mgr.isOnDemandEnabled = false
        try await mgr.saveToPreferences()
        try await mgr.loadFromPreferences()
        try mgr.connection.startVPNTunnel()
        isOn = true
    }

    func disconnect() async {
        let all = (try? await NETunnelProviderManager.loadAllFromPreferences()) ?? []
        for mgr in all {
            mgr.connection.stopVPNTunnel()
        }
        isOn = false
    }

    func refreshStatus() async {
        let all = (try? await NETunnelProviderManager.loadAllFromPreferences()) ?? []
        isOn = all.contains { $0.connection.status == .connected || $0.connection.status == .connecting }
    }
}

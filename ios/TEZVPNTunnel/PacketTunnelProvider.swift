import NetworkExtension
import WireGuardKit

final class PacketTunnelProvider: NEPacketTunnelProvider {
    private lazy var adapter: WireGuardAdapter = {
        WireGuardAdapter(with: self) { _, message in
            NSLog("SULTAN VPN tunnel: %@", message)
        }
    }()

    override func startTunnel(options: [String: NSObject]?, completionHandler: @escaping (Error?) -> Void) {
        guard
            let proto = protocolConfiguration as? NETunnelProviderProtocol,
            let conf = proto.providerConfiguration?["wg-quick"] as? String
        else {
            completionHandler(NSError(domain: "SULTANVPN", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "Нет конфига VPN"
            ]))
            return
        }
        do {
            let tunnel = try TunnelConfiguration(fromWgQuickConfig: conf, called: "SULTAN VPN")
            adapter.start(tunnelConfiguration: tunnel) { error in
                completionHandler(error)
            }
        } catch {
            completionHandler(error)
        }
    }

    override func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
        adapter.stop { _ in
            completionHandler()
        }
    }

    override func handleAppMessage(_ messageData: Data, completionHandler: ((Data?) -> Void)?) {
        completionHandler?(messageData)
    }
}

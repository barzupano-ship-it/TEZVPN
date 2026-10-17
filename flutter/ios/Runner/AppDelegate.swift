import Darwin
import Flutter
import UIKit

private func sultanTunnelTraffic() -> [String: Int64] {
  var head: UnsafeMutablePointer<ifaddrs>?
  if getifaddrs(&head) != 0 || head == nil {
    return ["up": 0, "down": 0]
  }
  defer { freeifaddrs(head) }
  var upload: UInt64 = 0
  var download: UInt64 = 0
  var cursor = head
  while let current = cursor {
    let next = current.pointee.ifa_next
    if let addr = current.pointee.ifa_addr, addr.pointee.sa_family == UInt8(AF_LINK) {
      let name = String(cString: current.pointee.ifa_name)
      if name.hasPrefix("utun") || name.hasPrefix("ipsec"), let data = current.pointee.ifa_data {
        let stats = data.assumingMemoryBound(to: if_data.self).pointee
        download &+= UInt64(stats.ifi_ibytes)
        upload &+= UInt64(stats.ifi_obytes)
      }
    }
    cursor = next
  }
  return ["up": Int64(clamping: upload), "down": Int64(clamping: download)]
}

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private let vpn = VpnBridge()

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    let channel = FlutterMethodChannel(
      name: "ru.tezvpn.app/vpn",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self else { return }
      Task { @MainActor in
        do {
          switch call.method {
          case "prepare":
            result(true)
          case "connect":
            let conf = (call.arguments as? [String: Any])?["conf"] as? String ?? ""
            try await self.vpn.connect(conf: conf)
            result(true)
          case "disconnect":
            await self.vpn.disconnect()
            result(true)
          case "isUp":
            result(await self.vpn.isUp())
          case "traffic":
            result(sultanTunnelTraffic())
          default:
            result(FlutterMethodNotImplemented)
          }
        } catch {
          result(FlutterError(code: "vpn", message: error.localizedDescription, details: nil))
        }
      }
    }
  }
}

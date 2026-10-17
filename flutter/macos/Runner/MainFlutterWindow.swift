import Cocoa
import Darwin
import FlutterMacOS

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

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    self.contentViewController = flutterViewController
    self.title = "SULTAN VPN"
    self.backgroundColor = NSColor.white
    self.minSize = NSSize(width: 390, height: 700)
    self.setContentSize(NSSize(width: 430, height: 880))
    self.center()

    RegisterGeneratedPlugins(registry: flutterViewController)

    let channel = FlutterMethodChannel(
      name: "ru.tezvpn.app/vpn",
      binaryMessenger: flutterViewController.engine.binaryMessenger
    )
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "prepare":
        result(true)
      case "isUp":
        result(false)
      case "traffic":
        result(sultanTunnelTraffic())
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    super.awakeFromNib()
  }
}

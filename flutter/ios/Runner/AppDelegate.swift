import Flutter
import UIKit

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

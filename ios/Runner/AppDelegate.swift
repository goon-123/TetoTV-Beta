import Flutter
import UIKit
import AVFoundation

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Movie audio should work when the iPhone's silent switch is enabled.
    try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "TetoIosPlatformPlugin") {
      TetoIosPlatformPlugin.register(with: registrar)
    }
  }
}

final class TetoIosPlatformPlugin: NSObject, FlutterPlugin {
  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "dev.tetotv/ios", binaryMessenger: registrar.messenger())
    registrar.addMethodCallDelegate(TetoIosPlatformPlugin(), channel: channel)
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getAppVersion":
      result([
        "versionName": Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "unknown",
        "versionCode": Int(Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "0") ?? 0
      ])
    case "openExternalWebPage":
      // Match the Dart public-page boundary. No arbitrary scheme, credentials,
      // query tokens or media headers are handed to another app.
      guard let args = call.arguments as? [String: Any],
            let value = args["uri"] as? String,
            let components = URLComponents(string: value),
            components.scheme?.lowercased() == "https",
            let host = components.host, !host.isEmpty,
            components.user == nil, components.password == nil,
            components.query == nil,
            let url = components.url else {
        result(FlutterError(code: "INVALID_URL", message: "A public HTTPS page is required.", details: nil))
        return
      }
      UIApplication.shared.open(url, options: [:]) { opened in result(opened) }
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}

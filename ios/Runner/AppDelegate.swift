import Flutter
import UIKit
import shared_preferences_foundation

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    #if DEBUG
    GeneratedPluginRegistrant.register(with: self)
    #else
    if let registrar = self.registrar(forPlugin: "SharedPreferencesPlugin") {
      SharedPreferencesPlugin.register(with: registrar)
    }
    #endif
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}

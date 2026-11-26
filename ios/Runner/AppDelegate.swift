import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    BackupExclusion.apply()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "MediaEngine") {
      let engine = IosMediaEngine()
      MediaEngineHostApiSetup.setUp(binaryMessenger: registrar.messenger(), api: engine)
      EngineEventsStreamHandler.register(with: registrar.messenger(), streamHandler: engine)
      FileExportHostApiSetup.setUp(binaryMessenger: registrar.messenger(), api: FileExporter())
    }
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "SystemMonitor") {
      SystemMonitorHostApiSetup.setUp(binaryMessenger: registrar.messenger(), api: SystemMonitor())
    }
  }
}

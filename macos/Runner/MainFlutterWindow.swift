import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    // Keep the window wide enough for the narrowest supported desktop layout.
    minSize = NSSize(width: 600, height: 600)

    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)
    SystemMonitorHostApiSetup.setUp(binaryMessenger: flutterViewController.engine.binaryMessenger, api: SystemMonitor())

    super.awakeFromNib()
  }
}

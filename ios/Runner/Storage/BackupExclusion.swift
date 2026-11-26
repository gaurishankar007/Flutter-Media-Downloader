import Foundation

/// Keeps the app's own folders out of iCloud / device backups: downloads are
/// large, the engine and thumbnails can be fetched or rebuilt, and imported
/// cookies must never leave the device. Same folders as Dart's
/// `AppDirectories` (path_provider's Application Support). Runs at launch,
/// before Dart creates them; the flag on a folder covers everything inside.
enum BackupExclusion {
  private static let folders = ["downloads", "thumbnails", "cookies", "engine"]

  static func apply() {
    let fileManager = FileManager.default
    guard let base = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
      return
    }
    for folder in folders {
      var url = base.appendingPathComponent(folder, isDirectory: true)
      do {
        try fileManager.createDirectory(at: url, withIntermediateDirectories: true)
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        try url.setResourceValues(values)
      } catch {
        NSLog("BackupExclusion: could not mark %@", folder)
      }
    }
  }
}

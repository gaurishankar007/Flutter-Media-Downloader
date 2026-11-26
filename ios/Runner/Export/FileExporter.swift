import Flutter
import UIKit

/// Save to Files on iOS: `UIDocumentPickerViewController(forExporting:)`. The
/// file is offered under the suggested name through a hard link (or a copy on
/// another volume), so it's never loaded into memory.
final class FileExporter: NSObject, FileExportHostApi, UIDocumentPickerDelegate {
  private var pending: CheckedContinuation<Bool, Never>?

  func exportFile(path: String, suggestedName: String, mimeType: String) async throws -> Bool {
    let fileManager = FileManager.default
    guard fileManager.fileExists(atPath: path) else {
      throw FileExportPigeonError(code: "not_found", message: "File not found: \(path)", details: nil)
    }
    // The picker uses the file's own name, so stage it under the suggested one.
    let staging = fileManager.temporaryDirectory
      .appendingPathComponent("export-\(UUID().uuidString)", isDirectory: true)
    try fileManager.createDirectory(at: staging, withIntermediateDirectories: true)
    defer { try? fileManager.removeItem(at: staging) }
    let staged = staging.appendingPathComponent(Self.safeName(suggestedName, fallback: path))
    do {
      try fileManager.linkItem(atPath: path, toPath: staged.path)
    } catch {
      try fileManager.copyItem(atPath: path, toPath: staged.path)
    }
    return await present(staged)
  }

  @MainActor
  private func present(_ url: URL) async -> Bool {
    // A second request while the picker is open cancels the first.
    pending?.resume(returning: false)
    pending = nil
    guard let presenter = Self.topViewController() else {
      return false
    }
    return await withCheckedContinuation { continuation in
      pending = continuation
      let picker = UIDocumentPickerViewController(forExporting: [url], asCopy: true)
      picker.delegate = self
      presenter.present(picker, animated: true)
    }
  }

  func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
    finish(!urls.isEmpty)
  }

  func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
    finish(false)
  }

  private func finish(_ saved: Bool) {
    pending?.resume(returning: saved)
    pending = nil
  }

  private static func safeName(_ name: String, fallback path: String) -> String {
    let cleaned = name.replacingOccurrences(of: "/", with: "_").trimmingCharacters(in: .whitespacesAndNewlines)
    return cleaned.isEmpty ? (path as NSString).lastPathComponent : cleaned
  }

  @MainActor
  private static func topViewController() -> UIViewController? {
    let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
    let window = scenes.flatMap(\.windows).first(where: \.isKeyWindow) ?? scenes.first?.windows.first
    var top = window?.rootViewController
    while let presented = top?.presentedViewController {
      top = presented
    }
    return top
  }
}

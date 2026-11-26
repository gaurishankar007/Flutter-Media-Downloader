import Flutter
import UIKit

/// Runs yt-dlp (embedded CPython, `python/engine_shim.py`) and ffmpeg
/// (FFmpegKit) inside the app process. Arguments come from Dart
/// (YtDlpArgsBuilder / FfmpegCommandBuilder); this class only runs them and
/// forwards each stdout line. See docs/engine/ios_engine.md.
final class IosMediaEngine: EngineEventsStreamHandler, MediaEngineHostApi {
  private static let ytDlpReleaseUrl = URL(string: "https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp")!

  // Python needs far more stack than the 512 KB a secondary thread gets.
  private static let pythonStackSize = 16 << 20

  private let lock = NSLock()
  private let startLock = NSLock()
  private var sink: PigeonEventSink<EngineEventMsg>?
  private var encoders: [String]?
  private var downloads = Set<String>()
  private var backgroundTasks: [String: UIBackgroundTaskIdentifier] = [:]
  private var expiredJobs = Set<String>()
  // Cancelled while Python was still starting: never handed to yt-dlp.
  private var cancelledEarly = Set<String>()
  // Guarded by startLock.
  private var loadedVersion: String?

  private var bundle: URL { Bundle.main.bundleURL }

  /// Application Support/engine: the updated yt-dlp zipapp lives here.
  private var engineDir: URL {
    FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
      .appendingPathComponent("engine", isDirectory: true)
  }

  private var updatedZip: URL { engineDir.appendingPathComponent("yt-dlp.zip") }

  override func onListen(withArguments arguments: Any?, sink: PigeonEventSink<EngineEventMsg>) {
    self.sink = sink
  }

  override func onCancel(withArguments arguments: Any?) {
    sink = nil
  }

  // MARK: MediaEngineHostApi

  func initialize() async throws -> EngineInfoMsg {
    let version = try await onPythonThread { try self.startPython() }
    let found = await onPythonThread { self.readEncoders() }
    return EngineInfoMsg(ytDlpVersion: version, encoders: found)
  }

  func probe(args: [String]) async throws -> String {
    try await onPythonThread {
      _ = try self.startPython()
      return try self.callShim("probe", [try Self.json(args)])
    }
  }

  func startDownload(jobId: String, args: [String]) throws {
    let argv = try Self.json(args)
    locked { _ = downloads.insert(jobId) }
    beginBackgroundTime(jobId)
    Self.startPythonThread {
      let (kind, payload) = self.runDownload(jobId: jobId, argv: argv)
      self.locked { _ = self.downloads.remove(jobId) }
      self.finish(jobId, kind, payload)
    }
  }

  func startFfmpeg(jobId: String, args: [String]) throws {
    beginBackgroundTime(jobId)
    MDFFmpeg.startJob(
      jobId,
      arguments: args,
      onLine: { [weak self] line in self?.emit(jobId, .line, line) },
      completion: { [weak self] outcome, output in
        let kind: EngineEventKind = switch outcome {
        case .done: .done
        case .cancelled: .cancelled
        default: .error
        }
        self?.finish(jobId, kind, output)
      })
  }

  func cancel(jobId: String) throws -> Bool {
    let isDownload = locked { downloads.contains(jobId) }
    // For a download this stops a merge / audio extraction yt-dlp started.
    let stoppedFfmpeg = MDFFmpeg.cancelJob(jobId)
    guard isDownload else {
      return stoppedFfmpeg
    }
    if MDPythonRuntime.isStarted() {
      _ = try callShim("cancel", [jobId])
    } else {
      locked { _ = cancelledEarly.insert(jobId) }
    }
    return true
  }

  func updateYtDlp() async throws -> String {
    _ = try await onPythonThread { try self.startPython() }
    let (downloaded, response) = try await URLSession.shared.download(from: Self.ytDlpReleaseUrl)
    guard (response as? HTTPURLResponse)?.statusCode == 200 else {
      throw MediaEnginePigeonError(code: "update", message: "yt-dlp download failed", details: nil)
    }
    let fileManager = FileManager.default
    try fileManager.createDirectory(at: engineDir, withIntermediateDirectories: true)
    if fileManager.fileExists(atPath: updatedZip.path) {
      try fileManager.removeItem(at: updatedZip)
    }
    try fileManager.moveItem(at: downloaded, to: updatedZip)
    return try await onPythonThread {
      let version = try self.callShim("reload", [])
      if version.isEmpty {
        throw MediaEnginePigeonError(code: "update", message: "yt-dlp update did not load", details: nil)
      }
      self.startLock.lock()
      self.loadedVersion = version
      self.startLock.unlock()
      return version
    }
  }

  // MARK: Python

  /// Starts Python and loads yt-dlp once. Returns the yt-dlp version.
  private func startPython() throws -> String {
    startLock.lock()
    defer { startLock.unlock() }
    if MDPythonRuntime.isStarted(), let version = loadedVersion {
      return version
    }
    let engine = bundle.appendingPathComponent("engine", isDirectory: true)
    let sitePackages = engine.appendingPathComponent("site-packages", isDirectory: true)
    // Python on iOS has no CA bundle; certifi's is used for every TLS connection.
    setenv("SSL_CERT_FILE", sitePackages.appendingPathComponent("certifi/cacert.pem").path, 1)
    // yt-dlp's cache (e.g. YouTube player data) must go somewhere writable.
    let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
    setenv("XDG_CACHE_HOME", caches.path, 1)

    var error: NSString?
    let started = MDPythonRuntime.start(
      withHome: bundle.appendingPathComponent("python").path,
      paths: [engine.path, sitePackages.path],
      lineHandler: { [weak self] jobId, line in self?.emit(jobId, .line, line) },
      error: &error)
    guard started else {
      throw MediaEnginePigeonError(code: "python", message: error as String? ?? "Python failed to start", details: nil)
    }
    let version = try callShim(
      "init", [engine.appendingPathComponent("yt-dlp.zip").path, updatedZip.path])
    loadedVersion = version
    return version
  }

  private func callShim(_ function: String, _ arguments: [String]) throws -> String {
    var error: NSString?
    guard let result = MDPythonRuntime.call(function, arguments: arguments, error: &error) else {
      throw MediaEnginePigeonError(code: "engine", message: error as String? ?? "yt-dlp failed", details: nil)
    }
    return result
  }

  private func runDownload(jobId: String, argv: String) -> (EngineEventKind, String) {
    do {
      _ = try startPython()
      if locked({ cancelledEarly.remove(jobId) != nil }) {
        return (.cancelled, "")
      }
      let json = try callShim("download", [jobId, argv])
      let result = try JSONDecoder().decode(DownloadResult.self, from: Data(json.utf8))
      return switch result.result {
      case "done": (.done, "")
      case "cancelled": (.cancelled, "")
      default: (.error, result.message)
      }
    } catch {
      return (.error, Self.message(of: error))
    }
  }

  private func readEncoders() -> [String] {
    if let encoders = locked({ encoders }) {
      return encoders
    }
    let found = MDFFmpeg.videoEncoders()
    locked { encoders = found }
    return found
  }

  // MARK: Events

  private func emit(_ jobId: String, _ kind: EngineEventKind, _ payload: String) {
    let event = EngineEventMsg(jobId: jobId, kind: kind, payload: payload)
    DispatchQueue.main.async { [weak self] in self?.sink?.success(event) }
  }

  /// Sends the job's last event and gives its background time back.
  private func finish(_ jobId: String, _ kind: EngineEventKind, _ payload: String) {
    let expired = locked { expiredJobs.remove(jobId) != nil }
    if expired, kind == .cancelled {
      emit(jobId, .error, "iOS stopped the job in the background (background time ran out).")
    } else {
      emit(jobId, kind, payload)
    }
    endBackgroundTime(jobId)
  }

  // MARK: Background time

  /// iOS gives a backgrounded app about 30 s; each job asks for it, and is
  /// stopped (marked failed) when it runs out. See docs/engine/ios_engine.md#background.
  private func beginBackgroundTime(_ jobId: String) {
    DispatchQueue.main.async { [weak self] in
      guard let self else { return }
      let task = UIApplication.shared.beginBackgroundTask(withName: "job-\(jobId)") { [weak self] in
        guard let self else { return }
        self.locked { _ = self.expiredJobs.insert(jobId) }
        _ = try? cancel(jobId: jobId)
        endBackgroundTime(jobId)
      }
      self.locked { self.backgroundTasks[jobId] = task }
    }
  }

  private func endBackgroundTime(_ jobId: String) {
    DispatchQueue.main.async { [weak self] in
      guard let self, let task = self.locked({ self.backgroundTasks.removeValue(forKey: jobId) }) else { return }
      UIApplication.shared.endBackgroundTask(task)
    }
  }

  // MARK: Threads

  // Foundation's lock helper needs iOS 16; the app supports 15.
  private func locked<T>(_ body: () throws -> T) rethrows -> T {
    lock.lock()
    defer { lock.unlock() }
    return try body()
  }

  private static func startPythonThread(_ body: @escaping () -> Void) {
    let thread = Thread(block: body)
    thread.stackSize = pythonStackSize
    thread.qualityOfService = .userInitiated
    thread.start()
  }

  private func onPythonThread<T: Sendable>(_ body: @escaping () throws -> T) async throws -> T {
    try await withCheckedThrowingContinuation { continuation in
      Self.startPythonThread { continuation.resume(with: Result { try body() }) }
    }
  }

  private func onPythonThread<T: Sendable>(_ body: @escaping () -> T) async -> T {
    await withCheckedContinuation { continuation in
      Self.startPythonThread { continuation.resume(returning: body()) }
    }
  }

  private static func json(_ args: [String]) throws -> String {
    String(decoding: try JSONEncoder().encode(args), as: UTF8.self)
  }

  private static func message(of error: Error) -> String {
    if let error = error as? MediaEnginePigeonError {
      return error.message ?? error.code
    }
    return error.localizedDescription
  }
}

private struct DownloadResult: Decodable {
  let result: String
  let message: String
}

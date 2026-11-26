/// Save to Files: the system's "save as" UI plus a streamed copy. Methods
/// throw; repositories call them inside `ErrorHandler.execute`.
/// See docs/core/core_services.md#platform-services.
abstract interface class FileExportService {
  /// Asks where to save [path] as [name] and copies it there. Returns true
  /// when saved, false when the user cancelled.
  Future<bool> export(String path, {required String name, required String mimeType});
}

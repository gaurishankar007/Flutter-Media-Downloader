// Pigeon input: keeps classic field + constructor syntax (see CLAUDE.md).
// Regenerate: dart run pigeon --input lib/config/pigeon/file_export_api.dart
import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/core/clients/platform/file_export_api.g.dart',
    dartPackageName: 'media_downloader',
    kotlinOut: 'android/app/src/main/kotlin/com/gss/mediadownloader/export/FileExportApi.g.kt',
    kotlinOptions: KotlinOptions(package: 'com.gss.mediadownloader.export'),
    swiftOut: 'ios/Runner/Export/FileExportApi.g.swift',
    swiftOptions: SwiftOptions(errorClassName: 'FileExportPigeonError'),
  ),
)
/// Save to Files: the system's "save as" UI, then a streamed copy (the file
/// is never loaded into memory). See docs/core/core_services.md#platform-services.
@HostApi()
abstract class FileExportHostApi {
  /// Asks where to save [path] as [suggestedName] and copies it there.
  /// Returns true when saved, false when the user cancelled; throws on failure.
  @async
  bool exportFile(String path, String suggestedName, String mimeType);
}

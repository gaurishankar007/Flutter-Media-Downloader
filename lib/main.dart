import 'package:material_ui/material_ui.dart';
import 'package:media_downloader/ui/startup/run_media_downloader_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await runMediaDownloaderApp();
}

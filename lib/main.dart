import 'package:material_ui/material_ui.dart';
import 'package:media_tool/ui/startup/run_media_tool_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await runMediaToolApp();
}

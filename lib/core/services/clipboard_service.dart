import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';

abstract interface class ClipboardService {
  /// The clipboard's plain text, or `null` when it has none.
  Future<String?> readText();

  Future<void> writeText(String text);
}

@LazySingleton(as: ClipboardService)
final class ClipboardServiceImpl implements ClipboardService {
  @override
  Future<String?> readText() async => (await Clipboard.getData(Clipboard.kTextPlain))?.text;

  @override
  Future<void> writeText(String text) => Clipboard.setData(ClipboardData(text: text));
}

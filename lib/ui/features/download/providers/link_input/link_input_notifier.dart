import 'package:get_it/get_it.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:media_downloader/core/messages/app_messages.dart';
import 'package:media_downloader/core/services/clipboard_service.dart';
import 'package:media_downloader/core/utils/url_utils.dart';
import 'package:media_downloader/domain/models/site.dart';
import 'package:media_downloader/ui/core/providers/base/base_notifier.dart';

part 'link_input_state.dart';

/// The Download screen's link field: text, the cleaned-up URL and its site.
class LinkInputNotifier extends BaseNotifier<LinkInputState> {
  late final ClipboardService _clipboard;

  @override
  LinkInputState build() {
    _clipboard = GetIt.I<ClipboardService>();
    return const LinkInputState();
  }

  void onChanged(String text) => state = _parse(text);

  Future<void> pasteFromClipboard() => runFlow('download.paste', () async {
    final text = await _clipboard.readText();
    if (!ref.mounted) {
      return;
    }
    if (text == null || UrlUtils.extractUrl(text) == null) {
      state = state.copyWith(message: trackError(DownloadMessages.clipboardEmpty));
      return;
    }
    state = _parse(text);
  });

  void clear() => state = const LinkInputState();

  static LinkInputState _parse(String text) {
    if (text.trim().isEmpty) {
      return LinkInputState(text: text);
    }
    final url = UrlUtils.extractUrl(text);
    if (url == null) {
      return LinkInputState(text: text, linkStatus: .notALink);
    }
    final normalised = UrlUtils.normalise(url);
    final site = UrlUtils.detectSite(normalised);
    return LinkInputState(
      // Show the cleaned link when it came from surrounding text or had tracking params.
      text: normalised.toString(),
      url: normalised,
      site: site,
      linkStatus: site == null ? .unsupported : .recognised,
    );
  }
}

final linkInputProvider = NotifierProvider(LinkInputNotifier.new);

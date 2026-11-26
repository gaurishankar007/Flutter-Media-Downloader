import 'package:get_it/get_it.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:media_downloader/core/data/states/data_state.dart';
import 'package:media_downloader/core/messages/app_messages.dart';
import 'package:media_downloader/domain/models/cookie_browser.dart';
import 'package:media_downloader/domain/models/site.dart';
import 'package:media_downloader/domain/models/site_cookies.dart';
import 'package:media_downloader/domain/repositories/cookies_repository.dart';
import 'package:media_downloader/ui/core/providers/base/base_notifier.dart';
import 'package:media_downloader/ui/features/settings/providers/settings/settings_notifier.dart';

part 'cookies_state.dart';

/// Per-site cookie status: import, remove, and the macOS browser option.
/// The View confirms removes. See docs/features/settings.md#cookies.
class CookiesNotifier extends BaseNotifier<CookiesState> {
  late final CookiesRepository _repository;
  SettingsNotifier? _settings;

  @override
  CookiesState build() {
    _repository = GetIt.I<CookiesRepository>();
    _settings = ref.read(settingsProvider.notifier);
    Future.microtask(refresh);
    return CookiesState(status: .loading, supportsBrowserCookies: _repository.supportsBrowserCookies);
  }

  Future<void> refresh() => runFlow('cookies.list', () async {
    final result = await _repository.list();
    if (!ref.mounted) {
      return;
    }
    state = switch (result) {
      SuccessState(:final data) => state.copyWith(cookies: data ?? const [], status: .loaded),
      _ => state.copyWith(status: .error, message: trackFailure(result)),
    };
  });

  Future<void> import(Site site) => runFlow('cookies.import', () async {
    if (state.busySite != null) {
      return;
    }
    state = state.copyWith(busySite: site);
    final result = await _repository.import(site);
    if (!ref.mounted) {
      return;
    }
    switch (result) {
      case SuccessState(data: final imported?):
        state = state.copyWith(
          cookies: [...state.cookies.where((entry) => entry.site != site), imported],
          clearBusySite: true,
          message: SuccessMessage(CookiesMessages.importedToast(site.label)),
        );
      case SuccessState():
        // Picker cancelled.
        state = state.copyWith(clearBusySite: true);
      default:
        state = state.copyWith(clearBusySite: true, message: trackFailure(result));
    }
  });

  Future<void> remove(Site site) => runFlow('cookies.remove', () async {
    final result = await _repository.remove(site);
    if (!ref.mounted) {
      return;
    }
    state = switch (result) {
      FailureState() => state.copyWith(message: trackFailure(result)),
      _ => state.copyWith(
        cookies: state.cookies.where((entry) => entry.site != site).toList(),
        message: SuccessMessage(CookiesMessages.removedToast(site.label)),
      ),
    };
  });

  Future<void> setBrowser(CookieBrowser browser) async => await _settings?.setCookieBrowser(browser);
}

final cookiesProvider = NotifierProvider.autoDispose(CookiesNotifier.new);

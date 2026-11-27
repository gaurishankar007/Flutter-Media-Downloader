import 'dart:io';

import 'package:injectable/injectable.dart';
import 'package:media_tool/core/data/states/data_state.dart';
import 'package:media_tool/core/errors/error_handler.dart';
import 'package:media_tool/core/messages/app_messages.dart';
import 'package:media_tool/core/services/app_directories.dart';
import 'package:media_tool/core/types/types.dart';
import 'package:media_tool/domain/models/site.dart';
import 'package:media_tool/domain/models/site_cookies.dart';
import 'package:path/path.dart' as p;

/// Imported Netscape cookies.txt files, one per site, in `cookies/`. Their
/// contents are never logged: failures carry only a user message.
/// See docs/features/settings.md#cookies.
abstract interface class CookiesLocalService {
  /// The site's cookies file, or `null` when none was imported.
  String? pathFor(Site site);

  FutureList<SiteCookies> list();

  /// The `Cookie` header for a request to [url], built from [site]'s file.
  /// `null` when [url] isn't on [site]'s own domains or nothing matches, so
  /// cookies never go anywhere else.
  String? cookieHeader(Site site, Uri url);

  /// Validates [sourcePath], keeps only [site]'s cookies and stores them.
  FutureData<SiteCookies> save(Site site, String sourcePath);

  FutureVoid remove(Site site);
}

@LazySingleton(as: CookiesLocalService)
final class CookiesLocalServiceImpl({
  required final AppDirectories _directories,
  required final ErrorHandler _errorHandler,
}) implements CookiesLocalService {
  static const _header = '# Netscape HTTP Cookie File';
  static const _httpOnlyPrefix = '#HttpOnly_';

  @override
  String? pathFor(Site site) {
    final path = _fileFor(site);
    return File(path).existsSync() ? path : null;
  }

  @override
  String? cookieHeader(Site site, Uri url) {
    final host = url.host.toLowerCase();
    if (!_isOnSite(host, site)) {
      return null;
    }
    final file = File(_fileFor(site));
    if (!file.existsSync()) {
      return null;
    }
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final pairs = <String>[];
    for (final line in file.readAsLinesSync()) {
      if (!_isCookieLine(line)) {
        continue;
      }
      final fields = line.split('\t');
      var domain = fields[0].toLowerCase();
      if (domain.startsWith(_httpOnlyPrefix.toLowerCase())) {
        domain = domain.substring(_httpOnlyPrefix.length);
      }
      domain = domain.startsWith('.') ? domain.substring(1) : domain;
      final expiry = int.tryParse(fields[4]) ?? 0;
      final matches = host == domain || host.endsWith('.$domain');
      final secureOk = fields[3].toUpperCase() != 'TRUE' || url.scheme == 'https';
      if (matches && secureOk && (expiry == 0 || expiry > now)) {
        pairs.add('${fields[5]}=${fields[6]}');
      }
    }
    return pairs.isEmpty ? null : pairs.join('; ');
  }

  @override
  FutureList<SiteCookies> list() => _errorHandler.execute(action: 'cookies.list', () async {
    final result = <SiteCookies>[];
    for (final site in Site.values) {
      final file = File(_fileFor(site));
      if (!file.existsSync()) {
        continue;
      }
      final lines = await file.readAsLines();
      result.add(
        SiteCookies(site: site, count: lines.where(_isCookieLine).length, importedAt: file.lastModifiedSync()),
      );
    }
    return SuccessState(data: result);
  });

  @override
  FutureData<SiteCookies> save(Site site, String sourcePath) => _errorHandler.execute(action: 'cookies.save', () async {
    final source = File(sourcePath);
    // A cookies.txt is small; anything big isn't one.
    if (source.lengthSync() > 5 * 1024 * 1024) {
      return const FailureState(message: CookiesMessages.notCookiesFile);
    }
    final String text;
    try {
      text = await source.readAsString();
    } on FileSystemException {
      return const FailureState(message: CookiesMessages.notCookiesFile);
    } on FormatException {
      return const FailureState(message: CookiesMessages.notCookiesFile);
    }
    final lines = text.split(RegExp(r'\r?\n'));
    final hasHeader = lines.any((line) => line.contains('HTTP Cookie File'));
    if (!hasHeader) {
      return const FailureState(message: CookiesMessages.notCookiesFile);
    }
    final kept = [
      for (final line in lines)
        if (_isCookieLine(line) && _belongsTo(line, site)) line,
    ];
    if (kept.isEmpty) {
      return FailureState(message: CookiesMessages.noCookiesFor(site.label));
    }

    final target = File(_fileFor(site));
    await target.parent.create(recursive: true);
    await target.writeAsString('$_header\n\n${kept.join('\n')}\n', flush: true);
    if (Platform.isMacOS || Platform.isLinux) {
      // Readable by this user only.
      await Process.run('chmod', ['600', target.path]);
    }
    return SuccessState(
      data: SiteCookies(site: site, count: kept.length, importedAt: DateTime.now()),
    );
  });

  @override
  FutureVoid remove(Site site) => _errorHandler.execute(action: 'cookies.remove', () async {
    final file = File(_fileFor(site));
    if (file.existsSync()) {
      await file.delete();
    }
    return const SuccessState.nil();
  });

  String _fileFor(Site site) => p.join(_directories.cookies, '${site.name}.txt');

  /// `domain  includeSubdomains  path  secure  expiry  name  value`, tab-separated.
  static bool _isCookieLine(String line) {
    if (line.trim().isEmpty || (line.startsWith('#') && !line.startsWith(_httpOnlyPrefix))) {
      return false;
    }
    return line.split('\t').length >= 7;
  }

  static bool _isOnSite(String host, Site site) =>
      site.domains.any((domain) => host == domain || host.endsWith('.$domain'));

  static bool _belongsTo(String line, Site site) {
    var host = line.split('\t').first.toLowerCase();
    if (host.startsWith(_httpOnlyPrefix.toLowerCase())) {
      host = host.substring(_httpOnlyPrefix.length);
    }
    if (host.startsWith('.')) {
      host = host.substring(1);
    }
    return site.domains.any((domain) => host == domain || host.endsWith('.$domain'));
  }
}

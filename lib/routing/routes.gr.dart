// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes

import 'package:auto_route/auto_route.dart' as _i11;
import 'package:collection/collection.dart' as _i13;
import 'package:material_ui/material_ui.dart' as _i12;
import 'package:media_tool/ui/features/convert/views/convert/convert_screen.dart'
    as _i2;
import 'package:media_tool/ui/features/download/views/download/download_screen.dart'
    as _i5;
import 'package:media_tool/ui/features/home/views/home_shell/home_shell_screen.dart'
    as _i6;
import 'package:media_tool/ui/features/library/views/library/library_screen.dart'
    as _i7;
import 'package:media_tool/ui/features/library/views/media_viewer/media_viewer_screen.dart'
    as _i8;
import 'package:media_tool/ui/features/settings/views/about/about_screen.dart'
    as _i1;
import 'package:media_tool/ui/features/settings/views/cookies/cookies_screen.dart'
    as _i3;
import 'package:media_tool/ui/features/settings/views/design_gallery/design_gallery_screen.dart'
    as _i4;
import 'package:media_tool/ui/features/settings/views/settings/settings_screen.dart'
    as _i9;
import 'package:media_tool/ui/features/system/views/system/system_screen.dart'
    as _i10;

/// generated route for
/// [_i1.AboutScreen]
class AboutRoute extends _i11.PageRouteInfo<void> {
  const AboutRoute({List<_i11.PageRouteInfo>? children})
    : super(AboutRoute.name, initialChildren: children);

  static const String name = 'AboutRoute';

  static _i11.PageInfo page = _i11.PageInfo(
    name,
    builder: (data) {
      return const _i1.AboutScreen();
    },
  );
}

/// generated route for
/// [_i2.ConvertScreen]
class ConvertRoute extends _i11.PageRouteInfo<void> {
  const ConvertRoute({List<_i11.PageRouteInfo>? children})
    : super(ConvertRoute.name, initialChildren: children);

  static const String name = 'ConvertRoute';

  static _i11.PageInfo page = _i11.PageInfo(
    name,
    builder: (data) {
      return const _i2.ConvertScreen();
    },
  );
}

/// generated route for
/// [_i3.CookiesScreen]
class CookiesRoute extends _i11.PageRouteInfo<void> {
  const CookiesRoute({List<_i11.PageRouteInfo>? children})
    : super(CookiesRoute.name, initialChildren: children);

  static const String name = 'CookiesRoute';

  static _i11.PageInfo page = _i11.PageInfo(
    name,
    builder: (data) {
      return const _i3.CookiesScreen();
    },
  );
}

/// generated route for
/// [_i4.DesignGalleryScreen]
class DesignGalleryRoute extends _i11.PageRouteInfo<void> {
  const DesignGalleryRoute({List<_i11.PageRouteInfo>? children})
    : super(DesignGalleryRoute.name, initialChildren: children);

  static const String name = 'DesignGalleryRoute';

  static _i11.PageInfo page = _i11.PageInfo(
    name,
    builder: (data) {
      return const _i4.DesignGalleryScreen();
    },
  );
}

/// generated route for
/// [_i5.DownloadScreen]
class DownloadRoute extends _i11.PageRouteInfo<void> {
  const DownloadRoute({List<_i11.PageRouteInfo>? children})
    : super(DownloadRoute.name, initialChildren: children);

  static const String name = 'DownloadRoute';

  static _i11.PageInfo page = _i11.PageInfo(
    name,
    builder: (data) {
      return const _i5.DownloadScreen();
    },
  );
}

/// generated route for
/// [_i6.HomeShellScreen]
class HomeShellRoute extends _i11.PageRouteInfo<void> {
  const HomeShellRoute({List<_i11.PageRouteInfo>? children})
    : super(HomeShellRoute.name, initialChildren: children);

  static const String name = 'HomeShellRoute';

  static _i11.PageInfo page = _i11.PageInfo(
    name,
    builder: (data) {
      return const _i6.HomeShellScreen();
    },
  );
}

/// generated route for
/// [_i7.LibraryScreen]
class LibraryRoute extends _i11.PageRouteInfo<void> {
  const LibraryRoute({List<_i11.PageRouteInfo>? children})
    : super(LibraryRoute.name, initialChildren: children);

  static const String name = 'LibraryRoute';

  static _i11.PageInfo page = _i11.PageInfo(
    name,
    builder: (data) {
      return const _i7.LibraryScreen();
    },
  );
}

/// generated route for
/// [_i8.MediaViewerScreen]
class MediaViewerRoute extends _i11.PageRouteInfo<MediaViewerRouteArgs> {
  MediaViewerRoute({
    _i12.Key? key,
    required String initialId,
    required List<String> ids,
    List<_i11.PageRouteInfo>? children,
  }) : super(
         MediaViewerRoute.name,
         args: MediaViewerRouteArgs(key: key, initialId: initialId, ids: ids),
         initialChildren: children,
       );

  static const String name = 'MediaViewerRoute';

  static _i11.PageInfo page = _i11.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<MediaViewerRouteArgs>();
      return _i8.MediaViewerScreen(
        key: args.key,
        initialId: args.initialId,
        ids: args.ids,
      );
    },
  );
}

class MediaViewerRouteArgs {
  const MediaViewerRouteArgs({
    this.key,
    required this.initialId,
    required this.ids,
  });

  final _i12.Key? key;

  final String initialId;

  final List<String> ids;

  @override
  String toString() {
    return 'MediaViewerRouteArgs{key: $key, initialId: $initialId, ids: $ids}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! MediaViewerRouteArgs) return false;
    return key == other.key &&
        initialId == other.initialId &&
        const _i13.ListEquality<String>().equals(ids, other.ids);
  }

  @override
  int get hashCode =>
      key.hashCode ^
      initialId.hashCode ^
      const _i13.ListEquality<String>().hash(ids);
}

/// generated route for
/// [_i9.SettingsScreen]
class SettingsRoute extends _i11.PageRouteInfo<void> {
  const SettingsRoute({List<_i11.PageRouteInfo>? children})
    : super(SettingsRoute.name, initialChildren: children);

  static const String name = 'SettingsRoute';

  static _i11.PageInfo page = _i11.PageInfo(
    name,
    builder: (data) {
      return const _i9.SettingsScreen();
    },
  );
}

/// generated route for
/// [_i10.SystemScreen]
class SystemRoute extends _i11.PageRouteInfo<void> {
  const SystemRoute({List<_i11.PageRouteInfo>? children})
    : super(SystemRoute.name, initialChildren: children);

  static const String name = 'SystemRoute';

  static _i11.PageInfo page = _i11.PageInfo(
    name,
    builder: (data) {
      return const _i10.SystemScreen();
    },
  );
}

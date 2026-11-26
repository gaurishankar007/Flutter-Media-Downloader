// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes

import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;
import 'package:media_tool/core/clients/database/app_database.dart' as _i840;
import 'package:media_tool/core/errors/error_handler.dart' as _i166;
import 'package:media_tool/core/services/app_directories.dart' as _i1027;
import 'package:media_tool/core/services/clipboard_service.dart' as _i10;
import 'package:media_tool/core/services/file_service.dart' as _i600;
import 'package:media_tool/data/repositories/app_info_repository_impl.dart'
    as _i449;
import 'package:media_tool/data/repositories/background_work_repository_impl.dart'
    as _i384;
import 'package:media_tool/data/repositories/convert_repository_impl.dart'
    as _i789;
import 'package:media_tool/data/repositories/cookies_repository_impl.dart'
    as _i814;
import 'package:media_tool/data/repositories/job_repository_impl.dart' as _i727;
import 'package:media_tool/data/repositories/library_repository_impl.dart'
    as _i728;
import 'package:media_tool/data/repositories/media_repository_impl.dart'
    as _i156;
import 'package:media_tool/data/repositories/post_repository_impl.dart'
    as _i1059;
import 'package:media_tool/data/repositories/settings_repository_impl.dart'
    as _i236;
import 'package:media_tool/data/repositories/system_monitor_repository_impl.dart'
    as _i815;
import 'package:media_tool/data/services/local/app_files_local_service.dart'
    as _i662;
import 'package:media_tool/data/services/local/cookies_local_service.dart'
    as _i149;
import 'package:media_tool/data/services/local/error_log_local_service.dart'
    as _i298;
import 'package:media_tool/data/services/local/job_local_service.dart' as _i193;
import 'package:media_tool/data/services/local/library_local_service.dart'
    as _i202;
import 'package:media_tool/data/services/local/settings_local_service.dart'
    as _i221;
import 'package:media_tool/data/services/platform/app_info_service.dart'
    as _i247;
import 'package:media_tool/data/services/platform/background_work/android_background_work_service.dart'
    as _i376;
import 'package:media_tool/data/services/platform/background_work/background_work_service.dart'
    as _i495;
import 'package:media_tool/data/services/platform/background_work/noop_background_work_service.dart'
    as _i880;
import 'package:media_tool/data/services/platform/file_export/android_file_export_service.dart'
    as _i1055;
import 'package:media_tool/data/services/platform/file_export/file_export_service.dart'
    as _i18;
import 'package:media_tool/data/services/platform/file_export/ios_file_export_service.dart'
    as _i765;
import 'package:media_tool/data/services/platform/file_export/macos_file_export_service.dart'
    as _i955;
import 'package:media_tool/data/services/platform/file_picker_service.dart'
    as _i537;
import 'package:media_tool/data/services/platform/gallery_service.dart'
    as _i919;
import 'package:media_tool/data/services/platform/image_convert_service.dart'
    as _i990;
import 'package:media_tool/data/services/platform/image_service.dart' as _i879;
import 'package:media_tool/data/services/platform/media_engine/android_media_engine.dart'
    as _i173;
import 'package:media_tool/data/services/platform/media_engine/ffmpeg_slot.dart'
    as _i847;
import 'package:media_tool/data/services/platform/media_engine/macos_media_engine.dart'
    as _i946;
import 'package:media_tool/data/services/platform/media_engine/media_engine.dart'
    as _i11;
import 'package:media_tool/data/services/platform/media_picker_service.dart'
    as _i1017;
import 'package:media_tool/data/services/platform/share_service.dart' as _i316;
import 'package:media_tool/data/services/platform/system_monitor/system_monitor_service.dart'
    as _i338;
import 'package:media_tool/data/services/remote/engine_release_service.dart'
    as _i759;
import 'package:media_tool/data/services/remote/extractors/facebook_photo_extractor.dart'
    as _i984;
import 'package:media_tool/data/services/remote/extractors/instagram_photo_extractor.dart'
    as _i556;
import 'package:media_tool/data/services/remote/extractors/photo_extractors.dart'
    as _i501;
import 'package:media_tool/data/services/remote/extractors/threads_extractor.dart'
    as _i895;
import 'package:media_tool/data/services/remote/extractors/tiktok_photo_extractor.dart'
    as _i121;
import 'package:media_tool/data/services/remote/extractors/x_image_extractor.dart'
    as _i97;
import 'package:media_tool/data/services/remote/media_file_downloader.dart'
    as _i883;
import 'package:media_tool/data/services/remote/site_http_client.dart' as _i191;
import 'package:media_tool/domain/repositories/app_info_repository.dart'
    as _i928;
import 'package:media_tool/domain/repositories/background_work_repository.dart'
    as _i305;
import 'package:media_tool/domain/repositories/convert_repository.dart'
    as _i377;
import 'package:media_tool/domain/repositories/cookies_repository.dart'
    as _i609;
import 'package:media_tool/domain/repositories/job_repository.dart' as _i1062;
import 'package:media_tool/domain/repositories/library_repository.dart'
    as _i601;
import 'package:media_tool/domain/repositories/media_repository.dart' as _i413;
import 'package:media_tool/domain/repositories/post_repository.dart' as _i665;
import 'package:media_tool/domain/repositories/settings_repository.dart'
    as _i684;
import 'package:media_tool/domain/repositories/system_monitor_repository.dart'
    as _i521;
import 'package:media_tool/domain/use_cases/convert_media_use_case.dart'
    as _i966;
import 'package:media_tool/domain/use_cases/download_media_use_case.dart'
    as _i1046;
import 'package:media_tool/domain/use_cases/resolve_link_use_case.dart'
    as _i143;

const String _ios = 'ios';
const String _macos = 'macos';
const String _android = 'android';

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt initialize({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    gh.singleton<_i1027.AppDirectories>(() => _i1027.AppDirectories());
    gh.lazySingleton<_i847.FfmpegSlot>(() => _i847.FfmpegSlot());
    gh.lazySingleton<_i298.ErrorLogLocalService>(
      () => _i298.ErrorLogLocalServiceImpl(
        database: gh<_i840.AppDatabase>(),
        errorHandler: gh<_i166.ErrorHandler>(),
      ),
    );
    gh.lazySingleton<_i495.BackgroundWorkService>(
      () => _i880.NoopBackgroundWorkService(),
      registerFor: {_ios, _macos},
    );
    gh.lazySingleton<_i221.SettingsLocalService>(
      () => _i221.SettingsLocalServiceImpl(
        database: gh<_i840.AppDatabase>(),
        errorHandler: gh<_i166.ErrorHandler>(),
      ),
    );
    gh.lazySingleton<_i537.FilePickerService>(
      () => _i537.FilePickerServiceImpl(),
    );
    gh.lazySingleton<_i202.LibraryLocalService>(
      () => _i202.LibraryLocalServiceImpl(
        database: gh<_i840.AppDatabase>(),
        errorHandler: gh<_i166.ErrorHandler>(),
      ),
    );
    gh.lazySingleton<_i662.AppFilesLocalService>(
      () => _i662.AppFilesLocalServiceImpl(
        directories: gh<_i1027.AppDirectories>(),
      ),
    );
    gh.lazySingleton<_i10.ClipboardService>(() => _i10.ClipboardServiceImpl());
    gh.lazySingleton<_i919.GalleryService>(() => _i919.GalleryServiceImpl());
    gh.lazySingleton<_i11.MediaEngine>(
      () => _i173.AndroidMediaEngine(errorHandler: gh<_i166.ErrorHandler>()),
      registerFor: {_android, _ios},
    );
    gh.lazySingleton<_i338.SystemMonitorService>(
      () => _i338.SystemMonitorServiceImpl(),
    );
    gh.lazySingleton<_i1017.MediaPickerService>(
      () => _i1017.MediaPickerServiceImpl(),
    );
    gh.lazySingleton<_i684.SettingsRepository>(
      () => _i236.SettingsRepositoryImpl(
        localService: gh<_i221.SettingsLocalService>(),
      ),
    );
    gh.lazySingleton<_i879.ImageService>(() => _i879.ImageServiceImpl());
    gh.lazySingleton<_i990.ImageConvertService>(
      () => _i990.ImageConvertServiceImpl(),
    );
    gh.lazySingleton<_i247.AppInfoService>(() => _i247.AppInfoServiceImpl());
    gh.lazySingleton<_i600.FileService>(() => _i600.FileServiceImpl());
    gh.lazySingleton<_i11.MediaEngine>(
      () => _i946.MacosMediaEngine(
        errorHandler: gh<_i166.ErrorHandler>(),
        directories: gh<_i1027.AppDirectories>(),
      ),
      registerFor: {_macos},
    );
    gh.lazySingleton<_i193.JobLocalService>(
      () => _i193.JobLocalServiceImpl(
        database: gh<_i840.AppDatabase>(),
        errorHandler: gh<_i166.ErrorHandler>(),
      ),
    );
    gh.lazySingleton<_i316.ShareService>(() => _i316.ShareServiceImpl());
    gh.lazySingleton<_i149.CookiesLocalService>(
      () => _i149.CookiesLocalServiceImpl(
        directories: gh<_i1027.AppDirectories>(),
        errorHandler: gh<_i166.ErrorHandler>(),
      ),
    );
    gh.lazySingleton<_i18.FileExportService>(
      () => _i955.MacosFileExportService(),
      registerFor: {_macos},
    );
    gh.lazySingleton<_i18.FileExportService>(
      () => _i1055.AndroidFileExportService(),
      registerFor: {_android},
    );
    gh.lazySingleton<_i18.FileExportService>(
      () => _i765.IosFileExportService(),
      registerFor: {_ios},
    );
    gh.lazySingleton<_i928.AppInfoRepository>(
      () => _i449.AppInfoRepositoryImpl(
        appInfo: gh<_i247.AppInfoService>(),
        errorLog: gh<_i298.ErrorLogLocalService>(),
        clipboard: gh<_i10.ClipboardService>(),
        errorHandler: gh<_i166.ErrorHandler>(),
      ),
    );
    gh.lazySingleton<_i759.EngineReleaseService>(
      () => _i759.EngineReleaseServiceImpl(
        errorHandler: gh<_i166.ErrorHandler>(),
      ),
    );
    gh.lazySingleton<_i601.LibraryRepository>(
      () => _i728.LibraryRepositoryImpl(
        localService: gh<_i202.LibraryLocalService>(),
        directories: gh<_i1027.AppDirectories>(),
        files: gh<_i600.FileService>(),
        share: gh<_i316.ShareService>(),
        gallery: gh<_i919.GalleryService>(),
        fileExport: gh<_i18.FileExportService>(),
        images: gh<_i879.ImageService>(),
        errorHandler: gh<_i166.ErrorHandler>(),
      ),
    );
    gh.lazySingleton<_i495.BackgroundWorkService>(
      () => _i376.AndroidBackgroundWorkService(),
      registerFor: {_android},
    );
    gh.lazySingleton<_i521.SystemMonitorRepository>(
      () => _i815.SystemMonitorRepositoryImpl(
        service: gh<_i338.SystemMonitorService>(),
        appFiles: gh<_i662.AppFilesLocalService>(),
        errorHandler: gh<_i166.ErrorHandler>(),
      ),
    );
    gh.lazySingleton<_i191.SiteHttpClient>(
      () => _i191.SiteHttpClient(cookies: gh<_i149.CookiesLocalService>()),
    );
    gh.lazySingleton<_i377.ConvertRepository>(
      () => _i789.ConvertRepositoryImpl(
        engine: gh<_i11.MediaEngine>(),
        slot: gh<_i847.FfmpegSlot>(),
        images: gh<_i990.ImageConvertService>(),
        thumbnails: gh<_i879.ImageService>(),
        picker: gh<_i1017.MediaPickerService>(),
        library: gh<_i202.LibraryLocalService>(),
        directories: gh<_i1027.AppDirectories>(),
        files: gh<_i600.FileService>(),
        errorHandler: gh<_i166.ErrorHandler>(),
      ),
    );
    gh.lazySingleton<_i609.CookiesRepository>(
      () => _i814.CookiesRepositoryImpl(
        localService: gh<_i149.CookiesLocalService>(),
        picker: gh<_i537.FilePickerService>(),
        errorHandler: gh<_i166.ErrorHandler>(),
      ),
    );
    gh.lazySingleton<_i1062.JobRepository>(
      () => _i727.JobRepositoryImpl(localService: gh<_i193.JobLocalService>()),
    );
    gh.factory<_i966.ConvertMediaUseCase>(
      () => _i966.ConvertMediaUseCase(convert: gh<_i377.ConvertRepository>()),
    );
    gh.lazySingleton<_i305.BackgroundWorkRepository>(
      () => _i384.BackgroundWorkRepositoryImpl(
        service: gh<_i495.BackgroundWorkService>(),
        errorHandler: gh<_i166.ErrorHandler>(),
      ),
    );
    gh.lazySingleton<_i984.FacebookPhotoExtractor>(
      () => _i984.FacebookPhotoExtractor(http: gh<_i191.SiteHttpClient>()),
    );
    gh.lazySingleton<_i556.InstagramPhotoExtractor>(
      () => _i556.InstagramPhotoExtractor(http: gh<_i191.SiteHttpClient>()),
    );
    gh.lazySingleton<_i895.ThreadsExtractor>(
      () => _i895.ThreadsExtractor(http: gh<_i191.SiteHttpClient>()),
    );
    gh.lazySingleton<_i121.TikTokPhotoExtractor>(
      () => _i121.TikTokPhotoExtractor(http: gh<_i191.SiteHttpClient>()),
    );
    gh.lazySingleton<_i97.XImageExtractor>(
      () => _i97.XImageExtractor(http: gh<_i191.SiteHttpClient>()),
    );
    gh.lazySingleton<_i883.MediaFileDownloader>(
      () => _i883.MediaFileDownloader(http: gh<_i191.SiteHttpClient>()),
    );
    gh.lazySingleton<_i413.MediaRepository>(
      () => _i156.MediaRepositoryImpl(
        engine: gh<_i11.MediaEngine>(),
        directories: gh<_i1027.AppDirectories>(),
        files: gh<_i600.FileService>(),
        cookies: gh<_i149.CookiesLocalService>(),
        settings: gh<_i684.SettingsRepository>(),
        releases: gh<_i759.EngineReleaseService>(),
        slot: gh<_i847.FfmpegSlot>(),
      ),
    );
    gh.lazySingleton<_i501.PhotoExtractors>(
      () => _i501.PhotoExtractors(
        instagram: gh<_i556.InstagramPhotoExtractor>(),
        tiktok: gh<_i121.TikTokPhotoExtractor>(),
        facebook: gh<_i984.FacebookPhotoExtractor>(),
        threads: gh<_i895.ThreadsExtractor>(),
        x: gh<_i97.XImageExtractor>(),
      ),
    );
    gh.lazySingleton<_i665.PostRepository>(
      () => _i1059.PostRepositoryImpl(
        extractors: gh<_i501.PhotoExtractors>(),
        http: gh<_i191.SiteHttpClient>(),
        downloader: gh<_i883.MediaFileDownloader>(),
        images: gh<_i879.ImageService>(),
        cookies: gh<_i149.CookiesLocalService>(),
        directories: gh<_i1027.AppDirectories>(),
        errorHandler: gh<_i166.ErrorHandler>(),
      ),
    );
    gh.factory<_i143.ResolveLinkUseCase>(
      () => _i143.ResolveLinkUseCase(
        media: gh<_i413.MediaRepository>(),
        posts: gh<_i665.PostRepository>(),
      ),
    );
    gh.factory<_i1046.DownloadMediaUseCase>(
      () => _i1046.DownloadMediaUseCase(
        media: gh<_i413.MediaRepository>(),
        library: gh<_i601.LibraryRepository>(),
        posts: gh<_i665.PostRepository>(),
      ),
    );
    return this;
  }
}

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
import 'package:media_downloader/core/clients/database/app_database.dart'
    as _i407;
import 'package:media_downloader/core/errors/error_handler.dart' as _i313;
import 'package:media_downloader/core/services/app_directories.dart' as _i198;
import 'package:media_downloader/core/services/clipboard_service.dart' as _i875;
import 'package:media_downloader/core/services/file_service.dart' as _i624;
import 'package:media_downloader/data/repositories/app_info_repository_impl.dart'
    as _i219;
import 'package:media_downloader/data/repositories/background_work_repository_impl.dart'
    as _i834;
import 'package:media_downloader/data/repositories/convert_repository_impl.dart'
    as _i399;
import 'package:media_downloader/data/repositories/cookies_repository_impl.dart'
    as _i727;
import 'package:media_downloader/data/repositories/job_repository_impl.dart'
    as _i417;
import 'package:media_downloader/data/repositories/library_repository_impl.dart'
    as _i1057;
import 'package:media_downloader/data/repositories/media_repository_impl.dart'
    as _i398;
import 'package:media_downloader/data/repositories/post_repository_impl.dart'
    as _i591;
import 'package:media_downloader/data/repositories/settings_repository_impl.dart'
    as _i645;
import 'package:media_downloader/data/repositories/system_monitor_repository_impl.dart'
    as _i509;
import 'package:media_downloader/data/services/local/cookies_local_service.dart'
    as _i340;
import 'package:media_downloader/data/services/local/error_log_local_service.dart'
    as _i433;
import 'package:media_downloader/data/services/local/job_local_service.dart'
    as _i332;
import 'package:media_downloader/data/services/local/library_local_service.dart'
    as _i567;
import 'package:media_downloader/data/services/local/settings_local_service.dart'
    as _i960;
import 'package:media_downloader/data/services/platform/app_info_service.dart'
    as _i1059;
import 'package:media_downloader/data/services/platform/background_work/android_background_work_service.dart'
    as _i731;
import 'package:media_downloader/data/services/platform/background_work/background_work_service.dart'
    as _i429;
import 'package:media_downloader/data/services/platform/background_work/noop_background_work_service.dart'
    as _i546;
import 'package:media_downloader/data/services/platform/file_export/android_file_export_service.dart'
    as _i207;
import 'package:media_downloader/data/services/platform/file_export/file_export_service.dart'
    as _i122;
import 'package:media_downloader/data/services/platform/file_export/ios_file_export_service.dart'
    as _i527;
import 'package:media_downloader/data/services/platform/file_export/macos_file_export_service.dart'
    as _i945;
import 'package:media_downloader/data/services/platform/file_picker_service.dart'
    as _i132;
import 'package:media_downloader/data/services/platform/gallery_service.dart'
    as _i860;
import 'package:media_downloader/data/services/platform/image_convert_service.dart'
    as _i699;
import 'package:media_downloader/data/services/platform/image_service.dart'
    as _i454;
import 'package:media_downloader/data/services/platform/media_engine/android_media_engine.dart'
    as _i535;
import 'package:media_downloader/data/services/platform/media_engine/ffmpeg_slot.dart'
    as _i866;
import 'package:media_downloader/data/services/platform/media_engine/macos_media_engine.dart'
    as _i581;
import 'package:media_downloader/data/services/platform/media_engine/media_engine.dart'
    as _i328;
import 'package:media_downloader/data/services/platform/media_picker_service.dart'
    as _i495;
import 'package:media_downloader/data/services/platform/share_service.dart'
    as _i569;
import 'package:media_downloader/data/services/platform/system_monitor/system_monitor_service.dart'
    as _i204;
import 'package:media_downloader/data/services/remote/engine_release_service.dart'
    as _i879;
import 'package:media_downloader/data/services/remote/extractors/facebook_photo_extractor.dart'
    as _i372;
import 'package:media_downloader/data/services/remote/extractors/instagram_photo_extractor.dart'
    as _i780;
import 'package:media_downloader/data/services/remote/extractors/photo_extractors.dart'
    as _i239;
import 'package:media_downloader/data/services/remote/extractors/threads_extractor.dart'
    as _i400;
import 'package:media_downloader/data/services/remote/extractors/tiktok_photo_extractor.dart'
    as _i626;
import 'package:media_downloader/data/services/remote/extractors/x_image_extractor.dart'
    as _i784;
import 'package:media_downloader/data/services/remote/media_file_downloader.dart'
    as _i245;
import 'package:media_downloader/data/services/remote/site_http_client.dart'
    as _i901;
import 'package:media_downloader/domain/repositories/app_info_repository.dart'
    as _i455;
import 'package:media_downloader/domain/repositories/background_work_repository.dart'
    as _i366;
import 'package:media_downloader/domain/repositories/convert_repository.dart'
    as _i792;
import 'package:media_downloader/domain/repositories/cookies_repository.dart'
    as _i58;
import 'package:media_downloader/domain/repositories/job_repository.dart'
    as _i653;
import 'package:media_downloader/domain/repositories/library_repository.dart'
    as _i715;
import 'package:media_downloader/domain/repositories/media_repository.dart'
    as _i434;
import 'package:media_downloader/domain/repositories/post_repository.dart'
    as _i568;
import 'package:media_downloader/domain/repositories/settings_repository.dart'
    as _i991;
import 'package:media_downloader/domain/repositories/system_monitor_repository.dart'
    as _i1060;
import 'package:media_downloader/domain/use_cases/convert_media_use_case.dart'
    as _i192;
import 'package:media_downloader/domain/use_cases/download_media_use_case.dart'
    as _i948;
import 'package:media_downloader/domain/use_cases/resolve_link_use_case.dart'
    as _i898;

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
    gh.singleton<_i198.AppDirectories>(() => _i198.AppDirectories());
    gh.lazySingleton<_i866.FfmpegSlot>(() => _i866.FfmpegSlot());
    gh.lazySingleton<_i495.MediaPickerService>(
      () => _i495.MediaPickerServiceImpl(),
    );
    gh.lazySingleton<_i879.EngineReleaseService>(
      () => _i879.EngineReleaseServiceImpl(
        errorHandler: gh<_i313.ErrorHandler>(),
      ),
    );
    gh.lazySingleton<_i204.SystemMonitorService>(
      () => _i204.SystemMonitorServiceImpl(),
    );
    gh.lazySingleton<_i860.GalleryService>(() => _i860.GalleryServiceImpl());
    gh.lazySingleton<_i569.ShareService>(() => _i569.ShareServiceImpl());
    gh.lazySingleton<_i429.BackgroundWorkService>(
      () => _i546.NoopBackgroundWorkService(),
      registerFor: {_ios, _macos},
    );
    gh.lazySingleton<_i1059.AppInfoService>(() => _i1059.AppInfoServiceImpl());
    gh.lazySingleton<_i340.CookiesLocalService>(
      () => _i340.CookiesLocalServiceImpl(
        directories: gh<_i198.AppDirectories>(),
        errorHandler: gh<_i313.ErrorHandler>(),
      ),
    );
    gh.lazySingleton<_i624.FileService>(() => _i624.FileServiceImpl());
    gh.lazySingleton<_i699.ImageConvertService>(
      () => _i699.ImageConvertServiceImpl(),
    );
    gh.lazySingleton<_i875.ClipboardService>(
      () => _i875.ClipboardServiceImpl(),
    );
    gh.lazySingleton<_i454.ImageService>(() => _i454.ImageServiceImpl());
    gh.lazySingleton<_i132.FilePickerService>(
      () => _i132.FilePickerServiceImpl(),
    );
    gh.lazySingleton<_i960.SettingsLocalService>(
      () => _i960.SettingsLocalServiceImpl(
        database: gh<_i407.AppDatabase>(),
        errorHandler: gh<_i313.ErrorHandler>(),
      ),
    );
    gh.lazySingleton<_i1060.SystemMonitorRepository>(
      () => _i509.SystemMonitorRepositoryImpl(
        service: gh<_i204.SystemMonitorService>(),
        errorHandler: gh<_i313.ErrorHandler>(),
      ),
    );
    gh.lazySingleton<_i433.ErrorLogLocalService>(
      () => _i433.ErrorLogLocalServiceImpl(
        database: gh<_i407.AppDatabase>(),
        errorHandler: gh<_i313.ErrorHandler>(),
      ),
    );
    gh.lazySingleton<_i429.BackgroundWorkService>(
      () => _i731.AndroidBackgroundWorkService(),
      registerFor: {_android},
    );
    gh.lazySingleton<_i567.LibraryLocalService>(
      () => _i567.LibraryLocalServiceImpl(
        database: gh<_i407.AppDatabase>(),
        errorHandler: gh<_i313.ErrorHandler>(),
      ),
    );
    gh.lazySingleton<_i122.FileExportService>(
      () => _i945.MacosFileExportService(),
      registerFor: {_macos},
    );
    gh.lazySingleton<_i332.JobLocalService>(
      () => _i332.JobLocalServiceImpl(
        database: gh<_i407.AppDatabase>(),
        errorHandler: gh<_i313.ErrorHandler>(),
      ),
    );
    gh.lazySingleton<_i58.CookiesRepository>(
      () => _i727.CookiesRepositoryImpl(
        localService: gh<_i340.CookiesLocalService>(),
        picker: gh<_i132.FilePickerService>(),
        errorHandler: gh<_i313.ErrorHandler>(),
      ),
    );
    gh.lazySingleton<_i122.FileExportService>(
      () => _i527.IosFileExportService(),
      registerFor: {_ios},
    );
    gh.lazySingleton<_i122.FileExportService>(
      () => _i207.AndroidFileExportService(),
      registerFor: {_android},
    );
    gh.lazySingleton<_i328.MediaEngine>(
      () => _i535.AndroidMediaEngine(errorHandler: gh<_i313.ErrorHandler>()),
      registerFor: {_android, _ios},
    );
    gh.lazySingleton<_i328.MediaEngine>(
      () => _i581.MacosMediaEngine(
        errorHandler: gh<_i313.ErrorHandler>(),
        directories: gh<_i198.AppDirectories>(),
      ),
      registerFor: {_macos},
    );
    gh.lazySingleton<_i366.BackgroundWorkRepository>(
      () => _i834.BackgroundWorkRepositoryImpl(
        service: gh<_i429.BackgroundWorkService>(),
        errorHandler: gh<_i313.ErrorHandler>(),
      ),
    );
    gh.lazySingleton<_i455.AppInfoRepository>(
      () => _i219.AppInfoRepositoryImpl(
        appInfo: gh<_i1059.AppInfoService>(),
        errorLog: gh<_i433.ErrorLogLocalService>(),
        clipboard: gh<_i875.ClipboardService>(),
        errorHandler: gh<_i313.ErrorHandler>(),
      ),
    );
    gh.lazySingleton<_i901.SiteHttpClient>(
      () => _i901.SiteHttpClient(cookies: gh<_i340.CookiesLocalService>()),
    );
    gh.lazySingleton<_i653.JobRepository>(
      () => _i417.JobRepositoryImpl(localService: gh<_i332.JobLocalService>()),
    );
    gh.lazySingleton<_i715.LibraryRepository>(
      () => _i1057.LibraryRepositoryImpl(
        localService: gh<_i567.LibraryLocalService>(),
        directories: gh<_i198.AppDirectories>(),
        files: gh<_i624.FileService>(),
        share: gh<_i569.ShareService>(),
        gallery: gh<_i860.GalleryService>(),
        fileExport: gh<_i122.FileExportService>(),
        images: gh<_i454.ImageService>(),
        errorHandler: gh<_i313.ErrorHandler>(),
      ),
    );
    gh.lazySingleton<_i991.SettingsRepository>(
      () => _i645.SettingsRepositoryImpl(
        localService: gh<_i960.SettingsLocalService>(),
      ),
    );
    gh.lazySingleton<_i792.ConvertRepository>(
      () => _i399.ConvertRepositoryImpl(
        engine: gh<_i328.MediaEngine>(),
        slot: gh<_i866.FfmpegSlot>(),
        images: gh<_i699.ImageConvertService>(),
        thumbnails: gh<_i454.ImageService>(),
        picker: gh<_i495.MediaPickerService>(),
        library: gh<_i567.LibraryLocalService>(),
        directories: gh<_i198.AppDirectories>(),
        files: gh<_i624.FileService>(),
        errorHandler: gh<_i313.ErrorHandler>(),
      ),
    );
    gh.lazySingleton<_i372.FacebookPhotoExtractor>(
      () => _i372.FacebookPhotoExtractor(http: gh<_i901.SiteHttpClient>()),
    );
    gh.lazySingleton<_i780.InstagramPhotoExtractor>(
      () => _i780.InstagramPhotoExtractor(http: gh<_i901.SiteHttpClient>()),
    );
    gh.lazySingleton<_i400.ThreadsExtractor>(
      () => _i400.ThreadsExtractor(http: gh<_i901.SiteHttpClient>()),
    );
    gh.lazySingleton<_i626.TikTokPhotoExtractor>(
      () => _i626.TikTokPhotoExtractor(http: gh<_i901.SiteHttpClient>()),
    );
    gh.lazySingleton<_i784.XImageExtractor>(
      () => _i784.XImageExtractor(http: gh<_i901.SiteHttpClient>()),
    );
    gh.lazySingleton<_i245.MediaFileDownloader>(
      () => _i245.MediaFileDownloader(http: gh<_i901.SiteHttpClient>()),
    );
    gh.factory<_i192.ConvertMediaUseCase>(
      () => _i192.ConvertMediaUseCase(convert: gh<_i792.ConvertRepository>()),
    );
    gh.lazySingleton<_i239.PhotoExtractors>(
      () => _i239.PhotoExtractors(
        instagram: gh<_i780.InstagramPhotoExtractor>(),
        tiktok: gh<_i626.TikTokPhotoExtractor>(),
        facebook: gh<_i372.FacebookPhotoExtractor>(),
        threads: gh<_i400.ThreadsExtractor>(),
        x: gh<_i784.XImageExtractor>(),
      ),
    );
    gh.lazySingleton<_i434.MediaRepository>(
      () => _i398.MediaRepositoryImpl(
        engine: gh<_i328.MediaEngine>(),
        directories: gh<_i198.AppDirectories>(),
        files: gh<_i624.FileService>(),
        cookies: gh<_i340.CookiesLocalService>(),
        settings: gh<_i991.SettingsRepository>(),
        releases: gh<_i879.EngineReleaseService>(),
        slot: gh<_i866.FfmpegSlot>(),
      ),
    );
    gh.lazySingleton<_i568.PostRepository>(
      () => _i591.PostRepositoryImpl(
        extractors: gh<_i239.PhotoExtractors>(),
        http: gh<_i901.SiteHttpClient>(),
        downloader: gh<_i245.MediaFileDownloader>(),
        images: gh<_i454.ImageService>(),
        cookies: gh<_i340.CookiesLocalService>(),
        directories: gh<_i198.AppDirectories>(),
        errorHandler: gh<_i313.ErrorHandler>(),
      ),
    );
    gh.factory<_i898.ResolveLinkUseCase>(
      () => _i898.ResolveLinkUseCase(
        media: gh<_i434.MediaRepository>(),
        posts: gh<_i568.PostRepository>(),
      ),
    );
    gh.factory<_i948.DownloadMediaUseCase>(
      () => _i948.DownloadMediaUseCase(
        media: gh<_i434.MediaRepository>(),
        library: gh<_i715.LibraryRepository>(),
        posts: gh<_i568.PostRepository>(),
      ),
    );
    return this;
  }
}

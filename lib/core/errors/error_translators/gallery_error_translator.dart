import 'package:gal/gal.dart';
import 'package:media_downloader/core/data/states/data_state.dart';
import 'package:media_downloader/core/errors/error_translators/error_translator.dart';
import 'package:media_downloader/core/messages/app_messages.dart';

/// Save to Photos failures.
final class GalleryErrorTranslator implements ErrorTranslator<GalException> {
  @override
  bool matches(Object error) => error is GalException;

  @override
  FailureState<T> translate<T>(GalException error) => FailureState(
    message: switch (error.type) {
      .permissionDenied => LibraryMessages.photosAccessDenied,
      .notEnoughSpace => CommonMessages.noSpace,
      .notSupportedFormat => LibraryMessages.photosUnsupportedFormat,
      .unexpected => LibraryMessages.saveToPhotosFailed,
    },
    error: error.toString(),
  );
}

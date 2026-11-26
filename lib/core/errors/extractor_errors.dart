import 'package:media_tool/core/messages/app_messages.dart';
import 'package:media_tool/domain/models/site.dart';

/// Why a photo extractor couldn't read a post.
enum ExtractorFailure { loginRequired, notFound, noMedia, broken }

/// Thrown by photo extractors. [detail] is for the error log only and never
/// holds cookies or full URLs with query strings.
final class const ExtractorException(
  final ExtractorFailure failure, {
  required final Site site,
  final String detail = '',
}) implements Exception {
  /// The user's message for [failure].
  String get message => switch (failure) {
    .loginRequired => ExtractorMessages.needsLogin(site.label),
    .notFound => ExtractorMessages.notFound,
    .noMedia => ExtractorMessages.noMedia,
    .broken => ExtractorMessages.broken,
  };

  @override
  String toString() => 'ExtractorException(${site.name}, ${failure.name}): $detail';
}

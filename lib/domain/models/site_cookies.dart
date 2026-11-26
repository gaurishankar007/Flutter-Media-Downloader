import 'package:equatable/equatable.dart';
import 'package:media_downloader/domain/models/site.dart';

/// The imported cookies.txt of one site.
final class const SiteCookies({required final Site site, required final int count, required final DateTime importedAt})
    extends Equatable {
  @override
  List<Object?> get props => [site, count, importedAt];
}

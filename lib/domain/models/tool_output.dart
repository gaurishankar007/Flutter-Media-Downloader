import 'package:equatable/equatable.dart';
import 'package:media_tool/domain/models/media_kind.dart';

/// One file a tool wrote into its job's work folder, before it moves into the Library.
final class const ToolOutput({
  required final String path,
  required final MediaKind kind,
  final String? thumbnailPath,
  final int? durationMs,
}) extends Equatable {
  @override
  List<Object?> get props => [path, kind, thumbnailPath, durationMs];
}

import 'package:equatable/equatable.dart';

/// What the download engine reported at init.
final class const EngineInfo({required final String ytDlpVersion, final List<String> encoders = const []})
    extends Equatable {
  @override
  List<Object?> get props => [ytDlpVersion, encoders];
}

import 'package:equatable/equatable.dart';

/// The result of an engine update check.
final class const EngineUpdate({required final String latestVersion, required final bool available}) extends Equatable {
  @override
  List<Object?> get props => [latestVersion, available];
}

import 'package:media_tool/core/data/states/data_state.dart';
import 'package:media_tool/core/errors/error_handler.dart';
import 'package:media_tool/core/messages/app_messages.dart';
import 'package:media_tool/domain/models/job_progress.dart';
import 'package:media_tool/domain/models/tool_event.dart';

/// Cancel flags and error-handled steps shared by the tool runners.
mixin ToolRunnerSteps {
  final Set<String> _cancelled = {};

  ErrorHandler get errorHandler;

  /// Asks [jobId] to stop at its next step.
  void cancel(String jobId) => _cancelled.add(jobId);

  bool isCancelled(String jobId) => _cancelled.contains(jobId);

  /// Forgets [jobId]'s cancel flag once it ended.
  void finish(String jobId) => _cancelled.remove(jobId);

  /// Runs [step] inside `ErrorHandler.execute`; returns the message to show
  /// when it failed, or null. [fallback] replaces the generic message.
  Future<String?> attempt(String action, Future<void> Function() step, {required String fallback}) async {
    final result = await errorHandler.execute<void>(action: action, () async {
      await step();
      return const SuccessState.nil();
    });
    if (result case FailureState(:final message)) {
      return message == null || message == CommonMessages.genericError ? fallback : message;
    }
    return null;
  }

  static ToolEvent progress(double fraction) =>
      ToolProgressed(JobProgress(stage: .processing, fraction: fraction.clamp(0, 1)));
}

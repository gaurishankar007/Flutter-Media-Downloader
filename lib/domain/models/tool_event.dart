import 'package:media_tool/domain/models/job_progress.dart';
import 'package:media_tool/domain/models/tool_output.dart';

/// One step of a running tool, for RunToolUseCase.
sealed class const ToolEvent();

final class const ToolProgressed(final JobProgress progress) extends ToolEvent;

/// Every output, in order, in the job's work folder.
final class const ToolFinished(final List<ToolOutput> outputs) extends ToolEvent;

final class const ToolFailed(final String message) extends ToolEvent;

final class const ToolCancelled() extends ToolEvent;

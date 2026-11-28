import 'package:media_tool/core/types/types.dart';
import 'package:media_tool/domain/models/library_item.dart';
import 'package:media_tool/domain/models/local_media_info.dart';
import 'package:media_tool/domain/models/pick_source.dart';
import 'package:media_tool/domain/models/tool_event.dart';
import 'package:media_tool/domain/models/tool_input.dart';
import 'package:media_tool/domain/models/tool_output.dart';
import 'package:media_tool/domain/models/tool_request.dart';

/// The Tools tab: reads picked files, runs PDF / GIF / video / image tools
/// and adds the results to the Library. See docs/features/tools.md.
abstract interface class ToolRepository {
  /// Asks for one or more [input] files from Photos or Files, copies them into
  /// `work/` and reads them. Empty when the user cancels.
  FutureList<LocalMediaInfo> pick(ToolInput input, {required PickSource from, required bool multiple});

  /// Reads Library items in place (they're never changed), in [ids] order.
  FutureList<LocalMediaInfo> fromLibrary(List<String> ids);

  /// Deletes picked files' working copies. Library files are left alone.
  Future<void> discard(List<LocalMediaInfo> sources);

  /// Small JPGs of every page of [pdf], in order, for Organize pages.
  FutureList<String> pageThumbnails(LocalMediaInfo pdf);

  /// Runs [request] into [jobId]'s work folder. ffmpeg tools wait for the
  /// shared ffmpeg slot first. Ends with finished, failed or cancelled.
  Stream<ToolEvent> run(String jobId, ToolRequest request);

  /// Moves the outputs into the Library (`origin: tool`), grouped when there
  /// are several, and adds their rows.
  FutureList<LibraryItem> save(ToolRequest request, List<ToolOutput> outputs);

  Future<void> cancel(String jobId);

  /// Deletes [jobId]'s work folder.
  Future<void> clearWork(String jobId);
}

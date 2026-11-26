/// One event of a running engine job. See docs/engine/media_engine.md.
sealed class const EngineEvent();

/// A stdout line (progress or a stage marker).
final class const EngineLine(final String text) extends EngineEvent;

final class const EngineDone() extends EngineEvent;

/// Failed; [output] is the engine's error output.
final class const EngineFailed(final String output) extends EngineEvent;

final class const EngineCancelled() extends EngineEvent;

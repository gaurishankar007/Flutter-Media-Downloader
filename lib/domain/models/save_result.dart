/// The confirmed outcome of a save that didn't fail. Only [saved] is followed
/// by the "remove from app?" prompt. See docs/features/library.md.
enum SaveResult { saved, cancelled }

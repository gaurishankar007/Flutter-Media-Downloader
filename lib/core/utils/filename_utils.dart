/// Turns titles into safe filenames. See docs/core/core_services.md#filenames.
abstract final class FilenameUtils {
  static const _maxLength = 80;
  static final _illegal = RegExp(r'[/\\:*?"<>|\x00-\x1F]');
  static final _trailingTags = RegExp(r'(\s+[#@][^\s#@]+)+\s*$');
  static final _spaces = RegExp(r'\s+');

  /// `Title [1080p].mp4`. Keeps Unicode (Hindi, emoji); only replaces
  /// characters filesystems reject, drops trailing #hashtags / @mentions,
  /// and trims to about 80 characters on a word boundary.
  static String fromTitle(String title, {required String extension, String? suffix, String fallback = 'download'}) {
    var name = title.replaceAll(_trailingTags, '').replaceAll(_illegal, ' ').replaceAll(_spaces, ' ').trim();
    // Names starting with a dot are hidden files.
    name = name.replaceFirst(RegExp(r'^\.+'), '').trim();
    if (name.length > _maxLength) {
      final cut = name.substring(0, _maxLength);
      final lastSpace = cut.lastIndexOf(' ');
      name = (lastSpace > _maxLength / 2 ? cut.substring(0, lastSpace) : cut).trim();
    }
    if (name.isEmpty) {
      name = fallback;
    }
    return '$name${suffix == null ? '' : ' $suffix'}.$extension';
  }

  /// A photo post's file: `<user> <postid> 01.jpg`; [index] is left out for a
  /// single item. Falls back to [fallback] (the title) without a user or id.
  static String forPostItem({
    required String extension,
    required String fallback,
    String? uploader,
    String? postId,
    int? index,
  }) {
    final stem = [?uploader, ?postId].join(' ');
    return fromTitle(stem.isEmpty ? fallback : stem, extension: extension, suffix: index?.toString().padLeft(2, '0'));
  }
}

/// Read cookies straight from a browser (`--cookies-from-browser`), on the desktops.
enum CookieBrowser {
  none(null),
  safari('safari'),
  chrome('chrome'),
  firefox('firefox');

  new(this.ytDlpName);

  /// The name yt-dlp expects, or `null` for [none].
  final String? ytDlpName;

  /// The choices on [operatingSystem] (`Platform.operatingSystem`); empty
  /// where yt-dlp can't read browsers (phones). Windows leaves out Chrome:
  /// its app-bound cookie encryption blocks other programs.
  static List<CookieBrowser> availableOn(String operatingSystem) => switch (operatingSystem) {
    'macos' => values,
    'linux' => const [none, chrome, firefox],
    'windows' => const [none, firefox],
    _ => const [],
  };
}

/// macOS only: read cookies straight from a browser (`--cookies-from-browser`).
enum CookieBrowser {
  none(null),
  safari('safari'),
  chrome('chrome'),
  firefox('firefox');

  new(this.ytDlpName);

  /// The name yt-dlp expects, or `null` for [none].
  final String? ytDlpName;
}

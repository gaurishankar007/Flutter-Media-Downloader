/// A supported social site. See docs/engine/site_support.md.
enum Site {
  youtube('YouTube', ['youtube.com', 'youtu.be']),
  facebook('Facebook', ['facebook.com', 'fb.watch', 'fb.com']),
  instagram('Instagram', ['instagram.com', 'instagr.am']),
  tiktok('TikTok', ['tiktok.com']),
  x('X', ['x.com', 'twitter.com', 't.co']),
  threads('Threads', ['threads.net', 'threads.com']);

  new(this.label, this.domains);

  /// Display name.
  final String label;

  /// Registrable domains; subdomains (www., m., vm., music.) match too.
  final List<String> domains;
}

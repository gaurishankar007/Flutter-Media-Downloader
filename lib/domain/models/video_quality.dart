/// The default video quality in Settings: the preview preselects the highest
/// option at or below it. [resolution] is `null` for Best.
enum VideoQuality {
  best(null),
  p2160(2160),
  p1440(1440),
  p1080(1080),
  p720(720),
  p480(480);

  new(this.resolution);

  final int? resolution;
}

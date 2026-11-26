/// MP3 bitrates offered for audio downloads.
enum AudioQuality {
  kbps320(320),
  kbps192(192),
  kbps128(128);

  new(this.kbps);

  final int kbps;
}

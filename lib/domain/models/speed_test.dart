/// A user-started speed test on the System page.
enum SpeedTest {
  /// Fills, scans and copies a large block of RAM.
  memory,

  /// Writes and reads back a temporary file, bypassing the system cache.
  storage,
}

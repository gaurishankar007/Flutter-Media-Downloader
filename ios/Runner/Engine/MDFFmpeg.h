#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, MDFFmpegOutcome) {
  MDFFmpegOutcomeDone,
  MDFFmpegOutcomeFailed,
  MDFFmpegOutcomeCancelled,
};

/// Runs ffmpeg / ffprobe in-process through FFmpegKit (iOS can't start
/// processes). Arguments come from Dart (FfmpegCommandBuilder) or from yt-dlp's
/// postprocessors through the Python shim; this class only runs them.
/// See docs/engine/ios_engine.md.
@interface MDFFmpeg : NSObject

/// Video encoder names from `ffmpeg -encoders`.
+ (NSArray<NSString *> *)videoEncoders;

/// Runs ffmpeg (or ffprobe when `probe`) and blocks until it ends. `output`
/// gets every log line; `stdoutText` only what the tool printed to stdout.
/// While it runs, `cancelJob:` with the same `jobId` stops it.
+ (int)runSyncWithArguments:(NSArray<NSString *> *)arguments
                      probe:(BOOL)probe
                      jobId:(nullable NSString *)jobId
                     output:(NSString *_Nullable *_Nonnull)output
                 stdoutText:(NSString *_Nullable *_Nonnull)stdoutText;

/// Starts ffmpeg for a Dart job. Progress arrives as `-progress`-style lines
/// (`out_time_us=…`), then `completion` runs once.
+ (void)startJob:(NSString *)jobId
       arguments:(NSArray<NSString *> *)arguments
          onLine:(void (^)(NSString *line))onLine
      completion:(void (^)(MDFFmpegOutcome outcome, NSString *errorOutput))completion;

/// Cancels the ffmpeg session running for `jobId`. Returns whether one was.
+ (BOOL)cancelJob:(NSString *)jobId;

@end

NS_ASSUME_NONNULL_END

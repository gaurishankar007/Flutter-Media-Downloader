#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Receives each stdout line a yt-dlp job prints.
typedef void (^MDLineHandler)(NSString *jobId, NSString *line);

/// The embedded CPython interpreter (one per app lifetime) that runs yt-dlp
/// through `engine_shim.py`. Calls block, so make them off the main thread on a
/// thread with a large stack. See docs/engine/ios_engine.md.
@interface MDPythonRuntime : NSObject

/// Starts Python once. `home` holds `lib/python3.x`; `paths` go on `sys.path`
/// (as site dirs, so `.pth` files work). Later calls return the first result.
+ (BOOL)startWithHome:(NSString *)home
                paths:(NSArray<NSString *> *)paths
          lineHandler:(MDLineHandler)lineHandler
                error:(NSString *_Nullable *_Nullable)error;

+ (BOOL)isStarted;

/// Calls `engine_shim.<function>(*arguments)` and returns `str()` of its result.
+ (nullable NSString *)call:(NSString *)function
                  arguments:(NSArray<NSString *> *)arguments
                      error:(NSString *_Nullable *_Nullable)error;

@end

NS_ASSUME_NONNULL_END

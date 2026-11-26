#import "MDFFmpeg.h"

@import ffmpegkit;

// Log lines are kept for error messages; only the tail is ever sent to Dart.
static const NSUInteger kErrorTailLength = 4000;

@implementation MDFFmpeg

static NSMutableDictionary<NSString *, NSNumber *> *sessions;
static NSMutableSet<NSString *> *cancelled;

+ (void)initialize {
  if (self == [MDFFmpeg class]) {
    sessions = [NSMutableDictionary dictionary];
    cancelled = [NSMutableSet set];
    // Sessions are tracked here; FFmpegKit's own history only holds memory.
    [FFmpegKitConfig setSessionHistorySize:4];
  }
}

+ (NSArray<NSString *> *)videoEncoders {
  NSString *output = nil;
  NSString *stdoutText = nil;
  [self runSyncWithArguments:@[ @"-hide_banner", @"-encoders" ] probe:NO jobId:nil output:&output stdoutText:&stdoutText];
  NSMutableArray<NSString *> *encoders = [NSMutableArray array];
  // Lines look like " V....D libx264  libx264 H.264 ...": keep video encoder names.
  for (NSString *raw in [output componentsSeparatedByCharactersInSet:NSCharacterSet.newlineCharacterSet]) {
    NSString *line = [raw stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet];
    if (line.length > 7 && [line characterAtIndex:0] == 'V' && [line characterAtIndex:6] == ' ') {
      NSString *rest = [[line substringFromIndex:7] stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet];
      NSString *name = [rest componentsSeparatedByString:@" "].firstObject;
      if (name.length > 0 && ![name isEqualToString:@"="]) {
        [encoders addObject:name];
      }
    }
  }
  return encoders;
}

+ (int)runSyncWithArguments:(NSArray<NSString *> *)arguments
                      probe:(BOOL)probe
                      jobId:(NSString *)jobId
                     output:(NSString **)output
                 stdoutText:(NSString **)stdoutText {
  dispatch_semaphore_t finished = dispatch_semaphore_create(0);
  id<Session> session;
  if (probe) {
    FFprobeSession *probeSession =
        [FFprobeSession create:arguments
            withCompleteCallback:^(FFprobeSession *_) { dispatch_semaphore_signal(finished); }];
    [self track:probeSession jobId:jobId];
    [FFmpegKitConfig asyncFFprobeExecute:probeSession];
    session = probeSession;
  } else {
    FFmpegSession *ffmpegSession =
        [FFmpegSession create:arguments
            withCompleteCallback:^(FFmpegSession *_) { dispatch_semaphore_signal(finished); }];
    [self track:ffmpegSession jobId:jobId];
    [FFmpegKitConfig asyncFFmpegExecute:ffmpegSession];
    session = ffmpegSession;
  }
  dispatch_semaphore_wait(finished, DISPATCH_TIME_FOREVER);
  [self untrack:jobId];
  if (jobId != nil) {
    @synchronized(cancelled) {
      [cancelled removeObject:jobId];
    }
  }

  NSMutableString *all = [NSMutableString string];
  NSMutableString *printed = [NSMutableString string];
  for (Log *log in [session getAllLogsWithTimeout:5000]) {
    NSString *message = [log getMessage] ?: @"";
    [all appendString:message];
    // FFmpegKit routes what the tool prints (ffprobe's JSON, -version) through
    // this level; ordinary log lines keep their own.
    if ([log getLevel] == LevelAVLogStdErr) {
      [printed appendString:message];
    }
  }
  *output = all;
  *stdoutText = printed;
  ReturnCode *code = [session getReturnCode];
  if (code == nil) {
    return 1;
  }
  return [code getValue];
}

+ (void)startJob:(NSString *)jobId
       arguments:(NSArray<NSString *> *)arguments
          onLine:(void (^)(NSString *))onLine
      completion:(void (^)(MDFFmpegOutcome, NSString *))completion {
  FFmpegSession *session = [FFmpegSession
                     create:arguments
       withCompleteCallback:^(FFmpegSession *finished) {
             [self untrack:jobId];
             BOOL wasCancelled;
             @synchronized(cancelled) {
               wasCancelled = [cancelled containsObject:jobId];
               [cancelled removeObject:jobId];
             }
             ReturnCode *code = [finished getReturnCode];
             if (wasCancelled || [ReturnCode isCancel:code]) {
               completion(MDFFmpegOutcomeCancelled, @"");
             } else if ([ReturnCode isSuccess:code]) {
               onLine(@"progress=end");
               completion(MDFFmpegOutcomeDone, @"");
             } else {
               NSString *logs = [finished getAllLogsAsStringWithTimeout:5000] ?: @"";
               if (logs.length > kErrorTailLength) {
                 logs = [logs substringFromIndex:logs.length - kErrorTailLength];
               }
               completion(MDFFmpegOutcomeFailed, logs);
             }
           }
                withLogCallback:nil
         withStatisticsCallback:^(Statistics *statistics) {
           // Same shape as ffmpeg's `-progress pipe:1` output, which can't
           // reach us in-process, so DownloadProgressParser works unchanged.
           long long micros = (long long)([statistics getTime] * 1000.0);
           onLine([NSString stringWithFormat:@"out_time_us=%lld", micros]);
           onLine(@"progress=continue");
         }];
  [self track:session jobId:jobId];
  [FFmpegKitConfig asyncFFmpegExecute:session];
}

+ (BOOL)cancelJob:(NSString *)jobId {
  NSNumber *sessionId;
  @synchronized(sessions) {
    sessionId = sessions[jobId];
  }
  if (sessionId == nil) {
    return NO;
  }
  @synchronized(cancelled) {
    [cancelled addObject:jobId];
  }
  [FFmpegKit cancel:sessionId.longValue];
  return YES;
}

+ (void)track:(id<Session>)session jobId:(NSString *)jobId {
  if (jobId.length == 0) {
    return;
  }
  @synchronized(sessions) {
    sessions[jobId] = @([session getSessionId]);
  }
}

+ (void)untrack:(NSString *)jobId {
  if (jobId.length == 0) {
    return;
  }
  @synchronized(sessions) {
    [sessions removeObjectForKey:jobId];
  }
}

@end

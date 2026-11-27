/// Every user-facing string the app writes itself.
///
/// Bump [kMessagesVersion] and add a changelog line to a message's doc comment
/// when its wording changes or it's removed. See docs/core/app_messages.md.
library;

/// 2: removed DownloadMessages.engineComing (the engine exists now).
/// 3: EngineMessages.needsLogin and botCheck point to cookies; SettingsMessages engine and
///    cookies tiles reworded (cookiesBody, engineBody), defaultQuality →
///    defaultVideoQuality.
/// 4: EngineMessages.noVideo no longer says photos are coming; added photo post
///    strings (DownloadMessages photos…, ExtractorMessages).
/// 5: removed EngineMessages.notOnThisPlatform (Android, iOS and macOS all have
///    engines now); removed duplicates DownloadMessages.retry (use
///    CommonMessages.retry) and ExtractorMessages.network (use EngineMessages.network);
///    removed CommonMessages.comingSoon (every feature is built).
/// 6: added NavMessages.system (System is a tab now); removed SystemMessages.openSystem.
/// 7: added DesignGalleryMessages toast demo strings, ConvertMessages.savePhotosShort /
///    saveFilesShort, LibraryMessages.loadFailed, SystemMessages.unavailableTitle / Body.
/// 8: added SystemMessages storage and battery strings.
/// 9: added SystemMessages.batteryCycles and batteryHealthWithPercent.
/// 10: added SystemMessages hardware rows (battery capacity, CPU, GPU, RAM, drive),
///     cpuInfoBody / gpuInfoBody and speed test strings.
const kMessagesVersion = 10;

abstract final class CommonMessages {
  /// Fallback for any failure without a clearer message.
  static const genericError = 'Something went wrong. Please try again.';

  /// Storage failures (FileSystemErrorTranslator).
  static const noSpace = 'Not enough storage on this device.';
  static const storageError = "Couldn't read or write the file.";

  /// Button: retry a failed action.
  static const retry = 'Retry';

  /// Button: confirm a dialog.
  static const ok = 'OK';

  /// Buttons and semantic labels shared by dialogs, sheets and cards.
  static const cancel = 'Cancel';
  static const close = 'Close';
  static const back = 'Back';
  static const share = 'Share';
  static const remove = 'Remove';
  static const delete = 'Delete';
  static const moreActions = 'More actions';
  static const selectAll = 'Select all';
  static const selectNone = 'Select none';

  /// ErrorState default title.
  static const errorTitle = "That didn't work";
}

abstract final class JobStageMessages {
  /// StageLabel text for each job stage.
  static const queued = 'Queued';
  static const downloading = 'Downloading';
  static const processing = 'Processing';
  static const saving = 'Saving';
  static const done = 'Done';
  static const failed = 'Failed';
  static const cancelled = 'Cancelled';

  /// Semantic label of a job card's cancel button.
  static const cancelJob = 'Cancel download';
}

abstract final class SavedPromptMessages {
  /// "Saved. Remove from app?" prompt after a confirmed Save to Photos / Files.
  /// {place} is [photos] or [files].
  static String title(String place) => 'Saved to $place';
  static String body(String place) => "It's safe in $place now. Remove the copy in this app to free up space?";
  static const photos = 'Photos';
  static const files = 'Files';
  static const removeFromApp = 'Remove from app';
  static const keep = 'Keep';
  static const dontAskAgain = "Don't ask again";
}

abstract final class NavMessages {
  /// Bottom nav / sidebar tab labels.
  static const download = 'Download';
  static const library = 'Library';
  static const convert = 'Convert';
  static const system = 'System';
  static const settings = 'Settings';
}

abstract final class StartupMessages {
  /// StartupErrorApp: initialisation failed.
  static const startupFailedTitle = "The app couldn't start";
  static const startupFailedBody =
      'Something went wrong while preparing the app. Try again, and reinstall if it keeps happening.';

  /// One-time rights notice dialog, shown on first launch and from Settings → About.
  static const rightsTitle = 'Before you start';
  static const rightsBody =
      "Only download videos, music and photos you have the right to save, such as your own posts or content the owner allows you to keep. You're responsible for what you download.\n\nEverything stays on this device: no account, no uploads, no tracking.";
  static const rightsAccept = 'I understand';
}

abstract final class DownloadMessages {
  /// Download screen header.
  static const title = 'Paste a link';
  static const subtitle = 'Videos, music and photos from your favourite sites, saved right here.';

  /// LinkField placeholder.
  static const linkHint = 'https://…';

  /// LinkField: Paste button and its semantic label.
  static const paste = 'Paste';
  static const clearLink = 'Clear link';

  /// LinkField: clipboard has no URL.
  static const clipboardEmpty = 'Copy a link first, then tap Paste.';

  /// Hint under LinkField: URL isn't from a supported site.
  static const unsupportedLink = "This link isn't from a supported site.";

  /// Hint under LinkField: text isn't a URL.
  static const notALink = "That doesn't look like a link.";

  /// Hint under LinkField: supported site detected. {site} is the site name.
  static String recognised(String site) => '$site link';

  /// Preview button under a recognised link.
  static const preview = 'Preview';

  /// Preview sheet.
  static const preparingEngine = 'Getting the download engine ready…';
  static const preparingEngineBody = 'The first start takes a few seconds.';
  static const loadingPreview = 'Looking up the link…';
  static const video = 'Video';
  static const audio = 'Audio';
  static const photos = 'Photos';

  /// Preview: photo selection. {selected} of {total} items chosen.
  static String photosSelected(int selected, int total) => '$selected of $total selected';
  static const slideshowVideo = 'Save as video';
  static const slideshowVideoBody = 'One MP4 with the photos and the post’s music';

  /// Download button for a photo post. {count} chosen items.
  static String downloadPhotos(int count, {bool allPhotos = true}) => switch (count) {
    0 => 'Choose at least one',
    1 => allPhotos ? 'Download 1 photo' : 'Download 1 item',
    _ => allPhotos ? 'Download $count photos' : 'Download $count items',
  };

  /// Job card detail of a photo post. {count} items.
  static String photoCount(int count) => count == 1 ? '1 photo' : '$count photos';
  static String itemCount(int count) => count == 1 ? '1 item' : '$count items';
  static const quality = 'Quality';
  static const best = 'Best';
  static String resolution(int pixels) => switch (pixels) {
    2160 => '4K',
    _ => '${pixels}p',
  };
  static String kbps(int kbps) => '$kbps kbps';
  static const reencodeHint = 'This quality is converted for iPhone after downloading, which takes a while on a phone.';
  static String download(String? size) => size == null ? 'Download' : 'Download · $size';

  /// Preview: semantic label of the ▶ on the thumbnail, and its failure.
  static const playPreview = 'Play preview';
  static const previewFailed = "The preview can't be played. You can still download it.";

  /// Toast after Download is tapped in the preview.
  static const added = 'Added to downloads';

  /// Job list sections and actions.
  static const inProgress = 'In progress';
  static const finished = 'Finished';
  static const clearFinished = 'Clear finished';
  static const dismiss = 'Dismiss';
  static const waiting = 'Waiting…';
  static const merging = 'Merging video and audio';
  static const extractingAudio = 'Converting to MP3';
  static const convertingForIphone = 'Converting for iPhone';
  static const finishing = 'Finishing up';
  static const convertingPhotos = 'Converting photos to JPG';
  static const makingSlideshow = 'Making the video';
  static const saving = 'Saving to your library';

  /// Job card numbers. {percent} 0–100.
  static String percent(int percent) => '$percent%';
  static String etaSeconds(int seconds) => '$seconds s left';
  static String etaMinutes(int minutes) => '$minutes min left';

  /// Remove dialog on a finished job.
  static const removeTitle = 'Remove from app?';
  static const removeBody = 'The file will be deleted from the app. Copies you saved to Photos or Files stay.';

  /// A job that was running when the app was closed.
  static const interrupted = 'The app was closed during this download.';

  /// Queue section header and empty state.
  static const downloads = 'Downloads';
  static const emptyTitle = 'No downloads yet';
  static const emptyBody = 'Paste a link above to get started. Finished downloads show up here, ready to share.';
}

abstract final class EngineMessages {
  /// Engine failures (EngineErrors), most specific first.
  static const botCheck = 'YouTube wants a sign-in. Import YouTube cookies in Settings, or try again later.';
  static const needsLogin = 'This post needs you to be logged in. Import cookies for this site in Settings.';
  static const unsupported = 'This link isn’t something that can be downloaded.';

  /// 4: no longer says photo downloads are coming.
  static const noVideo = 'This post has no video.';
  static const unavailable = 'This video isn’t available. It may have been removed or made private.';
  static const formatUnavailable = 'That quality isn’t available for this video. Try another one.';
  static const forbidden = 'The site refused the download. Try again in a little while.';
  static const network = 'Couldn’t reach the site. Check your internet connection and try again.';
  static const convertFailed = 'Converting the video failed. Try again, or turn off iPhone-compatible.';
  static const failed = 'The download failed. Try again; if it keeps failing, the site may have changed.';

  /// Engine init failed.
  static const initFailed = 'The download engine couldn’t start.';

  /// The site changed and yt-dlp can't read it any more.
  static const extractorBroken = 'The site changed. Update the download engine, then try again.';

  /// Job card actions for the two failures above that have a fix.
  static const updateEngine = 'Update engine';
  static const importCookies = 'Cookies';

  /// Update and update-check results.
  static const updateFailed = 'Couldn’t update the download engine. Check your connection and try again.';
  static const checkFailed = 'Couldn’t check for engine updates. Check your connection and try again.';
  static const upToDate = 'The download engine is already up to date.';
  static String updated(String version) => 'Download engine updated to $version.';
}

abstract final class ExtractorMessages {
  /// Photo extractor failures (ExtractorException, DioErrorTranslator).
  static String needsLogin(String site) => 'This post needs you to be logged in. Import $site cookies in Settings.';
  static const notFound = 'This post isn’t available. It may have been removed or made private.';
  static const noMedia = 'Couldn’t find any photos or videos in this post.';
  static const broken = 'The site changed and this post can’t be read right now. Try again after an app update.';
  static const rateLimited = 'The site is limiting requests. Try again in a few minutes.';
  static const downloadFailed = 'Downloading the photos failed. Try again.';
}

abstract final class LibraryMessages {
  /// Library screen header.
  static const title = 'Library';
  static const subtitle = 'Everything you download or convert, in one place.';

  /// Filter chips.
  static const all = 'All';
  static const videos = 'Videos';
  static const audio = 'Audio';
  static const photos = 'Photos';

  /// Empty state.
  static const emptyTitle = 'Nothing here yet';
  static const emptyBody = 'Downloads and conversions land here. Save them to Photos or Files whenever you like.';
  static const goToDownload = 'Go to Download';

  /// Empty result of a search or filter.
  static const noMatchesTitle = 'No matches';
  static const noMatchesBody = 'Try another search or filter.';

  /// Error state when the Library can't be read.
  static const loadFailed = "Your Library couldn't be read. Restart the app to try again.";

  /// Search field, sort menu and storage summary. {count} items, {size} formatted bytes.
  static const searchHint = 'Search by title or uploader';
  static const sort = 'Sort';
  static const sortNewest = 'Newest';
  static const sortOldest = 'Oldest';
  static const sortLargest = 'Largest';
  static String summary(int count, String size) => '$count ${count == 1 ? 'item' : 'items'} · $size';

  /// Selection mode. {count} selected items.
  static const select = 'Select';
  static const done = 'Done';
  static String selected(int count) => '$count selected';

  /// Item actions (action sheet and viewer).
  static const saveToPhotos = 'Save to Photos';
  static const saveToFiles = 'Save to Files';
  static const info = 'Info';
  static const play = 'Play';
  static const pause = 'Pause';
  static const mute = 'Mute';
  static const unmute = 'Unmute';

  /// Toasts after an action.
  static const savedToPhotos = 'Saved to Photos';
  static const savedToFiles = 'Saved to Files';
  static const deleted = 'Deleted from the app';
  static const audioNotForPhotos = "Audio can't go to Photos. Use Save to Files instead.";

  /// Save failures (GalleryErrorTranslator).
  static const photosAccessDenied = 'Allow access to Photos in Settings to save there.';
  static const photosUnsupportedFormat = "Photos can't open this file type. Use Save to Files instead.";
  static const saveToPhotosFailed = "Couldn't save to Photos.";

  /// Delete dialog. {count} items.
  static String deleteTitle(int count) => count == 1 ? 'Delete from app?' : 'Delete $count items from app?';
  static const deleteBody = 'The file will be deleted from the app. Copies you saved to Photos or Files stay.';

  /// Info sheet rows.
  static const infoSource = 'Source';
  static const infoSize = 'Size';
  static const infoFormat = 'Format';
  static const infoDuration = 'Duration';
  static const infoAdded = 'Added';
  static const infoFile = 'File';

  /// Grouped post card: semantic label. {count} items.
  static String groupCount(int count) => '$count items';

  /// Viewer: the item was deleted or can't be played.
  static const cantPlay = "This file can't be played here.";
}

abstract final class ConvertMessages {
  /// Convert screen header.
  static const title = 'Convert';
  static const subtitle = "Change a file's format, or make it smaller.";

  /// Source section and tiles.
  static const pickFile = 'Pick a file';
  static const fromLibrary = 'From Library';
  static const fromLibraryBody = 'Anything you downloaded';
  static const fromPhotos = 'From Photos';
  static const fromPhotosBody = 'Videos and photos on this device';
  static const fromFiles = 'From Files';
  static const fromFilesBody = 'Any video, audio or image file';

  /// "What you can do" section.
  static const whatYouCanDo = 'What you can do';
  static const videoFormats = 'Video';
  static const audioFormats = 'Audio';
  static const imageFormats = 'Images';
  static const shrink = 'Make smaller';
  static const shrinkBody =
      'Lower the resolution or quality of videos and photos, and see the size before you keep it.';

  /// Library picker sheet.
  static const pickFromLibrary = 'Pick from Library';
  static const libraryEmpty = 'Nothing in the Library yet. Download something first.';

  /// Picked file card. {duration} formatted, {size} formatted bytes.
  static const reading = 'Reading the file…';
  static const change = 'Change';
  static const original = 'Original';

  /// Step 2: mode and options.
  static const whatToDo = 'What to do';
  static const convertMode = 'Convert';
  static const compressMode = 'Compress';
  static const convertTo = 'Convert to';
  static const noTargets = "There's nothing this file can be converted to on this device.";
  static const iphoneCompatible = 'iPhone-compatible';
  static const iphoneCompatibleBody = 'H.264 / HEVC with AAC audio, so it plays in the Photos app.';
  static const preset = 'Quality';
  static const presetHigh = 'High';
  static const presetMedium = 'Medium';
  static const presetSmall = 'Small';
  static const maxResolution = 'Max resolution';
  static String resolution(int height) => '${height}p';
  static const aimForSize = 'Aim for a size';
  static String aboutMb(int mb) => 'About $mb MB';
  static const targetTooLow = 'That size is very small for this video. Pick a lower resolution for a sharper result.';
  static const imageSize = 'Size';
  static String pixels(int side) => '$side px';
  static String percent(int percent) => '$percent%';
  static const imageQuality = 'Quality';
  static const stripMetadata = 'Remove location and camera info';
  static const stripMetadataBody = 'Strips EXIF metadata such as GPS.';
  static String outputFormat(String format) => 'Saves as $format';

  /// The start button, with the size estimate when there is one.
  static String convertButton(String? size) => size == null ? 'Convert' : 'Convert · about $size';
  static String compressButton(String? size) => size == null ? 'Compress' : 'Compress · about $size';

  /// Running job.
  static const converting = 'Converting';
  static const compressing = 'Compressing';
  static const waitingForSlot = 'Waiting for another conversion to finish…';
  static const cancelConvert = 'Cancel conversion';

  /// Step 3: result. {before} / {after} formatted sizes, {percent} 0–100.
  static const resultBody = 'Saved in your Library. The original is untouched.';
  static const before = 'Before';
  static const after = 'After';
  static String smaller(int percent) => '−$percent%';
  static String larger(int percent) => '+$percent%';
  static const done = 'Done';
  static const tryAgain = 'Try again';

  /// Short Save to Photos / Save to Files labels for the result's pinned
  /// button row on phones.
  static const savePhotosShort = 'Photos';
  static const saveFilesShort = 'Files';

  /// Failures.
  static const unreadable = "This file can't be read. Pick a video, audio or image file.";
  static const failed = 'The conversion failed. Try another format or setting.';
  static String imageFailed(String format) => "This image couldn't be saved as $format on this device.";
  static const cancelled = 'Conversion cancelled.';
}

abstract final class SettingsMessages {
  /// Settings screen header.
  static const title = 'Settings';
  static const subtitle = 'Defaults, cookies, storage and the download engine.';

  /// Appearance section.
  static const appearance = 'Appearance';
  static const theme = 'Theme';
  static const themeSystem = 'System';
  static const themeDark = 'Dark';
  static const themeLight = 'Light';

  /// Downloads section.
  static const downloads = 'Downloads';
  static const defaultVideoQuality = 'Default video quality';
  static const defaultAudioQuality = 'Default audio quality';
  static const best = 'Best';
  static String resolution(int value) => value == 2160 ? '4K' : '${value}p';
  static String kbps(int value) => '$value kbps';
  static const iphoneCompatible = 'iPhone-compatible video';
  static const iphoneCompatibleBody = 'H.264 / HEVC in MP4, so videos play in the iPhone Photos app';
  static const photosToJpg = 'Convert photos to JPG';
  static const photosToJpgBody = 'Off keeps the original WebP or HEIC';

  /// Library & storage section.
  static const libraryStorage = 'Library & storage';
  static const askRemove = 'Ask to remove after saving';
  static const askRemoveBody = 'After Save to Photos or Files, offer to delete the app’s copy';
  static const storageUsed = 'Storage used';
  static const storageVideos = 'Videos';
  static const storageAudio = 'Audio';
  static const storagePhotos = 'Photos';
  static const storageEmpty = '0 KB';
  static const clearSaved = 'Clear saved items';
  static String clearSavedBody(int count, String size) =>
      count == 0 ? 'Nothing saved to Photos or Files yet' : '$count saved to Photos or Files · $size';
  static String clearSavedTitle(int count) => count == 1 ? 'Delete 1 saved item?' : 'Delete $count saved items?';
  static const clearSavedConfirmBody =
      'They’re deleted from the app only. The copies in Photos or Files stay where you saved them.';
  static const clear = 'Clear';
  static String cleared(int count) => count == 1 ? 'Deleted 1 item' : 'Deleted $count items';

  /// Cookies section.
  static const cookies = 'Cookies';
  static const cookiesTile = 'Logged-in content';
  static String cookiesBody(int count) => count == 0
      ? 'Import cookies for private posts and Stories'
      : count == 1
      ? 'Cookies imported for 1 site'
      : 'Cookies imported for $count sites';

  /// Engine section.
  static const engine = 'Download engine';
  static const engineVersion = 'yt-dlp';
  static String engineBody(String? version) => version == null ? 'Starting…' : 'Version $version';
  static const engineUnavailable = 'Not available on this device yet';
  static const update = 'Update';
  static const updating = 'Updating…';
  static const checkOnLaunch = 'Check for updates on launch';
  static const checkOnLaunchBody = 'At most once a day. Updates only when you tap Update.';
  static String updateAvailable(String version) => 'Version $version is available. Update when a site stops working.';

  /// About section.
  static const about = 'About';
  static const aboutTile = 'About this app';
  static const aboutBody = 'Versions, licences, error log';
  static const rightsNotice = 'Your responsibility';
  static const rightsNoticeBody = 'What you can download';

  /// Developer section, debug builds only.
  static const developer = 'Developer';
  static const designGallery = 'Design gallery';
  static const designGalleryBody = 'Every base component, in both themes';

  /// Toast: a setting couldn't be saved.
  static const saveFailed = "Couldn't save the setting. Please try again.";
}

abstract final class CookiesMessages {
  /// Cookies screen header.
  static const title = 'Cookies';
  static const subtitle =
      'Some posts need you to be logged in. Import that site’s cookies so the app can download them as you.';

  /// Per-site rows.
  static const sites = 'Sites';
  static const notSet = 'No cookies';
  static String imported(int count, String date) => '${count == 1 ? '1 cookie' : '$count cookies'} · $date';
  static const import = 'Import';
  static const replace = 'Replace';
  static String removeTitle(String site) => 'Remove $site cookies?';
  static const removeBody = 'The app won’t be logged in to this site any more. Your browser stays logged in.';

  /// Toasts.
  static String importedToast(String site) => '$site cookies imported';
  static String removedToast(String site) => '$site cookies removed';

  /// Import failures.
  static const notCookiesFile = 'That isn’t a cookies.txt file. Export it in the Netscape format and try again.';
  static String noCookiesFor(String site) => 'That file has no $site cookies. Log in to $site, then export again.';

  /// macOS browser cookies.
  static const browser = 'Use cookies from a browser';
  static const browserBody = 'Used for sites without a cookies.txt. macOS may ask for permission.';
  static const browserNone = 'Off';
  static const browserSafari = 'Safari';
  static const browserChrome = 'Chrome';
  static const browserFirefox = 'Firefox';

  /// How-to section.
  static const howTo = 'How to get cookies.txt';
  static const step1 = 'On a computer, install a “Get cookies.txt” extension for your browser.';
  static const step2 = 'Log in to the site in that browser.';
  static const step3 = 'Open the site, click the extension and export cookies for the current site.';
  static const step4 = 'Copy the file to this device, then tap Import next to the site.';

  /// Privacy note.
  static const privacy =
      'Cookies stay on this device, in the app’s private folder. They are only sent to their own site and are never '
      'logged, uploaded or backed up. Remove them any time.';
}

abstract final class AboutMessages {
  /// About screen header.
  static const title = 'About';
  static const subtitle = 'Media Tool, for personal use.';

  /// Version rows.
  static const versions = 'Versions';
  static const appVersion = 'App';
  static const ytDlpVersion = 'yt-dlp';
  static const unknown = '—';

  /// Rows.
  static const more = 'More';
  static const licences = 'Open-source licences';
  static const licencesBody = 'The packages this app is built on';
  static const errorLog = 'Error log';
  static const errorLogBody = 'Copy it to paste into a bug report. It stays on this device.';
  static const copy = 'Copy';
  static String copied(int count) => count == 1 ? 'Copied 1 entry' : 'Copied $count entries';
  static const errorLogEmpty = 'The error log is empty.';
  static const appName = 'Media Tool';
}

/// System monitor: the live strip on the Download page and the System page.
abstract final class SystemMessages {
  /// System page header.
  static const title = 'System';
  static const subtitle = 'Live stats for this device, updated every second. They never leave it.';

  /// Metric names.
  static const memory = 'RAM';
  static const cpu = 'CPU';
  static const gpu = 'GPU';
  static const network = 'Network';
  static const storage = 'Storage';
  static const battery = 'Battery';

  /// What each metric covers (System page cards).
  static const memoryBody = 'Memory in use by all apps and the system';
  static const cpuBody = 'Load across all cores';
  static const gpuBody = 'Load of the busiest graphics chip';
  static const networkBody = 'All traffic on this device, every app';
  static const storageBody = 'Space on the drive that holds the app';
  static const batteryBody = 'Charge level and power';

  /// CPU / GPU cards on systems that keep the live load private (CPU on Android, GPU on iOS).
  static const cpuInfoBody = 'Chip and cores. This system keeps CPU load private.';
  static const gpuInfoBody = 'Graphics chip. This system keeps GPU load private.';

  /// Storage card rows.
  static const storageUsed = 'Used';
  static const storageFree = 'Free';
  static const storageTotal = 'Total';
  static const appFiles = 'Media Tool files';

  /// The app's files: size and share of the drive, e.g. "1.2 GB · 0.5%".
  static String appShare(String size, String percent) => '$size · $percent';

  /// A share too small to round to 1%.
  static const underOnePercent = '<1%';

  /// Battery card rows.
  static const batteryStatus = 'Status';
  static const batteryCharging = 'Charging';
  static const batteryFull = 'Fully charged';
  static const batteryDischarging = 'On battery';
  static const batteryNotCharging = 'Plugged in, not charging';
  static const batteryTemperature = 'Temperature';
  static const batteryHealth = 'Health';
  static const batteryTimeLeft = 'Time left';
  static const batteryTimeToFull = 'Until full';
  static const batteryCycles = 'Cycles';

  /// Battery capacity rows.
  static const batteryDesignCapacity = 'Design capacity';
  static const batteryFullCapacity = 'Full charge';
  static const batteryRemaining = 'Charge left';
  static String mah(String amount) => '$amount mAh';

  /// CPU card rows.
  static const cpuProcessor = 'Processor';
  static const cpuCores = 'Cores';
  static const cpuThreads = 'Threads';
  static const cpuLayout = 'Layout';
  static const cpuMaxClock = 'Max clock';
  static String ghz(String value) => '$value GHz';

  /// Core clusters, fastest first: "8 performance + 4 efficiency",
  /// "1 prime + 3 performance + 4 efficiency".
  static String coreLayout(List<int> clusters) => switch (clusters) {
    [final performance, final efficiency] => '$performance performance + $efficiency efficiency',
    [final prime, final performance, final efficiency] =>
      '$prime prime + $performance performance + $efficiency efficiency',
    _ => clusters.join(' + '),
  };

  /// GPU card rows.
  static const gpuName = 'Graphics';
  static const gpuCores = 'GPU cores';

  /// RAM card rows.
  static const memoryType = 'Type';
  static const memoryManufacturer = 'Manufacturer';
  static const memoryClock = 'Clock';
  static String mhz(int value) => '$value MHz';

  /// Storage card drive rows.
  static const storageDrive = 'Drive';
  static const storageType = 'Type';
  static const storageNvmeSsd = 'NVMe SSD';
  static const storageSsd = 'SSD';
  static const storageHardDrive = 'Hard drive';

  /// Drive type and how it's attached, e.g. "NVMe SSD · Apple Fabric".
  static String storageTypeWithInterface(String type, String interface) => '$type · $interface';

  /// Speed tests (RAM and Storage cards).
  static const speedRead = 'Read speed';
  static const speedWrite = 'Write speed';
  static const speedCopy = 'Copy speed';
  static const testSpeed = 'Test speed';
  static const testSpeedAgain = 'Test again';
  static const testingSpeed = 'Testing…';
  static const memoryTestNote = 'Fills, reads and copies a large block of memory. Takes a few seconds.';
  static const storageTestNote = 'Writes a temporary file, reads it back and deletes it. Takes a few seconds.';

  /// Health condition with capacity left, e.g. "Good · 92%".
  static String batteryHealthWithPercent(String condition, String percent) => '$condition · $percent';

  /// Battery health (Android).
  static const healthGood = 'Good';
  static const healthOverheat = 'Overheating';
  static const healthDead = 'Dead';
  static const healthOverVoltage = 'Over voltage';
  static const healthFailure = 'Failing';
  static const healthCold = 'Too cold';

  static String celsius(double value) => '${value.toStringAsFixed(1)} °C';

  /// Battery time remaining: "45 min", "2 h 5 min".
  static String hoursMinutes(int minutes) => minutes < 60 ? '$minutes min' : '${minutes ~/ 60} h ${minutes % 60} min';

  /// Network directions.
  static const download = 'Download';
  static const upload = 'Upload';

  /// Network speed when nothing is moving.
  static const idleSpeed = '0 KB/s';

  /// Shown for the first second, before there are two readings to compare.
  static const pending = '—';

  /// Sparkline caption.
  static const lastMinute = 'Last 60 seconds';

  /// Empty state when the device reports none of the stats.
  static const unavailableTitle = 'No stats on this device';
  static const unavailableBody = "This device doesn't share its memory, CPU or network use with apps.";

  static String percent(double value) => '${value.round()}%';
  static String memoryOf(String used, String total) => '$used of $total';
}

/// Sample content for the debug-only design gallery (Settings → Developer).
abstract final class DesignGalleryMessages {
  static const title = 'Design gallery';
  static const subtitle = 'Every base component. Switch the theme in Settings to see both.';
  static const buttons = 'Buttons';
  static const primary = 'Download';
  static const secondary = 'Save to Photos';
  static const tertiary = 'Select all';
  static const controls = 'Pickers and controls';
  static const video = 'Video';
  static const audio = 'Audio';
  static const photos = 'Photos';
  static const quality = 'Quality';
  static const progress = 'Progress';
  static const jobs = 'Job cards';
  static const finishJob = 'Finish the job';
  static const resetJob = 'Restart';
  static const sampleTitle = 'Sunset timelapse over the Himalayas, shot on a phone';
  static const sampleTitleShort = 'Street food tour';
  static const sampleStatus = '64% · 3.2 MB/s';
  static const sampleDetail = '1080p MP4 · 45 s left';
  static const sampleDone = '720p MP4 · 84 MB';
  static const sampleAudio = 'MP3 320 kbps · 9.4 MB';
  static const sampleDuration = '12:34';
  static const library = 'Library cards';
  static const photoGrid = 'Photo grid';
  static String selectedCount(int count) => 'Download $count photos';
  static const overlays = 'Sheets and dialogs';
  static const actionSheet = 'Action sheet';
  static const confirm = 'Confirm';
  static const savedPrompt = 'Saved prompt';
  static const deleteTitle = 'Delete this video?';
  static const deleteBody = 'It will be removed from the app. Copies saved to Photos or Files stay.';
  static const saveToFiles = 'Save to Files';
  static const states = 'States';
  static const sampleError = "The site didn't answer. Check your connection and try again.";

  /// Toasts section: one button per toast kind, plus long text, a stack and
  /// a repeat (skipped while the same toast is up).
  static const toasts = 'Toasts';
  static const toastsBody = 'Each button fires the real toast, the way a screen shows a message.';
  static const toastSuccess = 'Success';
  static const toastError = 'Error';
  static const toastWarning = 'Warning';
  static const toastInfo = 'Info';
  static const toastLong = 'Long text';
  static const toastStack = 'Stack of three';
  static const toastRepeat = 'Repeat';
  static const sampleSuccess = 'Saved to Photos.';
  static const sampleWarning = 'This site needs cookies to download. Import them in Settings.';
  static const sampleInfo = 'Engine is up to date.';
  static const sampleRepeat = 'Shown once, even when sent twice.';
  static const sampleLongToast =
      "Couldn't download this video. The site asked for a sign-in check, the cookies for it are out of date, "
      'and the engine could not find another way in. Import fresh cookies in Settings → Cookies, then try '
      'again. If it still fails, update the engine.';
}

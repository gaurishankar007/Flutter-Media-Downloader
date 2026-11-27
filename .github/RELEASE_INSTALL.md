## Download

**Android:** download `MediaTool-…-android.apk` (one file for every phone, tablet, emulator and Chromebook).
Open the file on your phone and allow "Install unknown apps" for your browser or Files app when asked.

**macOS:** download `MediaTool-…-macos.dmg`, open it and drag **Media Tool** into **Applications**.
The app isn't notarized by Apple, so the first launch is blocked. To open it:
1. Open the app once, and click **Done** when macOS warns you.
2. Go to **System Settings → Privacy & Security**, scroll down and click **Open Anyway** next to Media Tool.
(Or in Terminal: `xattr -dr com.apple.quarantine "/Applications/Media Tool.app"`.)

**Windows (64-bit):** download `MediaTool-…-windows-x64.zip`, extract it anywhere (for example your Documents folder) and run `Media Tool\media_tool.exe`.
The app isn't code-signed, so Windows may show "Windows protected your PC": click **More info → Run anyway**. Keep the extracted folder together (the app needs its `data` and `bin` folders).

**Linux (64-bit, GTK 3):** download `MediaTool-…-linux-x64.tar.gz`, then:
```
tar -xzf MediaTool-*-linux-x64.tar.gz
MediaTool/media_tool
```
Save to Files needs a file dialog (`xdg-desktop-portal`, `zenity` or `kdialog`). Videos can't be played inside the app on Linux.

iPhone isn't available as a download (Apple only allows installs from the App Store or a developer's Mac).

You're responsible for having the rights to anything you download.

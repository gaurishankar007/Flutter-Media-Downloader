# Downloads the Windows engine binaries into windows\engine\bin\ (not
# committed). Run once after cloning, and again to refresh them. The build
# copies them into bin\ next to media_tool.exe. See docs/engine/desktop_engine.md.
#
#   powershell -ExecutionPolicy Bypass -File windows\scripts\fetch_engine.ps1             # x64
#   powershell -ExecutionPolicy Bypass -File windows\scripts\fetch_engine.ps1 -WithDeno   # also bundle deno
param([switch]$WithDeno)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue' # Invoke-WebRequest is very slow with the progress bar.

$Bin = Join-Path $PSScriptRoot '..\engine\bin'
New-Item -ItemType Directory -Force -Path $Bin | Out-Null
$Bin = (Resolve-Path $Bin).Path
$Tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("media-tool-engine-" + [guid]::NewGuid())
New-Item -ItemType Directory -Path $Tmp | Out-Null

try {
  # yt-dlp: official standalone build, checked against SHA2-256SUMS.
  $YtDlpBase = 'https://github.com/yt-dlp/yt-dlp/releases/latest/download'
  Write-Host 'Downloading yt-dlp.exe...'
  Invoke-WebRequest -Uri "$YtDlpBase/yt-dlp.exe" -OutFile "$Tmp\yt-dlp.exe"
  Invoke-WebRequest -Uri "$YtDlpBase/SHA2-256SUMS" -OutFile "$Tmp\SHA2-256SUMS"
  $expected = (Get-Content "$Tmp\SHA2-256SUMS" | Where-Object { ($_ -split '\s+')[1] -eq 'yt-dlp.exe' } | ForEach-Object { ($_ -split '\s+')[0] })
  $actual = (Get-FileHash "$Tmp\yt-dlp.exe" -Algorithm SHA256).Hash.ToLower()
  if (-not $expected -or $expected.ToLower() -ne $actual) {
    throw 'yt-dlp.exe checksum mismatch'
  }
  Move-Item -Force "$Tmp\yt-dlp.exe" "$Bin\yt-dlp.exe"

  # ffmpeg / ffprobe: static GPL builds from BtbN/FFmpeg-Builds (libx264, x265,
  # libmp3lame, libwebp, NVENC / QSV / AMF encoders).
  Write-Host 'Downloading ffmpeg...'
  $FfmpegDir = 'ffmpeg-master-latest-win64-gpl'
  Invoke-WebRequest -Uri "https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/$FfmpegDir.zip" -OutFile "$Tmp\ffmpeg.zip"
  Expand-Archive -Path "$Tmp\ffmpeg.zip" -DestinationPath $Tmp -Force
  foreach ($tool in 'ffmpeg.exe', 'ffprobe.exe') {
    Move-Item -Force "$Tmp\$FfmpegDir\bin\$tool" "$Bin\$tool"
  }

  if ($WithDeno) {
    Write-Host 'Downloading deno...'
    Invoke-WebRequest -Uri 'https://github.com/denoland/deno/releases/latest/download/deno-x86_64-pc-windows-msvc.zip' -OutFile "$Tmp\deno.zip"
    Expand-Archive -Path "$Tmp\deno.zip" -DestinationPath $Tmp -Force
    Move-Item -Force "$Tmp\deno.exe" "$Bin\deno.exe"
  }

  # Files from the internet carry a "blocked" mark; clear it so they run without prompts.
  Get-ChildItem $Bin -File | Unblock-File

  Write-Host ''
  Write-Host ("yt-dlp  " + (& "$Bin\yt-dlp.exe" --version))
  & "$Bin\ffmpeg.exe" -hide_banner -version | Select-Object -First 1
  Write-Host "Done: $Bin"
}
finally {
  Remove-Item -Recurse -Force $Tmp -ErrorAction SilentlyContinue
}

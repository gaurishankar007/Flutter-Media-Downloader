---
name: release
description: Publish a new Media Tool version to GitHub Releases (Android APKs + macOS DMG). Checks the local toolchain against the release workflow and updates it first, validates the build, bumps the version, drafts release notes for approval, then tags and watches the CI run. Use when the user asks to release, publish, ship a new version, or cut vX.Y.Z.
---

# Release workflow

Releases are built by `.github/workflows/release.yml`. It runs **only** when a tag `v*` is pushed (or the *Release* workflow is started by hand), never on ordinary pushes. This skill prepares everything, then pushes that tag.

Run the steps in order. **Stop and report** on any failure: don't retry blindly, skip a step or fall back to another route.

## 1. Preconditions
- `git status` is clean, the branch is `main`, and `git fetch && git status` shows it's in sync with `origin/main`. If not, tell the user and stop.
- `gh auth status` is logged in.
- The latest release tag: `git describe --tags --abbrev=0` (none yet means this is the first release).

## 2. Toolchain parity: update the workflow first
CI must build with the same toolchain that validated the build locally. Compare each item and **update `.github/workflows/release.yml` (and anything listed below) before moving on**:

| Check | Local source | Workflow / project field |
|---|---|---|
| Flutter version | `flutter --version` (version + channel) | `env.FLUTTER_VERSION` |
| Java (JDK) major | `flutter doctor -v` → "Java binary at", then `<that java> -version` | `env.JAVA_VERSION` |
| Dart SDK constraint | `dart --version` | `environment.sdk` in `pubspec.yaml` must allow it (if not, tell the user and stop: that's an SDK upgrade, not a release step) |
| Android compileSdk | `android/app/build.gradle.kts` | the GitHub Ubuntu image must have it, or a step must install it (the Android Gradle plugin downloads missing platforms; leave it unless a CI run failed on it) |
| GitHub Actions | `actions/checkout`, `actions/setup-java`, `actions/upload-artifact`, `actions/download-artifact`, `subosito/flutter-action`, `softprops/action-gh-release` | for each, `gh api repos/<owner>/<repo>/releases/latest -q .tag_name`. Bump the major tag (e.g. `@v4` → `@v5`) only when a new major exists, and read its release notes for breaking input changes first |
| Runner images | `ubuntu-latest`, `macos-latest` | keep them unless a run failed because of them |
| Engine fetch scripts | `macos/scripts/fetch_engine_binaries.sh` flags used in the workflow | still valid (`--universal --with-deno`) |

Show the user a short table of what changed (or "no changes").

## 3. Validate locally
- `flutter pub get`, `dart run build_runner build`, `flutter analyze`. It must be clean.
- `flutter build apk --release --split-per-abi`. It must succeed, and `apksigner verify --print-certs` on the arm64 APK must show `CN=GSS` (the release key, from `android/key.properties`). If `key.properties` is missing, stop: CI would still sign, but local parity is broken.
- `flutter build macos --release`. It must succeed.
- There are no automated tests in this project (see CLAUDE.md), so don't run `flutter test`.

## 4. Choose the version
- Read `version:` in `pubspec.yaml` (`X.Y.Z+N`).
- Propose the next version from the commits since the last tag (`git log <lastTag>..HEAD --oneline`): **patch** for fixes only, **minor** for new features, **major** for big or breaking changes. Ask the user to confirm or change it.
- Set `pubspec.yaml` to `X.Y.Z+N+1`. CI overrides the build number with the run number, but keep pubspec increasing so local builds match.
- The tag must not already exist (`git tag -l vX.Y.Z`, `gh release view vX.Y.Z`).

## 5. Release notes (needs user approval)
- Draft short bullets from `git log <lastTag>..HEAD`. **Only include user-visible changes**: new features, fixes and behaviour a user can notice. Leave out refactors, dependency bumps, CI or tooling, docs, lint and DI changes.
- Show the draft and ask the user to approve or edit it. **Don't write files or push anything until they approve.**
- Write the approved bullets to `.github/RELEASE_NOTES.md`, replacing its contents (it holds this release's notes only). The workflow adds `.github/RELEASE_INSTALL.md` (install steps) and GitHub's auto-generated changelog.

## 6. Commit, tag, push
```bash
git add pubspec.yaml .github/RELEASE_NOTES.md .github/workflows/release.yml   # plus any file step 2 changed
git commit -m "chore: release vX.Y.Z"
git push origin main
git tag vX.Y.Z
git push origin vX.Y.Z          # this triggers the Release workflow
```
No AI-attribution trailer in the commit (CLAUDE.md).

## 7. Watch the run
- Find it with `gh run list --workflow release.yml --limit 1`, then follow it with `gh run watch <id> --exit-status`. Use the Monitor tool and post a short line to the user whenever a job changes state (android, macos, release).
- On failure, run `gh run view <id> --log-failed | tail -80`, report the failing step and the cause, and **stop**. Propose a fix. Once it's fixed and pushed, re-run by deleting and re-pushing the tag (`git push --delete origin vX.Y.Z && git tag -d vX.Y.Z`, then tag again) **only with the user's OK**, because it rewrites a public tag.

## 8. Verify and report
- `gh release view vX.Y.Z --json assets -q '.assets[].name'` should list 3 APKs and 1 DMG.
- Give the user the release URL, the asset list, and anything step 2 changed in the workflow.

## Secrets and keys (never print them)
- Repo secrets: `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`.
- Keystore: `~/Keystores/media_downloader/release.jks` (+ `key.properties`), outside the repo. Never commit them, and never change the app ID `com.gss.mediatool`.

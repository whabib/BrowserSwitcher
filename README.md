# BrowserSwitcher

A tiny macOS menu bar app for switching your default web browser without opening System Settings.

Click the globe icon in the menu bar to see every browser installed on your Mac, each with its icon and short name. The current default has a checkmark. Pick another one to make it the default for `http` and `https`. A **Start at Login** toggle adds or removes the app from your Login Items for you.

## Requirements

- macOS 13 (Ventura) or later
- Xcode command line tools (provides `swiftc`):

  ```bash
  xcode-select --install
  ```

No full Xcode install or third-party dependencies needed.

## Build

```bash
git clone https://github.com/whabib/BrowserSwitcher.git
cd BrowserSwitcher
./build.sh
```

This compiles `main.swift` and produces `BrowserSwitcher.app` in the current directory.

## Run

```bash
open BrowserSwitcher.app
```

The app lives only in the menu bar (no Dock icon). Use **Quit** in its menu to exit.

For best results, drag `BrowserSwitcher.app` to `/Applications` before enabling **Start at Login**, since the login item points at the app's current location.

## Start at Login

The menu has a **Start at Login** toggle just above **Quit**. Turn it on and the app adds itself to System Settings → General → Login Items, so it launches automatically when you log in. Turn it off to remove it. The checkmark always reflects the current state, even if you change it manually in System Settings.

- Move `BrowserSwitcher.app` to `/Applications` first. The login item points to the app's location when you enable it, so moving the app later breaks it (toggle off and on again to fix).
- If macOS asks for approval, the app opens the Login Items settings pane; enable BrowserSwitcher there.
- If registration fails, an alert shows the error.

## Notes

- macOS shows its own "Change default browser?" confirmation when you switch. This is a system security prompt and can't be bypassed. You may see it once for `http` and once for `https`.
- The list contains apps registered to open both `http` and `https` URLs. An occasional non-browser app may appear if it registers for both.
- The app is unsigned. If Gatekeeper blocks the first launch, right-click the app and choose **Open**, or run `xattr -dr com.apple.quarantine BrowserSwitcher.app`. Apps you build locally normally aren't quarantined.

## How it works

Everything is in `main.swift`: an `NSStatusItem` with an `NSMenu` that is rebuilt each time it opens. It uses `NSWorkspace.urlsForApplications(toOpen:)` to list browsers, `urlForApplication(toOpen:)` to find the current default, and `setDefaultApplication(at:toOpenURLsWithScheme:)` to change it.

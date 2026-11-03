#!/bin/bash
# Run on a Mac with Xcode command line tools installed (xcode-select --install).
set -e
APP="BrowserSwitcher.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
swiftc -O -o "$APP/Contents/MacOS/BrowserSwitcher" main.swift
cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>CFBundleName</key><string>BrowserSwitcher</string>
  <key>CFBundleIdentifier</key><string>local.browserswitcher</string>
  <key>CFBundleExecutable</key><string>BrowserSwitcher</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>LSMinimumSystemVersion</key><string>13.0</string>
  <key>LSUIElement</key><true/>
</dict></plist>
PLIST
codesign --force --sign - "$APP"
echo "Built $APP — run with: open $APP"

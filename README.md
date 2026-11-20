# BatteryWatch

A small menu bar app for macOS 14+ that shows the battery level of every connected Bluetooth accessory that reports one (Magic Keyboard, Magic Mouse, trackpad and others). It sends a notification when a device drops below your threshold, which defaults to 50%.

- Battery levels come from the IORegistry (the same data as `ioreg -r -k BatteryPercent`). Device names come from IOBluetooth.
- The app checks every 5 minutes, after the Mac wakes from sleep, and whenever you open the menu.
- You get one warning per device each time it drops below the threshold. The warning comes back after the device has charged above the threshold again.

## Build

```bash
xcodegen generate
xcodebuild -project BatteryWatch.xcodeproj -scheme BatteryWatch -configuration Release -derivedDataPath build build
open build/Build/Products/Release/BatteryWatch.app
```

The build uses ad-hoc signing (`CODE_SIGN_IDENTITY = "-"`), so it runs on this Mac only. Move it to `/Applications` before you turn on **Launch at login**.

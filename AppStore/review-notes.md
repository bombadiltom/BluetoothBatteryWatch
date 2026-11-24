# App Review notes

Paste the text between the rules into the "Notes" field under App Review Information in App Store Connect. Leave "Sign-in required" unticked.

---

BluetoothBatteryWatch is a menu bar app. It has no window and no Dock icon. After launch, look for the battery icon in the menu bar at the top right of the screen, and click it to open the app.

It needs no account, login or demo credentials.

To see it working:

1. Connect a Bluetooth accessory that reports its battery level to macOS, for example a Magic Keyboard, Magic Mouse or Magic Trackpad. The menu lists each one with its name, its level and a level bar. With no such accessory connected, the menu says "No connected device is reporting a battery level."; that's expected and not an error.
2. Allow notifications when asked at the first launch.
3. To trigger a low-battery warning without waiting for a battery to run down, drag the "Warn below" slider above the accessory's current level. A notification appears right away, and the accessory's row turns red. The percentage also appears next to the menu bar icon.
4. Lower the slider below the level again. That re-arms the warning, so moving the slider back up shows it again.

"Launch at login" only registers the app as a login item when the user ticks it. It's off by default.

The app reads battery levels locally from macOS (IOKit) and looks up accessory names through IOBluetooth. That's why it has the Bluetooth entitlement and usage description. It makes no network connections.

---

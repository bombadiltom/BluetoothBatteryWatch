# App Store Connect: "App Privacy" answers

These answers for App Store Connect's App Privacy questionnaire (the "nutrition label") come from the app's actual code, not from assumptions. Apple's wording changes, so check them against the live questionnaire.

They have to agree with `BluetoothBatteryWatch/PrivacyInfo.xcprivacy`, the privacy manifest bundled in the app. It declares no tracking, no collected data types, and `UserDefaults` as the only required-reason API. That was checked by searching the source for every other required-reason API category.

## Does the app "collect" data, by Apple's definition?

Apple counts data as collected when it's **sent off the device in a way the developer, or a third party the developer works with, can access.** Here's every flow in the app:

| Flow | Leaves the Mac? | Can the developer access it? |
|---|---|---|
| Battery levels (IORegistry) | No. They're read locally and only shown in the menu and notifications. | No |
| Accessory names (IOBluetooth) | No. It's a local lookup of devices that are already paired. | No |
| Threshold and warned devices (`UserDefaults`) | No. They stay in the app's own container. | No |
| Notifications | No. They're local notifications, with no push. | No |
| Launch at login (`SMAppService`) | No | No |

The sandboxed build doesn't have the `com.apple.security.network.client` entitlement, so the app *can't* open a network connection.

The answer to the top-level question is **"Data Not Collected"**, for the whole app.

## Tracking

**No.** The app contains no advertising and doesn't combine user data with other companies' data. It never calls `ATTrackingManager`, so App Tracking Transparency doesn't apply.

## Third-party SDKs

There are none. The app uses only Apple frameworks: SwiftUI, AppKit, IOKit, IOBluetooth, UserNotifications and ServiceManagement.

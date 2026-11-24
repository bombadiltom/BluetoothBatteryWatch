# BluetoothBatteryWatch

A small menu bar app for macOS 14+ that shows the battery level of every connected Bluetooth accessory that reports one (Magic Keyboard, Magic Mouse, trackpad and others). It sends a notification when a device drops below your threshold, which defaults to 50%.

- Battery levels come from the IORegistry (the same data as `ioreg -r -k BatteryPercent`). Device names come from IOBluetooth.
- The app checks every 5 minutes, after the Mac wakes from sleep, and whenever you open the menu.
- You get one warning per device each time it drops below the threshold. The warning comes back after the device has charged above the threshold again.

## Build

```bash
xcodegen generate
xcodebuild -project BluetoothBatteryWatch.xcodeproj -scheme BluetoothBatteryWatch -configuration Release -derivedDataPath build build
open build/Build/Products/Release/BluetoothBatteryWatch.app
```

The build uses ad-hoc signing (`CODE_SIGN_IDENTITY = "-"`), so it runs on this Mac only. Move it to `/Applications` before you turn on **Launch at login**.

## Install with Homebrew

```bash
brew tap bombadiltom/tap
brew trust --cask bombadiltom/tap/bluetoothbatterywatch
brew install --cask bombadiltom/tap/bluetoothbatterywatch
```

Homebrew 7 only loads casks from third-party taps once you trust them, which is what the `brew trust` line does. The app is signed with a Developer ID and notarized by Apple, so it opens without Gatekeeper warnings.

## Releasing

Commit and push your changes, then run:

```bash
scripts/release.sh 1.1
```

This tags the current commit as `v1.1` and pushes the tag. The [Release action](.github/workflows/release.yml) then does the rest:

1. It builds the app and signs it with the Developer ID certificate.
2. It sends the app to Apple for notarization and staples the ticket.
3. It publishes a GitHub release with the zip.
4. It updates the cask in [bombadiltom/homebrew-tap](https://github.com/bombadiltom/homebrew-tap).

After that, `brew upgrade --cask bluetoothbatterywatch` installs the new version.

Other options:

- **Check signing without releasing.** Run the Release action manually from the Actions tab and enter a version. It only builds and notarizes, and it attaches the zip to the workflow run.
- **Build locally without publishing:** `scripts/release.sh 1.1 --build-only`.
- **Publish locally if the action is unavailable.** Check out the tag, then run `scripts/release.sh 1.1 --publish-existing-tag`.

### One-time setup

**For the GitHub Action:**

1. **Export the certificate.** In Keychain Access, open login → My Certificates, right-click **Developer ID Application: Tom Lorenz (K6QN2C7Q55)** and choose **Export…**. Save it as a `.p12` with a password.
2. **Set the secrets.** Run `scripts/setup-ci-secrets.sh` yourself. It asks for the `.p12`, its password, your Apple ID and an app-specific password, and stores them as encrypted repository secrets. It also creates a write deploy key on the tap repo, so the action can update the cask.

**For local builds** (`--build-only` and `--publish-existing-tag`):

1. **Developer ID Application certificate.** Create it at [developer.apple.com → Certificates](https://developer.apple.com/account/resources/certificates/list), or in Xcode under Settings → Accounts → Manage Certificates. Install it in the **login** keychain.
2. **App-specific password.** Create one at [account.apple.com](https://account.apple.com) under Sign-In and Security → App-Specific Passwords.
3. **Store the notarization credentials in the keychain.** Run the command below. It asks for the app-specific password.
   ```bash
   xcrun notarytool store-credentials BombadilTom --apple-id <apple-id> --team-id K6QN2C7Q55
   ```
4. **GitHub CLI.** Log in as `bombadiltom` with `gh auth login`. It doesn't have to be the active account.

## Mac App Store

The App Store version is built separately from the Homebrew version. It's sandboxed (see [`AppStore.entitlements`](BluetoothBatteryWatch/AppStore.entitlements)), signed automatically through your Apple account and uploaded as a `.pkg`. The Homebrew version stays unsandboxed.

```bash
scripts/release.sh 1.2 --app-store-build-only   # signed .pkg in dist/, nothing uploaded
scripts/release.sh 1.2 --app-store              # same, then uploads to App Store Connect
```

After the upload, pick the build on the app's version page in App Store Connect and submit it for review. Each upload needs a new build number. The build number is the commit count, so commit something before uploading the same version again.

A sandboxed app keeps its settings in its own container, so switching from the Homebrew version to the App Store version resets the threshold to 50%.

### One-time setup

Signing is automatic. Xcode registers the App ID `de.idiotentruppe.batterywatch`, manages the App Store provisioning profile, and signs with Apple's cloud-managed distribution certificates, so there's no certificate or profile to create by hand. The upload goes through the same account.

1. **Xcode account.** In Xcode → Settings → Accounts, sign in to an Apple account that's a member of team `K6QN2C7Q55`. The script uses it through `-allowProvisioningUpdates`.
2. **App record.** In [App Store Connect](https://appstoreconnect.apple.com) → Apps, create a new macOS app with the bundle ID `de.idiotentruppe.batterywatch`. Fill it in from [`AppStore/`](AppStore/README.md): listing copy, App Privacy answers, review notes and screenshots. Apple can't create the record from a build, so this one stays manual.

Without an Xcode account, for example in CI, set `ASC_KEY_ID`, `ASC_ISSUER_ID` and, if the `.p8` isn't in `~/.appstoreconnect/private_keys/`, `ASC_KEY_PATH` to an App Store Connect API key. Cloud signing needs the key's **Admin** role.

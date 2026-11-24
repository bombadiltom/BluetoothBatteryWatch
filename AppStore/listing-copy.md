# App Store listing copy

Copy for the App Store Connect listing. A script checked every character count below against Apple's limits. Check them again if you edit.

The listing is Mac only: one App Store Connect record for `de.idiotentruppe.batterywatch`, macOS platform.

## App name (max 30)

    BluetoothBatteryWatch

(21 characters)

## Subtitle (max 30)

    Low-battery alerts in menu bar

(30 characters)

## Promotional text (max 170, editable without a new review)

    See every Bluetooth keyboard, mouse and trackpad battery at a glance, and get a notification before one runs out, not when it already has.

(138 characters)

## Description (max 4000)

    BluetoothBatteryWatch sits in your menu bar and keeps an eye on the batteries of your Bluetooth accessories, so your keyboard or mouse never dies in the middle of your work.

    AT A GLANCE
    The menu bar icon shows the battery of whichever accessory is lowest. Click it to see every connected keyboard, mouse, trackpad and other accessory that reports a battery level, each with its name and a level bar.

    WARNED IN TIME
    Pick your own warning level, from 5% to 95% (50% by default). When an accessory drops below it, you get a notification, its level appears next to the menu bar icon, and it turns red in the menu. You're warned once per device. The warning comes back after the device has been charged above your level again.

    QUIETLY UP TO DATE
    The app checks every 5 minutes, right after your Mac wakes from sleep, and whenever you open the menu. It uses almost no resources and has no window, no Dock icon and nothing to set up.

    STARTS WITH YOUR MAC
    Tick Launch at login and it's there every time you sign in.

    PRIVATE BY DESIGN
    No accounts, no analytics, no tracking, no ads, and no network access at all. Battery levels are read from macOS on your Mac and never leave it.

    Works with any Bluetooth accessory that reports its battery level to macOS, including Apple's keyboards, mice and trackpads.

(1,301 characters)

## Keywords (max 100, comma-separated, no spaces after commas)

    battery,bluetooth,keyboard,mouse,trackpad,menu bar,low battery,alert,charge,accessory,level,monitor

(99 characters)

Deliberately left out:

- **"Magic Keyboard", "Magic Mouse", "AirPods".** Guideline 2.3.7 rejects keywords that are other companies' trademarks, and Apple's own product names count.
- **"widget".** The app has no widget, and a keyword that promises one invites a rejection.
- **German terms.** Keywords are indexed per localization, and 1.0 is English only. For a German localization, use for example `batterie,akku,bluetooth,tastatur,maus,trackpad,menüleiste,warnung,laden,zubehör,ladestand`.

## What's New in This Version (max 4000)

It isn't shown for a first release. From the second App Store version on, fill it in with each submission.

## Support URL *(required)*

    https://www.idiotentruppe.de/apps/bluetoothbatterywatch/

## Privacy Policy URL *(required)*

    https://www.idiotentruppe.de/apps/bluetoothbatterywatch/privacy/

It's hosted on idiotentruppe.de, from `src/content/privacy/bluetoothbatterywatch.md` in the website repo. Update the page there whenever the policy changes.

## Marketing URL *(optional)*

    [leave blank]

## Copyright

    2026 Tom Lorenz

## Primary category

    Utilities

This matches `LSApplicationCategoryType` in `project.yml`.

## Secondary category (optional)

    Productivity

## Price

Free is the expected choice, the same as the Homebrew version. It's set under Pricing and Availability.

## Age rating

Run App Store Connect's questionnaire yourself; it's the source of truth. The expected result is **4+**: no user-generated content, no web access, nothing mature. Answer **No** to "Unrestricted Web Access".

## Accuracy notes: read before submitting

App Review checks that the listing matches what the app does on the reviewer's Mac. Some wording here is deliberate:

- **"each with its name and a level bar"** is true: names come from IOBluetooth and the bars are ProgressViews. The sandboxed build was tested in Nov 2026 and shows both.
- **"from 5% to 95%"** matches the slider's range in `MenuContentView`.
- **"its level appears next to the menu bar icon, and it turns red in the menu"**: the menu bar label is a template image and text, so it isn't coloured. Only the row in the menu is red. Don't promise a red menu bar.
- **"no network access at all"** is true: the sandbox build has no `network.client` entitlement, so it couldn't connect even if it tried.
- **"Works with any Bluetooth accessory that reports its battery level to macOS"** is deliberately not "any Bluetooth accessory". Many third-party devices don't report a level, and a reviewer with one would otherwise file a bug.

If you change what the app does, update this file in the same change.

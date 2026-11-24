import AppKit
import SwiftUI

// Renders the Mac App Store screenshots (2880×1800) into AppStore/screenshots/.
// Run scripts/make-screenshots.sh; it compiles this together with the app's real views.

let root = URL(fileURLWithPath: CommandLine.arguments[1])
let outDir = root.appendingPathComponent("AppStore/screenshots")
let iconURL = root.appendingPathComponent("BluetoothBatteryWatch/Assets.xcassets/AppIcon.appiconset/icon_128x128@2x.png")

let canvas = CGSize(width: 1440, height: 900) // points; rendered at 2x
let menuBarHeight: CGFloat = 30

struct Notice {
    let title: String
    let body: String
}

struct Scene {
    let file: String
    let dark: Bool
    let headline: String
    let subline: String
    let devices: [BatteryDevice]
    let threshold: Int
    var notice: Notice?
}

func device(_ name: String, _ category: String, _ percent: Int, _ id: String) -> BatteryDevice {
    BatteryDevice(id: id, name: name, category: category, percent: percent)
}

let keyboard = "aa-bb-cc-00-00-01", mouse = "aa-bb-cc-00-00-02", trackpad = "aa-bb-cc-00-00-03"

let scenes: [Scene] = [
    Scene(
        file: "mac-1-overview.png", dark: false,
        headline: "Every Bluetooth battery,\none click away",
        subline: "Keyboard, mouse, trackpad and more,\nright in your menu bar.",
        devices: [
            device("Magic Keyboard", "Keyboard", 82, keyboard),
            device("Magic Mouse", "Mouse", 64, mouse),
            device("Magic Trackpad", "Trackpad", 91, trackpad),
        ],
        threshold: 50
    ),
    Scene(
        file: "mac-2-low-battery.png", dark: false,
        headline: "Warned before\nit runs out",
        subline: "One notification per device when it drops\nbelow your level. Not one more.",
        devices: [
            device("Magic Keyboard", "Keyboard", 76, keyboard),
            device("Magic Mouse", "Mouse", 18, mouse),
            device("Magic Trackpad", "Trackpad", 88, trackpad),
        ],
        threshold: 50,
        notice: Notice(
            title: "Magic Mouse at 18%",
            body: "Time to charge it — it's below your 50% warning level."
        )
    ),
    Scene(
        file: "mac-3-your-level.png", dark: true,
        headline: "Your warning level,\nyour call",
        subline: "Anywhere from 5% to 95%. Launch at login,\nand it simply stays out of your way.",
        devices: [
            device("Magic Keyboard", "Keyboard", 41, keyboard),
            device("Magic Mouse", "Mouse", 57, mouse),
        ],
        threshold: 30
    ),
]

// MARK: - Pieces

struct Wallpaper: View {
    let dark: Bool
    var body: some View {
        let colors: [Color] = dark
            ? [Color(red: 0.07, green: 0.09, blue: 0.20), Color(red: 0.20, green: 0.12, blue: 0.35), Color(red: 0.05, green: 0.25, blue: 0.35)]
            : [Color(red: 0.36, green: 0.55, blue: 0.95), Color(red: 0.55, green: 0.42, blue: 0.90), Color(red: 0.25, green: 0.75, blue: 0.80)]
        ZStack {
            LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
            RadialGradient(colors: [.white.opacity(dark ? 0.08 : 0.25), .clear], center: .init(x: 0.25, y: 0.75), startRadius: 0, endRadius: 700)
        }
    }
}

struct MenuBar: View {
    let dark: Bool
    let monitor: BatteryMonitor

    var body: some View {
        let fg: Color = dark ? .white : .black
        HStack(spacing: 22) {
            Text("Finder").fontWeight(.bold)
            ForEach(["File", "Edit", "View", "Go", "Window", "Help"], id: \.self) { Text($0) }
            Spacer()
            HStack(spacing: 5) { label }
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(RoundedRectangle(cornerRadius: 5).fill(fg.opacity(0.18)))
            Image(systemName: "wifi")
            Image(systemName: "magnifyingglass")
            Image(systemName: "switch.2")
            Text("Tue 24 Nov  9:41")
        }
        .font(.system(size: 14))
        .foregroundStyle(fg)
        .padding(.horizontal, 18)
        .frame(height: menuBarHeight)
        .background((dark ? Color.black : Color.white).opacity(dark ? 0.35 : 0.55))
    }

    /// Same logic as MenuBarLabel in the app.
    @ViewBuilder private var label: some View {
        if let lowest = monitor.lowestDevice {
            Image(systemName: BatterySymbol.name(for: lowest.percent))
            if monitor.isLow(lowest) { Text("\(lowest.percent)%").monospacedDigit() }
        }
    }
}

struct MenuPanel: View {
    let monitor: BatteryMonitor
    var body: some View {
        MenuContentView(monitor: monitor)
            .background(Color(nsColor: .windowBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.primary.opacity(0.12)))
            .shadow(color: .black.opacity(0.35), radius: 24, y: 12)
    }
}

struct Banner: View {
    let notice: Notice
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if let icon = NSImage(contentsOf: iconURL) {
                Image(nsImage: icon).resizable().frame(width: 38, height: 38)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(notice.title).font(.system(size: 13, weight: .semibold))
                Text(notice.body).font(.system(size: 13)).fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
            Text("now").font(.system(size: 11)).foregroundStyle(.secondary)
        }
        .padding(14)
        .frame(width: 360)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(nsColor: .windowBackgroundColor).opacity(0.97)))
        .shadow(color: .black.opacity(0.25), radius: 18, y: 8)
    }
}

struct ScreenshotView: View {
    let scene: Scene
    let monitor: BatteryMonitor

    var body: some View {
        ZStack(alignment: .topLeading) {
            Wallpaper(dark: scene.dark)
            VStack(spacing: 0) {
                MenuBar(dark: scene.dark, monitor: monitor)
                Spacer()
            }
            VStack(alignment: .leading, spacing: 22) {
                Text(scene.headline)
                    .font(.system(size: 58, weight: .bold))
                    .lineSpacing(4)
                Text(scene.subline)
                    .font(.system(size: 28, weight: .medium))
                    .opacity(0.9)
                    .lineSpacing(4)
            }
            .foregroundStyle(.white)
            .shadow(color: .black.opacity(0.2), radius: 8, y: 2)
            .padding(.leading, 90)
            .padding(.top, 300)

            // The menu hangs below the app's item, near the right end of the menu bar.
            MenuPanel(monitor: monitor)
                .scaleEffect(1.35, anchor: .topTrailing)
                .padding(.top, menuBarHeight + 8)
                .padding(.trailing, 230)
                .frame(maxWidth: .infinity, alignment: .topTrailing)

            if let notice = scene.notice {
                Banner(notice: notice)
                    .scaleEffect(1.25, anchor: .bottomLeading)
                    .padding(.leading, 90)
                    .padding(.top, 650)
            }
        }
        .frame(width: canvas.width, height: canvas.height)
        .environment(\.colorScheme, scene.dark ? .dark : .light)
        // The offscreen window is never key, which would draw the controls greyed out.
        .environment(\.controlActiveState, .key)
    }
}

// MARK: - Render


@MainActor
func render(_ scene: Scene) throws {
    NSApp.appearance = NSAppearance(named: scene.dark ? .darkAqua : .aqua)
    let monitor = BatteryMonitor(devices: scene.devices, threshold: scene.threshold)
    let view = NSHostingView(rootView: ScreenshotView(scene: scene, monitor: monitor))
    view.frame = CGRect(origin: .zero, size: canvas)
    let window = NSWindow(contentRect: view.frame, styleMask: .borderless, backing: .buffered, defer: false)
    window.appearance = NSApp.appearance
    window.contentView = view
    window.setFrameOrigin(CGPoint(x: -20000, y: -20000))
    window.orderFrontRegardless()
    view.layoutSubtreeIfNeeded()
    RunLoop.current.run(until: Date().addingTimeInterval(0.8))

    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: Int(canvas.width * 2), pixelsHigh: Int(canvas.height * 2),
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
    )!
    rep.size = canvas
    view.cacheDisplay(in: view.bounds, to: rep)
    window.orderOut(nil)

    // App Store Connect rejects screenshots with an alpha channel: flatten onto opaque RGB.
    let flat = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: rep.pixelsWide, pixelsHigh: rep.pixelsHigh,
        bitsPerSample: 8, samplesPerPixel: 3, hasAlpha: false, isPlanar: false,
        colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 32
    )!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: flat)
    NSColor.black.setFill()
    CGRect(x: 0, y: 0, width: rep.pixelsWide, height: rep.pixelsHigh).fill()
    rep.draw(in: CGRect(x: 0, y: 0, width: rep.pixelsWide, height: rep.pixelsHigh))
    NSGraphicsContext.restoreGraphicsState()

    let url = outDir.appendingPathComponent(scene.file)
    try flat.representation(using: .png, properties: [:])!.write(to: url)
    print("wrote \(url.path)")
}

let app = NSApplication.shared
app.setActivationPolicy(.prohibited)
try FileManager.default.createDirectory(at: outDir, withIntermediateDirectories: true)
MainActor.assumeIsolated {
    for scene in scenes {
        do { try render(scene) } catch { print("error: \(scene.file): \(error)"); exit(1) }
    }
}

import SwiftUI

@main
struct BluetoothBatteryWatchApp: App {
    @State private var monitor = BatteryMonitor()

    var body: some Scene {
        MenuBarExtra {
            MenuContentView(monitor: monitor)
        } label: {
            MenuBarLabel(monitor: monitor)
        }
        .menuBarExtraStyle(.window)
    }
}

/// Menu bar icon: a battery glyph for the lowest device, plus its percentage once it's below the threshold.
struct MenuBarLabel: View {
    let monitor: BatteryMonitor

    var body: some View {
        if let lowest = monitor.lowestDevice {
            if monitor.isLow(lowest) {
                Image(systemName: BatterySymbol.name(for: lowest.percent))
                Text("\(lowest.percent)%")
            } else {
                Image(systemName: BatterySymbol.name(for: lowest.percent))
            }
        } else {
            Image(systemName: "battery.100percent.circle")
        }
    }
}

enum BatterySymbol {
    static func name(for percent: Int) -> String {
        switch percent {
        case ..<13: "battery.0percent"
        case ..<38: "battery.25percent"
        case ..<63: "battery.50percent"
        case ..<88: "battery.75percent"
        default: "battery.100percent"
        }
    }

    static func device(_ category: String?) -> String {
        switch category?.lowercased() {
        case "mouse": "magicmouse"
        case "keyboard": "keyboard"
        case "trackpad": "rectangle.and.hand.point.up.left"
        case "headphones", "headset": "headphones"
        case "gamecontroller", "game controller": "gamecontroller"
        default: "dot.radiowaves.left.and.right"
        }
    }
}

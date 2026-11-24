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

import AppKit
import SwiftUI

struct MenuContentView: View {
    @Bindable var monitor: BatteryMonitor

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Bluetooth batteries")
                .font(.headline)

            if monitor.devices.isEmpty {
                Text("No connected device is reporting a battery level.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            } else {
                VStack(spacing: 10) {
                    ForEach(monitor.devices) { device in
                        DeviceRow(device: device, isLow: monitor.isLow(device))
                    }
                }
            }

            Divider()

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Warn below")
                    Spacer()
                    Text("\(monitor.threshold)%")
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
                Slider(
                    value: Binding(
                        get: { Double(monitor.threshold) },
                        set: { monitor.threshold = Int($0.rounded()) }
                    ),
                    in: 5...95,
                    step: 5
                )
            }

            Toggle(
                "Launch at login",
                isOn: Binding(
                    get: { monitor.launchAtLogin },
                    set: { monitor.setLaunchAtLogin($0) }
                )
            )
            .toggleStyle(.checkbox)

            if !monitor.notificationsAllowed {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Image(systemName: "bell.slash")
                        .foregroundStyle(.orange)
                    Text("Notifications are off, so you won't get warnings.")
                        .font(.callout)
                    Button("Settings…") {
                        if let url = URL(string: "x-apple.systempreferences:com.apple.Notifications-Settings.extension") {
                            NSWorkspace.shared.open(url)
                        }
                    }
                    .buttonStyle(.link)
                }
            }

            Divider()

            HStack {
                if let updated = monitor.lastUpdated {
                    Text("Updated \(updated, format: .relative(presentation: .named))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button("Refresh") { monitor.refresh() }
                Button("Quit") { NSApp.terminate(nil) }
            }
            .controlSize(.small)
        }
        .padding(14)
        .frame(width: 300)
        .onAppear { monitor.refresh() }
    }
}

private struct DeviceRow: View {
    let device: BatteryDevice
    let isLow: Bool

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: BatterySymbol.device(device.category))
                .frame(width: 22)
                .foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(device.name)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    Spacer()
                    Text("\(device.percent)%")
                        .monospacedDigit()
                        .fontWeight(isLow ? .semibold : .regular)
                        .foregroundStyle(isLow ? .red : .primary)
                }
                ProgressView(value: Double(device.percent), total: 100)
                    .tint(isLow ? .red : .green)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

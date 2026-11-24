import Foundation
import Observation

/// Stand-in for the app's BatteryMonitor with fixed data, so the real MenuContentView can be
/// rendered for the App Store screenshots. Keep its interface in step with the real one.
@MainActor
@Observable
final class BatteryMonitor {
    var devices: [BatteryDevice]
    var lastUpdated: Date? = .now
    var notificationsAllowed = true
    var launchAtLogin = true
    var threshold: Int

    init(devices: [BatteryDevice], threshold: Int) {
        self.devices = devices
        self.threshold = threshold
    }

    var lowestDevice: BatteryDevice? { devices.min { $0.percent < $1.percent } }
    func isLow(_ device: BatteryDevice) -> Bool { device.percent < threshold }
    func refresh() {}
    func setLaunchAtLogin(_ enabled: Bool) { launchAtLogin = enabled }
}

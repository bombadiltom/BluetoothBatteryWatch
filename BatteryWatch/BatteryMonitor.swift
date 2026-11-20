import AppKit
import Observation
import ServiceManagement
@preconcurrency import UserNotifications

/// Polls battery levels and sends one notification per device each time it drops below the threshold.
@MainActor
@Observable
final class BatteryMonitor {
    static let pollInterval: TimeInterval = 5 * 60

    private(set) var devices: [BatteryDevice] = []
    private(set) var lastUpdated: Date?
    private(set) var notificationsAllowed = true
    private(set) var launchAtLogin = SMAppService.mainApp.status == .enabled

    /// Warn when a device's level is *below* this percentage.
    var threshold: Int {
        didSet {
            UserDefaults.standard.set(threshold, forKey: Keys.threshold)
            evaluateAlerts()
        }
    }

    /// Devices already warned about in the current discharge cycle. Persisted so a relaunch
    /// (e.g. at login) doesn't repeat the same warning.
    private var alerted: Set<String> {
        didSet { UserDefaults.standard.set(Array(alerted), forKey: Keys.alerted) }
    }

    private var timer: Timer?
    private let notificationDelegate = NotificationDelegate()

    var lowestDevice: BatteryDevice? { devices.min { $0.percent < $1.percent } }

    func isLow(_ device: BatteryDevice) -> Bool { device.percent < threshold }

    init() {
        let stored = UserDefaults.standard.integer(forKey: Keys.threshold)
        threshold = stored == 0 ? 50 : stored
        alerted = Set(UserDefaults.standard.stringArray(forKey: Keys.alerted) ?? [])

        UNUserNotificationCenter.current().delegate = notificationDelegate
        requestNotificationPermission()

        refresh()
        timer = Timer.scheduledTimer(withTimeInterval: Self.pollInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.refresh() }
        }
        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification, object: nil, queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.refresh() }
        }
    }

    func refresh() {
        devices = BatteryReader.readDevices()
        lastUpdated = .now
        evaluateAlerts()
        Task { await updateNotificationStatus() }
    }

    func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            NSLog("BatteryWatch: launch-at-login change failed: \(error)")
        }
        launchAtLogin = SMAppService.mainApp.status == .enabled
    }

    private func evaluateAlerts() {
        var alerted = self.alerted
        for device in devices {
            if isLow(device) {
                if alerted.insert(device.id).inserted {
                    sendNotification(for: device)
                }
            } else {
                // Charged back up (or threshold lowered): arm the warning again.
                alerted.remove(device.id)
            }
        }
        if alerted != self.alerted { self.alerted = alerted }
    }

    private func sendNotification(for device: BatteryDevice) {
        let content = UNMutableNotificationContent()
        content.title = "\(device.name) at \(device.percent)%"
        content.body = "Time to charge it — it's below your \(threshold)% warning level."
        content.sound = .default
        let request = UNNotificationRequest(identifier: "low-\(device.id)", content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }

    private func requestNotificationPermission() {
        Task {
            _ = try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])
            await updateNotificationStatus()
        }
    }

    private func updateNotificationStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        notificationsAllowed = settings.authorizationStatus == .authorized
            || settings.authorizationStatus == .provisional
    }

    private enum Keys {
        static let threshold = "threshold"
        static let alerted = "alertedDevices"
    }
}

/// Shows banners even if the app happens to be active.
private final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }
}

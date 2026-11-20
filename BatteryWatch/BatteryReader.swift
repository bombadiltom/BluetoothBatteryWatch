import Foundation
import IOBluetooth
import IOKit

/// One Bluetooth accessory that reports its battery level to macOS.
struct BatteryDevice: Identifiable, Equatable, Sendable {
    /// Bluetooth address, lowercased with dashes (e.g. "bc-d0-74-ca-b5-59").
    let id: String
    let name: String
    /// IOKit's "Accessory Category" (e.g. "Mouse", "Keyboard", "Trackpad"), if any.
    let category: String?
    let percent: Int
}

/// Reads battery levels straight from the IORegistry — the same data `ioreg -k BatteryPercent` shows.
enum BatteryReader {
    static func readDevices() -> [BatteryDevice] {
        let matching = [kIOPropertyExistsMatchKey: "BatteryPercent"] as CFDictionary
        var iterator: io_iterator_t = 0
        guard IOServiceGetMatchingServices(kIOMainPortDefault, matching, &iterator) == KERN_SUCCESS else {
            return []
        }
        defer { IOObjectRelease(iterator) }

        var byAddress: [String: BatteryDevice] = [:]
        var service = IOIteratorNext(iterator)
        while service != 0 {
            defer {
                IOObjectRelease(service)
                service = IOIteratorNext(iterator)
            }
            var unmanaged: Unmanaged<CFMutableDictionary>?
            guard IORegistryEntryCreateCFProperties(service, &unmanaged, kCFAllocatorDefault, 0) == KERN_SUCCESS,
                  let props = unmanaged?.takeRetainedValue() as? [String: Any],
                  let percent = props["BatteryPercent"] as? Int
            else { continue }

            let address = normalizedAddress(props)
            let id = address ?? "service-\(service)"
            // A device can expose several HID services; keep the first one per address.
            if byAddress[id] != nil { continue }

            byAddress[id] = BatteryDevice(
                id: id,
                name: displayName(address: address, props: props),
                category: nonEmpty(props["Accessory Category"] as? String),
                percent: max(0, min(100, percent))
            )
        }
        return byAddress.values.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    private static func normalizedAddress(_ props: [String: Any]) -> String? {
        let raw = nonEmpty(props["DeviceAddress"] as? String) ?? nonEmpty(props["SerialNumber"] as? String)
        return raw?.lowercased().replacingOccurrences(of: ":", with: "-")
    }

    private static func displayName(address: String?, props: [String: Any]) -> String {
        if let address,
           let device = IOBluetoothDevice(addressString: address),
           let name = nonEmpty(device.name) {
            return name
        }
        return nonEmpty(props["Product"] as? String)
            ?? nonEmpty(props["Accessory Category"] as? String)
            ?? "Bluetooth device"
    }

    private static func nonEmpty(_ string: String?) -> String? {
        guard let trimmed = string?.trimmingCharacters(in: .whitespacesAndNewlines), !trimmed.isEmpty else {
            return nil
        }
        return trimmed
    }
}

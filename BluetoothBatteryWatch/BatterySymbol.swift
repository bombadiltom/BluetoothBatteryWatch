/// SF Symbol names for battery levels and accessory types.
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

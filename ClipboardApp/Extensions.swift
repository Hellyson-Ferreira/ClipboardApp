import SwiftUI
import AppKit

extension Notification.Name {
    static let closePanelNotification = Notification.Name("ClipboardApp.closePanel")
}

extension Color {
    init(hex: String) {
        var raw = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if raw.hasPrefix("#") { raw = String(raw.dropFirst()) }
        var int: UInt64 = 0
        Scanner(string: raw).scanHexInt64(&int)
        let r, g, b, a: Double
        switch raw.count {
        case 6:
            (r, g, b, a) = (
                Double((int >> 16) & 0xFF) / 255,
                Double((int >> 8)  & 0xFF) / 255,
                Double(int         & 0xFF) / 255,
                1
            )
        case 8:
            (r, g, b, a) = (
                Double((int >> 24) & 0xFF) / 255,
                Double((int >> 16) & 0xFF) / 255,
                Double((int >> 8)  & 0xFF) / 255,
                Double(int         & 0xFF) / 255
            )
        default:
            (r, g, b, a) = (1, 1, 1, 1)
        }
        self.init(red: r, green: g, blue: b, opacity: a)
    }
}

extension Date {
    var relativeShort: String {
        let diff = Date().timeIntervalSince(self)
        switch diff {
        case ..<60:       return String(localized: "now")
        case ..<3600:     return "\(Int(diff / 60))m"
        case ..<86400:    return "\(Int(diff / 3600))h"
        default:          return "\(Int(diff / 86400))d"
        }
    }
}

extension NSImage {
    static func appIcon(for appName: String) -> NSImage? {
        let candidates = [
            "/Applications/\(appName).app",
            "/System/Applications/\(appName).app",
            "/System/Applications/Utilities/\(appName).app",
        ]
        for path in candidates where FileManager.default.fileExists(atPath: path) {
            return NSWorkspace.shared.icon(forFile: path)
        }
        return nil
    }
}

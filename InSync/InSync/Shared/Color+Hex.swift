import SwiftUI

#if os(macOS)
import AppKit
#endif

extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex.trimmingCharacters(in: CharacterSet(charactersIn: "#")))
        var value: UInt64 = 0
        scanner.scanHexInt64(&value)

        let red = Double((value >> 16) & 0xFF) / 255.0
        let green = Double((value >> 8) & 0xFF) / 255.0
        let blue = Double(value & 0xFF) / 255.0

        self.init(red: red, green: green, blue: blue)
    }

    static let insyncBackground = Color(red: 0.98, green: 0.95, blue: 0.92)
    static let insyncInk = Color(red: 0.16, green: 0.12, blue: 0.11)
    static let insyncSoftPink = Color(red: 1.0, green: 0.86, blue: 0.89)
    static let insyncSoftBlue = Color(red: 0.86, green: 0.92, blue: 1.0)
}

#if os(macOS)
extension NSColor {
    convenience init(hex: String) {
        let scanner = Scanner(string: hex.trimmingCharacters(in: CharacterSet(charactersIn: "#")))
        var value: UInt64 = 0
        scanner.scanHexInt64(&value)

        let red = CGFloat((value >> 16) & 0xFF) / 255.0
        let green = CGFloat((value >> 8) & 0xFF) / 255.0
        let blue = CGFloat(value & 0xFF) / 255.0

        self.init(red: red, green: green, blue: blue, alpha: 1.0)
    }
}
#endif


import SwiftUI

/// Dark-theme palette aligned with the VPN Bypass Manager mockups.
enum ManagerDesignTokens {
    static let background = Color(red: 0.07, green: 0.07, blue: 0.07)
    static let surface = Color(red: 0.11, green: 0.11, blue: 0.12)
    static let surfaceElevated = Color(red: 0.14, green: 0.14, blue: 0.15)
    static let border = Color.white.opacity(0.08)
    static let accentBlue = Color(red: 0.2, green: 0.4, blue: 1.0)
    static let errorRed = Color(red: 1.0, green: 0.3, blue: 0.3)
    static let successGreen = Color(red: 0.35, green: 0.78, blue: 0.45)
    static let pendingYellow = Color(red: 0.95, green: 0.75, blue: 0.2)
    static let secondaryLabel = Color.white.opacity(0.55)
    static let cornerRadius: CGFloat = 10
    static let cardRadius: CGFloat = 10
}

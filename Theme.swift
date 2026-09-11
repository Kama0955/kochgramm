import SwiftUI

struct Theme {
    // Цвета
    static let background = Color(red: 0.04, green: 0.04, blue: 0.05)
    static let surface = Color(red: 0.09, green: 0.09, blue: 0.11)
    static let surfaceLight = Color(red: 0.14, green: 0.14, blue: 0.17)
    static let accent = Color(red: 0.30, green: 0.55, blue: 1.0)
    static let textPrimary = Color.white
    static let textSecondary = Color(red: 0.60, green: 0.60, blue: 0.65)
    static let divider = Color.white.opacity(0.06)
    static let unread = Color(red: 0.30, green: 0.55, blue: 1.0)
    
    // Градиенты
    static let accentGradient = LinearGradient(
        colors: [Color(red: 0.30, green: 0.55, blue: 1.0),
                 Color(red: 0.45, green: 0.35, blue: 0.95)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // Радиусы
    static let cornerSmall: CGFloat = 8
    static let cornerMedium: CGFloat = 14
    static let cornerLarge: CGFloat = 20
}

// Расширения для удобства
extension View {
    func premiumCard() -> some View {
        self
            .background(Theme.surface)
            .cornerRadius(Theme.cornerMedium)
    }
}

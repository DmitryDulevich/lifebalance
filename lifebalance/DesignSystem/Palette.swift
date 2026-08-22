import SwiftUI

/// Design tokens extracted verbatim (as `oklch(L C H)` triples) from the
/// reference mockup `Time Balance MVP - standalone.html`.
enum Palette {
    // MARK: Accent & hero

    static let accent = Color(oklch: 0.70, 0.13, 300)

    static let heroGradientColors: [Color] = [
        Color(oklch: 0.75, 0.13, 320),
        Color(oklch: 0.70, 0.14, 270)
    ]

    // MARK: Semantic surfaces (light/dark aware)

    static let screenBackgroundStops: [Color] = [
        Color(light: Color(oklch: 0.96, 0.02, 300), dark: Color(red: 26 / 255, green: 23 / 255, blue: 48 / 255)),
        Color(light: Color(oklch: 0.95, 0.025, 260), dark: Color(red: 36 / 255, green: 31 / 255, blue: 61 / 255)),
        Color(light: Color(oklch: 0.95, 0.02, 200), dark: Color(red: 28 / 255, green: 36 / 255, blue: 54 / 255))
    ]

    static let cardBackground = Color(
        light: .white,
        dark: Color(red: 36 / 255, green: 32 / 255, blue: 56 / 255)
    )

    static let textPrimary = Color(
        light: Color(red: 40 / 255, green: 36 / 255, blue: 61 / 255),
        dark: Color(red: 240 / 255, green: 238 / 255, blue: 250 / 255)
    )

    static let textSecondary = Color(
        light: Color(red: 60 / 255, green: 55 / 255, blue: 80 / 255, opacity: 0.55),
        dark: Color(red: 235 / 255, green: 232 / 255, blue: 250 / 255, opacity: 0.6)
    )

    /// Soft tinted background for play buttons, matrix chips and steppers.
    static let softAccentBackground = Color(
        light: Color(oklch: 0.95, 0.015, 280),
        dark: Color(red: 43 / 255, green: 38 / 255, blue: 69 / 255)
    )

    /// Track color for progress bars and radar-chart grid lines.
    static let trackBackground = Color(
        light: Color(red: 90 / 255, green: 70 / 255, blue: 120 / 255, opacity: 0.12),
        dark: Color(red: 235 / 255, green: 232 / 255, blue: 250 / 255, opacity: 0.16)
    )

    // MARK: Sphere colors

    /// Fixed hue per preset life sphere, in onboarding preset order.
    static let sphereColors: [Color] = [
        Color(oklch: 0.62, 0.13, 165), // Здоровье
        Color(oklch: 0.60, 0.14, 250), // Работа / Карьера
        Color(oklch: 0.62, 0.14, 145), // Финансы
        Color(oklch: 0.65, 0.15, 20), // Отношения
        Color(oklch: 0.68, 0.13, 60), // Семья
        Color(oklch: 0.64, 0.13, 95), // Обучение
        Color(oklch: 0.62, 0.12, 200), // Отдых
        Color(oklch: 0.62, 0.15, 330) // Творчество
    ]

    static let sphereColorHexes: [String] = [
        "029E72", // Здоровье
        "3284D0", // Работа / Карьера
        "479C4D", // Финансы
        "DB6468", // Отношения
        "D2833B", // Семья
        "A58A07", // Обучение
        "009BA3", // Отдых
        "B761B1" // Творчество
    ]

    // MARK: Matrix quadrants

    static let quadrantDo = Color(oklch: 0.55, 0.16, 30)
    static let quadrantSchedule = Color(oklch: 0.58, 0.14, 250)
    static let quadrantDelegate = Color(oklch: 0.64, 0.13, 95)
    static let quadrantEliminateBorder = Color(
        light: Color(red: 90 / 255, green: 70 / 255, blue: 120 / 255, opacity: 0.1),
        dark: Color(red: 130 / 255, green: 120 / 255, blue: 160 / 255, opacity: 0.2)
    )

    /// Overdue-task accent reuses the "Do" quadrant's red.
    static let overdue = quadrantDo

    // MARK: Custom-sphere picker (onboarding "add your own sphere")

    /// Curated, mutually distinguishable swatches for custom life spheres.
    /// Kept small on purpose so every color reads clearly in both light and dark mode.
    static let sphereSwatches: [String] = [
        "FF5A5F", // red
        "FF8A3D", // orange
        "FFC542", // yellow
        "3DDC97", // green
        "2EC4B6", // teal
        "3D8BFF", // blue
        "6C5CE7", // indigo
        "B15CE6", // purple
        "E6609C", // pink
        "8D6E63" // brown
    ]

    /// Curated SF Symbols for custom life spheres.
    static let sphereIcons: [String] = [
        "star.fill",
        "heart.fill",
        "leaf.fill",
        "book.fill",
        "paintpalette.fill",
        "figure.run",
        "briefcase.fill",
        "house.fill",
        "person.2.fill",
        "airplane",
        "dollarsign.circle.fill",
        "sparkles"
    ]
}

import Foundation

struct LifeAreaPreset: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let colorHex: String
}

extension LifeAreaPreset {
    static let all: [LifeAreaPreset] = [
        LifeAreaPreset(name: String(localized: "Здоровье"), icon: "heart.fill", colorHex: Palette.sphereColorHexes[0]),
        LifeAreaPreset(name: String(localized: "Работа / Карьера"), icon: "briefcase.fill", colorHex: Palette.sphereColorHexes[1]),
        LifeAreaPreset(name: String(localized: "Финансы"), icon: "dollarsign.circle.fill", colorHex: Palette.sphereColorHexes[2]),
        LifeAreaPreset(name: String(localized: "Отношения"), icon: "person.2.fill", colorHex: Palette.sphereColorHexes[3]),
        LifeAreaPreset(name: String(localized: "Семья"), icon: "house.fill", colorHex: Palette.sphereColorHexes[4]),
        LifeAreaPreset(name: String(localized: "Обучение"), icon: "book.fill", colorHex: Palette.sphereColorHexes[5]),
        LifeAreaPreset(name: String(localized: "Отдых"), icon: "leaf.fill", colorHex: Palette.sphereColorHexes[6]),
        LifeAreaPreset(name: String(localized: "Творчество"), icon: "paintpalette.fill", colorHex: Palette.sphereColorHexes[7])
    ]
}

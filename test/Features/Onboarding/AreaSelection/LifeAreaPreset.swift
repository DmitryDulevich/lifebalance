import Foundation

struct LifeAreaPreset: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let colorHex: String
}

extension LifeAreaPreset {
    static let all: [LifeAreaPreset] = [
        LifeAreaPreset(name: "Здоровье", icon: "heart.fill", colorHex: Palette.sphereColorHexes[0]),
        LifeAreaPreset(name: "Работа / Карьера", icon: "briefcase.fill", colorHex: Palette.sphereColorHexes[1]),
        LifeAreaPreset(name: "Финансы", icon: "dollarsign.circle.fill", colorHex: Palette.sphereColorHexes[2]),
        LifeAreaPreset(name: "Отношения", icon: "person.2.fill", colorHex: Palette.sphereColorHexes[3]),
        LifeAreaPreset(name: "Семья", icon: "house.fill", colorHex: Palette.sphereColorHexes[4]),
        LifeAreaPreset(name: "Обучение", icon: "book.fill", colorHex: Palette.sphereColorHexes[5]),
        LifeAreaPreset(name: "Отдых", icon: "leaf.fill", colorHex: Palette.sphereColorHexes[6]),
        LifeAreaPreset(name: "Творчество", icon: "paintpalette.fill", colorHex: Palette.sphereColorHexes[7])
    ]
}

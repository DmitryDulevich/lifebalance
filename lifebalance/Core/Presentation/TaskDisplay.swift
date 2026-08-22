import SwiftUI

/// Shared row-subtitle formatting ("Область · 30 мин" / "Область · Просрочено · 30 мин"),
/// used by both the Today and Tasks screens so task rows read identically everywhere.
enum TaskDisplay {
    static func subtitle(for task: TaskItem, showOverdueLabel: Bool = false) -> String {
        var parts: [String] = []
        if let area = task.lifeArea {
            parts.append(area.name)
        }
        if showOverdueLabel {
            parts.append("Просрочено")
        }
        if let minutes = task.estimateMinutes {
            parts.append("\(minutes) мин")
        }
        return parts.isEmpty ? "Без срока" : parts.joined(separator: " · ")
    }

    static func ringColor(for task: TaskItem) -> Color {
        guard let hex = task.lifeArea?.colorHex else { return Palette.textSecondary }
        return Color(hex: hex)
    }
}

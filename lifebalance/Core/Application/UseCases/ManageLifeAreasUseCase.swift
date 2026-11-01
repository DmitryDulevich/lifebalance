import Foundation

struct LifeAreaInput {
    let name: String
    let icon: String
    let colorHex: String
}

enum LifeAreaManagementError: LocalizedError {
    case invalidName
    case duplicateName
    case minimumActiveAreas
    case maximumActiveAreas
    case invalidReordering

    var errorDescription: String? {
        switch self {
        case .invalidName:
            return String(localized: "Название сферы должно содержать от 1 до 30 символов.")
        case .duplicateName:
            return String(localized: "Сфера с таким названием уже существует, возможно, в архиве.")
        case .minimumActiveAreas:
            return String(localized: "Должно остаться минимум 3 активные сферы.")
        case .maximumActiveAreas:
            return String(localized: "Можно использовать не более 8 активных сфер.")
        case .invalidReordering:
            return String(localized: "Не удалось изменить порядок сфер. Обновите экран и повторите попытку.")
        }
    }
}

@MainActor
final class ManageLifeAreasUseCase {
    private let repository: LifeAreaRepository

    init(repository: LifeAreaRepository) {
        self.repository = repository
    }

    @discardableResult
    func create(_ input: LifeAreaInput) throws -> LifeArea {
        let activeAreas = try repository.fetchActiveAreas()
        guard activeAreas.count < 8 else {
            throw LifeAreaManagementError.maximumActiveAreas
        }

        let normalized = try validateAndNormalize(input, excluding: nil)
        let nextOrder = (activeAreas.map(\.order).max() ?? -1) + 1
        let area = LifeArea(
            name: normalized.name,
            icon: normalized.icon,
            colorHex: normalized.colorHex,
            order: nextOrder
        )
        try repository.insert([area])
        return area
    }

    func update(_ area: LifeArea, with input: LifeAreaInput) throws {
        let normalized = try validateAndNormalize(input, excluding: area.id)
        let previous = (area.name, area.icon, area.colorHex)
        area.name = normalized.name
        area.icon = normalized.icon
        area.colorHex = normalized.colorHex

        do {
            try repository.save()
        } catch {
            (area.name, area.icon, area.colorHex) = previous
            throw error
        }
    }

    func setActive(_ area: LifeArea, isActive: Bool) throws {
        guard area.isActive != isActive else { return }
        let activeAreas = try repository.fetchActiveAreas()

        if isActive {
            guard activeAreas.count < 8 else {
                throw LifeAreaManagementError.maximumActiveAreas
            }
        } else {
            guard activeAreas.count > 3 else {
                throw LifeAreaManagementError.minimumActiveAreas
            }
        }

        let previous = (area.isActive, area.order)
        area.isActive = isActive
        if isActive {
            area.order = (activeAreas.map(\.order).max() ?? -1) + 1
        }

        do {
            try repository.save()
        } catch {
            (area.isActive, area.order) = previous
            throw error
        }
    }

    func reorder(_ reorderedAreas: [LifeArea]) throws {
        let activeAreas = try repository.fetchActiveAreas()
        guard Set(activeAreas.map(\.id)) == Set(reorderedAreas.map(\.id)) else {
            throw LifeAreaManagementError.invalidReordering
        }

        let previousOrders = Dictionary(uniqueKeysWithValues: activeAreas.map { ($0.id, $0.order) })
        for (index, area) in reorderedAreas.enumerated() {
            area.order = index
        }

        do {
            try repository.save()
        } catch {
            for area in activeAreas {
                area.order = previousOrders[area.id] ?? area.order
            }
            throw error
        }
    }

    private func validateAndNormalize(_ input: LifeAreaInput, excluding areaID: UUID?) throws -> LifeAreaInput {
        let name = input.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard (1...30).contains(name.count) else {
            throw LifeAreaManagementError.invalidName
        }

        let normalizedName = normalize(name)
        let allAreas = try repository.fetchAllAreas()
        guard !allAreas.contains(where: { area in
            area.id != areaID && normalize(area.name) == normalizedName
        }) else {
            throw LifeAreaManagementError.duplicateName
        }

        return LifeAreaInput(name: name, icon: input.icon, colorHex: input.colorHex)
    }

    private func normalize(_ name: String) -> String {
        name.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
    }
}

import Foundation
import Observation

struct CustomAreaDraft: Identifiable {
    let id = UUID()
    var name: String
    var icon: String
    var colorHex: String
}

@Observable
@MainActor
final class AreaSelectionViewModel {
    let presets = LifeAreaPreset.all

    var selectedPresetIDs: Set<UUID> = []
    var customAreas: [CustomAreaDraft] = []
    var selectedCustomIDs: Set<UUID> = []

    var isAddingCustomArea = false
    var customNameInput = ""
    var customIcon = Palette.sphereIcons[0]
    var customColorHex = Palette.sphereSwatches[0]
    var customAreaErrorMessage: String?

    var errorMessage: String?

    private let selectLifeAreasUseCase: SelectLifeAreasUseCase

    init(selectLifeAreasUseCase: SelectLifeAreasUseCase) {
        self.selectLifeAreasUseCase = selectLifeAreasUseCase
    }

    var selectedCount: Int {
        selectedPresetIDs.count + selectedCustomIDs.count
    }

    var canSelectMore: Bool {
        selectedCount < 8
    }

    var canContinue: Bool {
        (3...8).contains(selectedCount)
    }

    func togglePreset(_ preset: LifeAreaPreset) {
        if selectedPresetIDs.contains(preset.id) {
            selectedPresetIDs.remove(preset.id)
        } else if canSelectMore {
            selectedPresetIDs.insert(preset.id)
        }
    }

    func toggleCustom(_ area: CustomAreaDraft) {
        if selectedCustomIDs.contains(area.id) {
            selectedCustomIDs.remove(area.id)
        } else if canSelectMore {
            selectedCustomIDs.insert(area.id)
        }
    }

    func removeCustom(_ area: CustomAreaDraft) {
        customAreas.removeAll { $0.id == area.id }
        selectedCustomIDs.remove(area.id)
    }

    private func isDuplicateName(_ trimmed: String) -> Bool {
        let existingNames = presets.map(\.name) + customAreas.map(\.name)
        return existingNames.contains { $0.caseInsensitiveCompare(trimmed) == .orderedSame }
    }

    func addCustomArea() {
        let trimmed = customNameInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed.count <= 30 else {
            customAreaErrorMessage = "Название должно быть от 1 до 30 символов."
            return
        }
        guard !isDuplicateName(trimmed) else {
            customAreaErrorMessage = "Сфера с таким названием уже есть."
            return
        }

        let area = CustomAreaDraft(name: trimmed, icon: customIcon, colorHex: customColorHex)
        customAreas.append(area)
        if canSelectMore {
            selectedCustomIDs.insert(area.id)
        }

        customNameInput = ""
        customIcon = Palette.sphereIcons[0]
        customColorHex = Palette.sphereSwatches[0]
        customAreaErrorMessage = nil
        isAddingCustomArea = false
    }

    func continueTapped() -> Bool {
        let selectedPresets = presets.filter { selectedPresetIDs.contains($0.id) }
        let selectedCustoms = customAreas.filter { selectedCustomIDs.contains($0.id) }

        let drafts =
            selectedPresets.map { LifeAreaDraft(name: $0.name, icon: $0.icon, colorHex: $0.colorHex) }
            + selectedCustoms.map { LifeAreaDraft(name: $0.name, icon: $0.icon, colorHex: $0.colorHex) }

        do {
            try selectLifeAreasUseCase.execute(drafts)
            errorMessage = nil
            return true
        } catch {
            if !(error is SelectLifeAreasUseCase.ValidationError) {
                AppLogger.error(error, context: "onboarding.areas.save")
            }
            errorMessage = error.localizedDescription
            return false
        }
    }
}

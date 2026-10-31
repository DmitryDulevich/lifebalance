import Foundation
import Observation
import SwiftUI

@Observable
@MainActor
final class LifeAreasSettingsViewModel {
    var activeAreas: [LifeArea] = []
    var archivedAreas: [LifeArea] = []
    var errorMessage: String?
    var formErrorMessage: String?
    var isFormPresented = false
    var editingArea: LifeArea?
    var formName = ""
    var formIcon = Palette.sphereIcons[0]
    var formColorHex = Palette.sphereSwatches[0]

    private let repository: LifeAreaRepository
    private let manageLifeAreasUseCase: ManageLifeAreasUseCase

    init(repository: LifeAreaRepository, manageLifeAreasUseCase: ManageLifeAreasUseCase) {
        self.repository = repository
        self.manageLifeAreasUseCase = manageLifeAreasUseCase
    }

    var canAddArea: Bool { activeAreas.count < 8 }

    func load() {
        do {
            let allAreas = try repository.fetchAllAreas()
            activeAreas = allAreas.filter(\.isActive).sorted { $0.order < $1.order }
            archivedAreas = allAreas.filter { !$0.isActive }.sorted { $0.name < $1.name }
            errorMessage = nil
        } catch {
            AppLogger.error(error, context: "profile.life_areas.load")
            errorMessage = error.localizedDescription
        }
    }

    func startAdding() {
        guard canAddArea else {
            errorMessage = LifeAreaManagementError.maximumActiveAreas.localizedDescription
            return
        }
        editingArea = nil
        formName = ""
        formIcon = Palette.sphereIcons[0]
        formColorHex = Palette.sphereSwatches[0]
        formErrorMessage = nil
        isFormPresented = true
    }

    func startEditing(_ area: LifeArea) {
        editingArea = area
        formName = area.name
        formIcon = area.icon
        formColorHex = area.colorHex
        formErrorMessage = nil
        isFormPresented = true
    }

    @discardableResult
    func saveForm() -> Bool {
        let input = LifeAreaInput(name: formName, icon: formIcon, colorHex: formColorHex)
        do {
            if let editingArea {
                try manageLifeAreasUseCase.update(editingArea, with: input)
            } else {
                try manageLifeAreasUseCase.create(input)
            }
            formErrorMessage = nil
            isFormPresented = false
            load()
            return true
        } catch {
            logUnexpected(error, context: "profile.life_areas.save")
            formErrorMessage = error.localizedDescription
            return false
        }
    }

    func archive(_ area: LifeArea) {
        setActive(area, isActive: false)
    }

    func restore(_ area: LifeArea) {
        setActive(area, isActive: true)
    }

    func move(from source: IndexSet, to destination: Int) {
        let previous = activeAreas
        activeAreas.move(fromOffsets: source, toOffset: destination)
        do {
            try manageLifeAreasUseCase.reorder(activeAreas)
            errorMessage = nil
        } catch {
            logUnexpected(error, context: "profile.life_areas.reorder")
            activeAreas = previous
            errorMessage = error.localizedDescription
        }
    }

    private func setActive(_ area: LifeArea, isActive: Bool) {
        do {
            try manageLifeAreasUseCase.setActive(area, isActive: isActive)
            errorMessage = nil
            load()
        } catch {
            logUnexpected(error, context: "profile.life_areas.set_active")
            errorMessage = error.localizedDescription
        }
    }

    private func logUnexpected(_ error: Error, context: String) {
        if !(error is LifeAreaManagementError) {
            AppLogger.error(error, context: context)
        }
    }
}

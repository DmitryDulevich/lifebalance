import XCTest

final class LifebalanceUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testCompletesOnboarding() {
        let app = launchApp()

        XCTAssertTrue(app.buttons["onboarding.start"].waitForExistence(timeout: 5))
        app.buttons["onboarding.start"].tap()
        app.buttons["area.preset.Здоровье"].tap()
        app.buttons["area.preset.Работа / Карьера"].tap()
        app.buttons["area.preset.Финансы"].tap()
        app.buttons["onboarding.areas.continue"].tap()

        XCTAssertTrue(app.buttons["onboarding.balance.skip"].waitForExistence(timeout: 5))
        app.buttons["onboarding.balance.skip"].tap()

        XCTAssertTrue(app.tabBars.buttons["Сегодня"].waitForExistence(timeout: 5))
    }

    func testCreatesTask() {
        let app = launchApp(completedOnboarding: true)

        XCTAssertTrue(app.tabBars.buttons["Задачи"].waitForExistence(timeout: 5))
        app.tabBars.buttons["Задачи"].tap()
        app.buttons["tasks.add"].tap()

        let titleField = app.textFields["task.title"]
        XCTAssertTrue(titleField.waitForExistence(timeout: 5))
        titleField.tap()
        titleField.typeText("UI задача")
        app.buttons["task.save"].tap()

        XCTAssertTrue(app.staticTexts["UI задача"].waitForExistence(timeout: 5))
    }

    func testStartsFocusSession() {
        let app = launchApp(completedOnboarding: true)

        XCTAssertTrue(app.tabBars.buttons["Задачи"].waitForExistence(timeout: 5))
        app.tabBars.buttons["Задачи"].tap()

        let playButton = app.buttons["task.play.Тестовая фокус-задача"]
        XCTAssertTrue(playButton.waitForExistence(timeout: 5))
        playButton.tap()

        XCTAssertTrue(app.staticTexts["focus.title"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Тестовая фокус-задача"].exists)
        app.buttons["focus.finish"].tap()
    }

    func testAddsLifeAreaFromProfile() {
        let app = launchApp(completedOnboarding: true)

        XCTAssertTrue(app.tabBars.buttons["Профиль"].waitForExistence(timeout: 5))
        app.tabBars.buttons["Профиль"].tap()
        app.buttons["profile.life_areas"].tap()

        let addButton = app.buttons["life_area.add"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 5))
        addButton.tap()

        let nameField = app.textFields["life_area.name"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 5))
        nameField.tap()
        nameField.typeText("Хобби")
        app.buttons["life_area.save"].tap()

        XCTAssertTrue(app.staticTexts["Хобби"].waitForExistence(timeout: 5))
    }

    func testPausesAndArchivesGoal() {
        let app = launchApp(completedOnboarding: true)

        XCTAssertTrue(app.tabBars.buttons["Цели"].waitForExistence(timeout: 5))
        app.tabBars.buttons["Цели"].tap()

        let menu = app.buttons["goal.menu.Тестовая цель"]
        XCTAssertTrue(menu.waitForExistence(timeout: 5))
        menu.tap()
        app.buttons["Поставить на паузу"].tap()

        app.buttons["goals.filter.paused"].tap()
        XCTAssertTrue(app.staticTexts["Тестовая цель"].waitForExistence(timeout: 5))

        app.buttons["goal.menu.Тестовая цель"].tap()
        app.buttons["Архивировать"].tap()
        app.buttons["goals.filter.archived"].tap()

        XCTAssertTrue(app.staticTexts["Тестовая цель"].waitForExistence(timeout: 5))
    }

    private func launchApp(completedOnboarding: Bool = false) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing"]
        if completedOnboarding {
            app.launchArguments.append("--ui-testing-completed")
        }
        app.launch()
        return app
    }
}

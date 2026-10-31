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

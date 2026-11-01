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

    func testOpensPrivacyPolicyAfterOnboarding() {
        let app = launchApp(completedOnboarding: true)

        XCTAssertTrue(app.tabBars.buttons["Профиль"].waitForExistence(timeout: 5))
        app.tabBars.buttons["Профиль"].tap()

        let privacyLink = app.buttons["profile.privacy_policy"]
        XCTAssertTrue(privacyLink.waitForExistence(timeout: 5))
        privacyLink.tap()

        XCTAssertTrue(app.navigationBars["Конфиденциальность"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Какие данные использует приложение"].exists)
        XCTAssertTrue(app.staticTexts["Хранение и удаление"].exists)
    }

    func testOpensDiagnosticsAndOffersExport() {
        let app = launchApp(completedOnboarding: true)

        XCTAssertTrue(app.tabBars.buttons["Профиль"].waitForExistence(timeout: 5))
        app.tabBars.buttons["Профиль"].tap()
        app.buttons["profile.diagnostics"].tap()

        XCTAssertTrue(app.navigationBars["Диагностика"].waitForExistence(timeout: 5))
        XCTAssertTrue(
            app.descendants(matching: .any)["diagnostics.storage.state"]
                .waitForExistence(timeout: 5)
        )
        XCTAssertTrue(
            app.descendants(matching: .any)["diagnostics.export"]
                .waitForExistence(timeout: 5)
        )
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

    func testShowsGoalTasksAndUpdatesProgress() {
        let app = launchApp(completedOnboarding: true)

        XCTAssertTrue(app.tabBars.buttons["Цели"].waitForExistence(timeout: 5))
        app.tabBars.buttons["Цели"].tap()

        let openTasks = app.buttons["goal.tasks.Тестовая цель"]
        XCTAssertTrue(openTasks.waitForExistence(timeout: 5))
        openTasks.tap()

        XCTAssertTrue(app.staticTexts["0 из 1 задач выполнено"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Тестовая фокус-задача"].exists)
        app.buttons["task.toggle.Тестовая фокус-задача"].tap()

        XCTAssertTrue(app.buttons["Завершить цель"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["1 из 1 задач выполнено"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["100%"].exists)
        app.buttons["Завершить цель"].tap()
        app.buttons["Готово"].tap()

        app.buttons["goals.filter.completed"].tap()
        XCTAssertTrue(app.staticTexts["Тестовая цель"].waitForExistence(timeout: 5))
    }

    func testCompletesArchivesAndRestoresTask() {
        let app = launchApp(completedOnboarding: true)

        XCTAssertTrue(app.tabBars.buttons["Задачи"].waitForExistence(timeout: 5))
        app.tabBars.buttons["Задачи"].tap()

        app.buttons["task.toggle.Тестовая фокус-задача"].tap()
        app.buttons["tasks.filter.completed"].tap()
        XCTAssertTrue(app.staticTexts["Тестовая фокус-задача"].waitForExistence(timeout: 5))

        app.buttons["task.menu.Тестовая фокус-задача"].tap()
        app.buttons["Архивировать"].tap()
        app.buttons["tasks.filter.archived"].tap()
        XCTAssertTrue(app.staticTexts["Тестовая фокус-задача"].waitForExistence(timeout: 5))

        app.buttons["task.menu.Тестовая фокус-задача"].tap()
        app.buttons["Восстановить"].tap()
        app.buttons["tasks.filter.active"].tap()
        XCTAssertTrue(app.staticTexts["Тестовая фокус-задача"].waitForExistence(timeout: 5))
    }

    func testTodayMovesOverdueTasksAndShowsGoalProgress() {
        let app = launchApp(completedOnboarding: true)

        XCTAssertTrue(app.staticTexts["Просроченная задача"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["today.goal.Тестовая цель"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["today.focus.start"].exists)

        app.buttons["today.move_all_overdue"].tap()

        XCTAssertFalse(app.staticTexts["Просроченная задача"].waitForExistence(timeout: 2))
    }

    func testOpensAnalyticsAndChangesPeriod() {
        let app = launchApp(completedOnboarding: true)

        XCTAssertTrue(app.tabBars.buttons["Профиль"].waitForExistence(timeout: 5))
        app.tabBars.buttons["Профиль"].tap()
        app.buttons["profile.analytics"].tap()

        XCTAssertTrue(app.navigationBars["Аналитика"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["25 мин"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Фокус по дням"].exists)
        XCTAssertTrue(app.staticTexts["История баланса"].exists)

        app.buttons["analytics.period.30"].tap()
        XCTAssertTrue(app.staticTexts["25 мин"].waitForExistence(timeout: 5))
    }

    func testLaunchesInEnglish() {
        let app = launchApp(completedOnboarding: true, language: "en", locale: "en_US")

        XCTAssertTrue(app.tabBars.buttons["Today"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.tabBars.buttons["Tasks"].exists)
        XCTAssertTrue(app.tabBars.buttons["Goals"].exists)
        XCTAssertTrue(app.tabBars.buttons["Balance"].exists)
        XCTAssertTrue(app.tabBars.buttons["Profile"].exists)
    }

    private func launchApp(
        completedOnboarding: Bool = false,
        language: String? = nil,
        locale: String? = nil
    ) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing"]
        if completedOnboarding {
            app.launchArguments.append("--ui-testing-completed")
        }
        if let language {
            app.launchArguments += ["-AppleLanguages", "(\(language))"]
        }
        if let locale {
            app.launchArguments += ["-AppleLocale", locale]
        }
        app.launch()
        return app
    }
}

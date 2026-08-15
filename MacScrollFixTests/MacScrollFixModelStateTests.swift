import Combine
import ServiceManagement
import XCTest
@testable import MacScrollFix

final class MacScrollFixModelStateTests: XCTestCase {
    func testStatusTextPrecedence() {
        XCTAssertEqual(
            MacScrollFixModel.statusText(
                isEnabled: false,
                accessibilityGranted: false,
                isOperational: false
            ),
            "Pasif"
        )
        XCTAssertEqual(
            MacScrollFixModel.statusText(
                isEnabled: false,
                accessibilityGranted: true,
                isOperational: false
            ),
            "Pasif"
        )
        XCTAssertEqual(
            MacScrollFixModel.statusText(
                isEnabled: true,
                accessibilityGranted: false,
                isOperational: false
            ),
            "Erişilebilirlik izni gerekli"
        )
        XCTAssertEqual(
            MacScrollFixModel.statusText(
                isEnabled: true,
                accessibilityGranted: true,
                isOperational: true
            ),
            "Aktif"
        )
        XCTAssertEqual(
            MacScrollFixModel.statusText(
                isEnabled: true,
                accessibilityGranted: true,
                isOperational: false
            ),
            "Yeniden bağlanıyor…"
        )
    }

    func testLaunchAtLoginStatusMapping() {
        XCTAssertEqual(MacScrollFixModel.launchAtLoginState(for: .enabled), .enabled)
        XCTAssertEqual(
            MacScrollFixModel.launchAtLoginState(for: .requiresApproval),
            .requiresApproval
        )
        XCTAssertEqual(MacScrollFixModel.launchAtLoginState(for: .notRegistered), .disabled)
        XCTAssertEqual(MacScrollFixModel.launchAtLoginState(for: .notFound), .unavailable)
    }

    func testMenuBarIconVisibilityPersistsAcrossModelInitialization() async {
        await MainActor.run {
            let defaults = makeTestDefaults()
            defer { defaults.removePersistentDomain(forName: defaultsSuiteName) }

            let model = MacScrollFixModel(defaults: defaults)
            XCTAssertTrue(model.menuBarIconVisible)

            model.hideMenuBarIcon()
            XCTAssertFalse(model.menuBarIconVisible)

            let relaunchedModel = MacScrollFixModel(defaults: defaults)
            XCTAssertFalse(relaunchedModel.menuBarIconVisible)

            relaunchedModel.showMenuBarIcon()
            XCTAssertTrue(relaunchedModel.menuBarIconVisible)

            let visibleModel = MacScrollFixModel(defaults: defaults)
            XCTAssertTrue(visibleModel.menuBarIconVisible)
        }
    }

    func testMenuBarIconVisibilitySetterIsIdempotent() async {
        await MainActor.run {
            let defaults = makeTestDefaults()
            defer { defaults.removePersistentDomain(forName: defaultsSuiteName) }

            let model = MacScrollFixModel(defaults: defaults)
            var publishedChanges = 0
            let observation = model.$menuBarIconVisible
                .dropFirst()
                .sink { _ in publishedChanges += 1 }

            model.setMenuBarIconVisible(true)
            model.setMenuBarIconVisible(false)
            model.setMenuBarIconVisible(false)

            XCTAssertFalse(model.menuBarIconVisible)
            XCTAssertEqual(publishedChanges, 1)
            withExtendedLifetime(observation) {}
        }
    }

    private var defaultsSuiteName: String {
        "MacScrollFixModelStateTests.\(name)"
    }

    private func makeTestDefaults() -> UserDefaults {
        let suiteName = defaultsSuiteName
        UserDefaults().removePersistentDomain(forName: suiteName)
        return UserDefaults(suiteName: suiteName)!
    }
}

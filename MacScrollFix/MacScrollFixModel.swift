import AppKit
import ApplicationServices
import Combine
import OSLog
import ServiceManagement

enum LaunchAtLoginState: Equatable {
    case disabled
    case enabled
    case requiresApproval
    case unavailable

    var isToggleOn: Bool {
        self == .enabled || self == .requiresApproval
    }

    var secondaryText: String? {
        switch self {
        case .requiresApproval:
            return "macOS onayı gerekiyor"
        case .unavailable:
            return "Girişte başlatma kullanılamıyor"
        case .disabled, .enabled:
            return nil
        }
    }
}

@MainActor
final class MacScrollFixModel: ObservableObject {
    static let shared = MacScrollFixModel()

    @Published private(set) var isEnabled: Bool
    @Published private(set) var accessibilityGranted: Bool
    @Published private(set) var launchAtLoginState: LaunchAtLoginState
    @Published private(set) var menuBarIconVisible: Bool

    var isOperational: Bool {
        isEnabled && accessibilityGranted && eventTapManager.isOperational
    }

    var statusText: String {
        Self.statusText(
            isEnabled: isEnabled,
            accessibilityGranted: accessibilityGranted,
            isOperational: isOperational
        )
    }

    private enum DefaultsKey {
        static let correctionEnabled = "mouseScrollCorrectionEnabled"
        static let didRequestAccessibility = "didRequestAccessibility"
        static let menuBarIconHidden = "menuBarIconHidden"
    }

    private let defaults: UserDefaults
    private let eventTapManager = EventTapManager()
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.ozanyuksel.MacScrollFix",
        category: "Application"
    )
    private var permissionTimer: Timer?
    private var hasStarted = false
    private var isShowingAlert = false

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        if defaults.object(forKey: DefaultsKey.correctionEnabled) == nil {
            isEnabled = true
        } else {
            isEnabled = defaults.bool(forKey: DefaultsKey.correctionEnabled)
        }

        accessibilityGranted = AXIsProcessTrusted()
        launchAtLoginState = Self.launchAtLoginState(for: SMAppService.mainApp.status)
        menuBarIconVisible = !defaults.bool(forKey: DefaultsKey.menuBarIconHidden)
    }

    func applicationDidFinishLaunching() {
        guard !hasStarted else { return }
        hasStarted = true

        // LSUIElement ana güvenceyi sağlar; accessory politikası Dock ikonunu ayrıca engeller.
        NSApplication.shared.setActivationPolicy(.accessory)

        let shouldRequestAccessibility =
            !defaults.bool(forKey: DefaultsKey.didRequestAccessibility)
        if shouldRequestAccessibility {
            defaults.set(true, forKey: DefaultsKey.didRequestAccessibility)
            accessibilityGranted = Self.checkAccessibility(prompt: true)
        } else {
            accessibilityGranted = Self.checkAccessibility(prompt: false)
        }

        synchronizeEventTap()
        startPermissionMonitoring()
    }

    func setEnabled(_ enabled: Bool) {
        guard enabled != isEnabled else { return }

        isEnabled = enabled
        defaults.set(enabled, forKey: DefaultsKey.correctionEnabled)

        if enabled {
            accessibilityGranted = Self.checkAccessibility(prompt: false)
        }

        synchronizeEventTap()
    }

    func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                if SMAppService.mainApp.status != .enabled {
                    try SMAppService.mainApp.register()
                }
            } else if SMAppService.mainApp.status != .notRegistered {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            showAlert(
                title: "Girişte Başlatma Değiştirilemedi",
                message: "macOS bu ayarı değiştiremedi. Sistem Ayarları > Genel > Giriş Öğeleri bölümünü kontrol edin.\n\n\(error.localizedDescription)"
            )
        }

        launchAtLoginState = Self.launchAtLoginState(for: SMAppService.mainApp.status)
    }

    func setMenuBarIconVisible(_ isVisible: Bool) {
        guard menuBarIconVisible != isVisible else { return }

        defaults.set(!isVisible, forKey: DefaultsKey.menuBarIconHidden)
        menuBarIconVisible = isVisible
    }

    func hideMenuBarIcon() {
        setMenuBarIconVisible(false)
    }

    func requestMenuBarIconHide() {
        guard !isShowingAlert else { return }
        isShowingAlert = true
        defer { isShowingAlert = false }

        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = "Menü çubuğu simgesi gizlensin mi?"
        alert.informativeText = "MacScrollFix arka planda çalışmaya devam eder. Simgeyi geri getirmek için Uygulamalar klasöründen MacScrollFix’i tekrar açabilirsin. Simge, Mac yeniden başlatıldığında da gizli kalır."
        alert.addButton(withTitle: "Gizle")
        alert.addButton(withTitle: "Vazgeç")

        NSApplication.shared.activate(ignoringOtherApps: true)
        guard alert.runModal() == .alertFirstButtonReturn else { return }

        // Alert'in modal döngüsü tamamlandıktan sonra MenuBarExtra'yı güncelle.
        DispatchQueue.main.async { [weak self] in
            self?.hideMenuBarIcon()
        }
    }

    func showMenuBarIcon() {
        setMenuBarIconVisible(true)
    }

    func openAccessibilitySettings() {
        guard let url = URL(
            string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
        ) else {
            return
        }

        NSWorkspace.shared.open(url)
    }

    func shutdown() {
        permissionTimer?.invalidate()
        permissionTimer = nil
        eventTapManager.stop()
        logger.info("MacScrollFix güvenli biçimde kapatıldı.")
    }

    nonisolated static func statusText(
        isEnabled: Bool,
        accessibilityGranted: Bool,
        isOperational: Bool
    ) -> String {
        guard isEnabled else {
            return "Pasif"
        }
        guard accessibilityGranted else {
            return "Erişilebilirlik izni gerekli"
        }
        return isOperational ? "Aktif" : "Yeniden bağlanıyor…"
    }

    nonisolated static func launchAtLoginState(
        for status: SMAppService.Status
    ) -> LaunchAtLoginState {
        switch status {
        case .enabled:
            return .enabled
        case .requiresApproval:
            return .requiresApproval
        case .notRegistered:
            return .disabled
        case .notFound:
            return .unavailable
        @unknown default:
            return .unavailable
        }
    }

    private static func checkAccessibility(prompt: Bool) -> Bool {
        if prompt {
            let options = [
                kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true
            ] as CFDictionary
            return AXIsProcessTrustedWithOptions(options)
        }

        return AXIsProcessTrusted()
    }

    private func startPermissionMonitoring() {
        permissionTimer?.invalidate()
        let timer = Timer(
            timeInterval: 2.0,
            target: self,
            selector: #selector(monitorSystemState),
            userInfo: nil,
            repeats: true
        )
        timer.tolerance = 0.4
        RunLoop.main.add(timer, forMode: .common)
        permissionTimer = timer
    }

    @objc private func monitorSystemState() {
        let isGrantedNow = AXIsProcessTrusted()
        if isGrantedNow != accessibilityGranted {
            accessibilityGranted = isGrantedNow
            synchronizeEventTap()
        } else if isEnabled && isGrantedNow {
            let wasOperational = eventTapManager.isOperational
            _ = eventTapManager.restoreIfNeeded()
            if wasOperational != eventTapManager.isOperational {
                objectWillChange.send()
            }
        }

        let launchAtLoginStateNow = Self.launchAtLoginState(for: SMAppService.mainApp.status)
        if launchAtLoginStateNow != launchAtLoginState {
            launchAtLoginState = launchAtLoginStateNow
        }
    }

    private func synchronizeEventTap() {
        if isEnabled && accessibilityGranted {
            if !eventTapManager.start() {
                logger.error("Scroll event tap başlatılamadı; otomatik olarak yeniden denenecek.")
            }
        } else {
            eventTapManager.stop()
        }

        // isOperational, event tap kurulum sonucuna da bağlı bir computed property'dir.
        objectWillChange.send()
    }

    private func showAlert(title: String, message: String) {
        guard !isShowingAlert else { return }
        isShowingAlert = true
        defer { isShowingAlert = false }

        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = title
        alert.informativeText = message
        alert.addButton(withTitle: "Tamam")

        NSApplication.shared.activate(ignoringOtherApps: true)
        alert.runModal()
    }
}

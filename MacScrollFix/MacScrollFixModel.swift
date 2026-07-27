import AppKit
import ApplicationServices
import Combine
import OSLog
import ServiceManagement

@MainActor
final class MacScrollFixModel: ObservableObject {
    static let shared = MacScrollFixModel()

    @Published private(set) var isEnabled: Bool
    @Published private(set) var accessibilityGranted: Bool
    @Published private(set) var launchAtLogin: Bool

    var isOperational: Bool {
        isEnabled && accessibilityGranted && eventTapManager.isOperational
    }

    var statusText: String {
        if isOperational {
            return "Aktif"
        }
        if !accessibilityGranted {
            return "Kapalı · Erişilebilirlik izni gerekli"
        }
        if isEnabled {
            return "Kapalı · Yeniden bağlanıyor"
        }
        return "Kapalı"
    }

    private enum DefaultsKey {
        static let correctionEnabled = "mouseScrollCorrectionEnabled"
        static let didRequestAccessibility = "didRequestAccessibility"
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

    private init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        if defaults.object(forKey: DefaultsKey.correctionEnabled) == nil {
            isEnabled = true
        } else {
            isEnabled = defaults.bool(forKey: DefaultsKey.correctionEnabled)
        }

        accessibilityGranted = AXIsProcessTrusted()
        launchAtLogin = Self.isLoginItemEnabled
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

        // İlk çalıştırmada macOS zaten kendi izin penceresini gösterir. Aynı anda
        // ikinci bir pencere açmamak için özel açıklamayı sonraki açılışlara bırakırız.
        if !accessibilityGranted && !shouldRequestAccessibility {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
                self?.showAccessibilityExplanation()
            }
        }
    }

    func setEnabled(_ enabled: Bool) {
        guard enabled != isEnabled else { return }

        isEnabled = enabled
        defaults.set(enabled, forKey: DefaultsKey.correctionEnabled)

        if enabled {
            accessibilityGranted = Self.checkAccessibility(prompt: false)
            if !accessibilityGranted {
                showAccessibilityExplanation()
            }
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

        launchAtLogin = Self.isLoginItemEnabled

        if SMAppService.mainApp.status == .requiresApproval {
            showAlert(
                title: "Onay Gerekiyor",
                message: "MacScrollFix’i girişte başlatmak için Sistem Ayarları > Genel > Giriş Öğeleri bölümünde uygulamaya izin verin."
            )
        }
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

    private static var isLoginItemEnabled: Bool {
        let status = SMAppService.mainApp.status
        return status == .enabled || status == .requiresApproval
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

        let loginItemEnabledNow = Self.isLoginItemEnabled
        if loginItemEnabledNow != launchAtLogin {
            launchAtLogin = loginItemEnabledNow
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

    private func showAccessibilityExplanation() {
        guard !accessibilityGranted, !isShowingAlert else { return }
        isShowingAlert = true
        defer { isShowingAlert = false }

        let alert = NSAlert()
        alert.alertStyle = .informational
        alert.messageText = "Erişilebilirlik İzni Gerekli"
        alert.informativeText = """
        MacScrollFix yalnızca harici mouse tekerleği olaylarını düzeltebilmek için Erişilebilirlik iznine ihtiyaç duyar. İzin verilene kadar özellik kapalı kalır.
        """
        alert.addButton(withTitle: "Ayarları Aç")
        alert.addButton(withTitle: "Daha Sonra")

        NSApplication.shared.activate(ignoringOtherApps: true)
        if alert.runModal() == .alertFirstButtonReturn {
            openAccessibilitySettings()
        }
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

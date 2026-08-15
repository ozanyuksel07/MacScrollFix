import AppKit
import SwiftUI

@main
struct MacScrollFixApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var model = MacScrollFixModel.shared

    var body: some Scene {
        MenuBarExtra(
            isInserted: Binding(
                get: { model.menuBarIconVisible },
                set: { isVisible in
                    model.setMenuBarIconVisible(isVisible)
                }
            )
        ) {
            Toggle(
                "Kaydırma Düzeltmesi",
                isOn: Binding(
                    get: { model.isEnabled },
                    set: { model.setEnabled($0) }
                )
            )

            Text(model.statusText)
                .foregroundStyle(.secondary)

            Divider()

            Toggle(
                "Girişte Başlat",
                isOn: Binding(
                    get: { model.launchAtLoginState.isToggleOn },
                    set: { model.setLaunchAtLogin($0) }
                )
            )

            if let secondaryText = model.launchAtLoginState.secondaryText {
                Text(secondaryText)
                    .foregroundStyle(.secondary)
            }

            Divider()

            Button("Erişilebilirlik Ayarları…") {
                model.openAccessibilitySettings()
            }

            Button("Menü Çubuğundan Gizle") {
                model.requestMenuBarIconHide()
            }

            Divider()

            Button("Çıkış") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
        } label: {
            Image(systemName: model.isOperational ? "computermouse.fill" : "computermouse")
                .symbolRenderingMode(.monochrome)
                .opacity(model.isOperational ? 1 : 0.45)
                .accessibilityLabel(model.isOperational ? "MacScrollFix aktif" : "MacScrollFix kapalı")
        }
        .menuBarExtraStyle(.menu)
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        MacScrollFixModel.shared.applicationDidFinishLaunching()
    }

    func applicationWillTerminate(_ notification: Notification) {
        MacScrollFixModel.shared.shutdown()
    }

    func applicationShouldHandleReopen(
        _ sender: NSApplication,
        hasVisibleWindows flag: Bool
    ) -> Bool {
        // AppKit'in reopen layout işlemi tamamlandıktan sonra MenuBarExtra'yı yeniden ekle.
        DispatchQueue.main.async {
            MacScrollFixModel.shared.showMenuBarIcon()
        }
        return true
    }
}

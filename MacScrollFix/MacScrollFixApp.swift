import AppKit
import SwiftUI

@main
struct MacScrollFixApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var model = MacScrollFixModel.shared

    var body: some Scene {
        MenuBarExtra {
            Toggle(
                "Mouse Scroll Düzeltme",
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
                    get: { model.launchAtLogin },
                    set: { model.setLaunchAtLogin($0) }
                )
            )

            Button("Erişilebilirlik Ayarlarını Aç") {
                model.openAccessibilitySettings()
            }

            Divider()

            Button("MacScrollFix’ten Çık") {
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
}

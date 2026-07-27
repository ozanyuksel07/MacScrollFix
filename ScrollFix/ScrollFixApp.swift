import AppKit
import SwiftUI

@main
struct ScrollFixApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var model = ScrollFixModel.shared

    var body: some Scene {
        MenuBarExtra {
            Toggle(
                "Mouse Scroll Düzeltme",
                isOn: Binding(
                    get: { model.isEnabled },
                    set: { model.setEnabled($0) }
                )
            )

            Text(model.isOperational ? "Aktif" : "Kapalı")

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

            Button("ScrollFix’ten Çık") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
        } label: {
            Image(systemName: model.isOperational ? "computermouse.fill" : "computermouse")
                .symbolRenderingMode(.monochrome)
                .opacity(model.isOperational ? 1 : 0.45)
                .accessibilityLabel(model.isOperational ? "ScrollFix aktif" : "ScrollFix kapalı")
        }
        .menuBarExtraStyle(.menu)
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        ScrollFixModel.shared.applicationDidFinishLaunching()
    }

    func applicationWillTerminate(_ notification: Notification) {
        ScrollFixModel.shared.shutdown()
    }
}

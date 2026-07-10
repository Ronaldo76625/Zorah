import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        if ProcessInfo.processInfo.arguments.contains("--open-interpreter") {
            NSApp.setActivationPolicy(.regular)
            NSApp.activate(ignoringOtherApps: true)
        } else {
            NSApp.setActivationPolicy(.accessory)
        }
    }
}

@main
struct ZorahApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var model = AppModel()

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(
                model: model,
                speech: model.speech,
                clapDetector: model.clapDetector
            )
        } label: {
            StatusIcon(
                model: model,
                speech: model.speech,
                clapDetector: model.clapDetector
            )
        }
        .menuBarExtraStyle(.window)

        WindowGroup("Intérprete", id: "interpreter") {
            InterpreterView(
                model: model,
                speech: model.speech,
                history: model.history
            )
        }
        .defaultSize(width: 560, height: 520)
        .windowResizability(.contentMinSize)
        .defaultLaunchBehavior(
            ProcessInfo.processInfo.arguments.contains("--open-interpreter")
                ? .presented
                : .suppressed
        )

        Window("Historial", id: "history") {
            HistoryView(history: model.history)
        }
        .defaultSize(width: 480, height: 440)

        Settings {
            SettingsView(speech: model.speech)
        }
    }
}

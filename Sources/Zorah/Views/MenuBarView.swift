import AppKit
import SwiftUI

struct MenuBarView: View {
    @ObservedObject var model: AppModel
    @ObservedObject var speech: SpeechRecognitionService
    @ObservedObject var clapDetector: ClapDetectionService
    @Environment(\.openWindow) private var openWindow

    private var sourceLanguage: LanguageOption {
        let identifier = UserDefaults.standard.string(
            forKey: AppConstants.DefaultsKey.sourceLanguage
        ) ?? "es-MX"
        return LanguageOption.option(for: identifier, fallback: .supported[0])
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Image(systemName: model.status.systemImage)
                    .font(.title2)
                    .foregroundStyle(speech.isRecording ? Color.red : Color.accentColor)
                    .symbolEffect(.pulse, isActive: speech.isRecording)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Zorah")
                        .font(.headline)
                    Text(model.statusTitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Toggle(
                    "Activar",
                    isOn: Binding(
                        get: { model.isAssistantEnabled },
                        set: { model.setAssistantEnabled($0) }
                    )
                )
                    .labelsHidden()
                    .toggleStyle(.switch)
                    .help("Activar Zorah")
            }
            .padding(14)

            Divider()

            VStack(spacing: 8) {
                Button {
                    Task {
                        await model.toggleSpeech(locale: sourceLanguage.locale)
                    }
                } label: {
                    Label(
                        speech.isRecording ? "Detener escucha" : "Escuchar ahora",
                        systemImage: speech.isRecording ? "stop.fill" : "mic.fill"
                    )
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.borderless)
                .disabled(!model.isAssistantEnabled)

                Button {
                    openWindow(id: "interpreter")
                    NSApp.activate(ignoringOtherApps: true)
                } label: {
                    Label("Abrir Intérprete", systemImage: "character.bubble")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.borderless)

                Button {
                    openWindow(id: "history")
                    NSApp.activate(ignoringOtherApps: true)
                } label: {
                    Label("Historial", systemImage: "clock.arrow.circlepath")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.borderless)

                SettingsLink {
                    Label("Ajustes", systemImage: "gearshape")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.borderless)
            }
            .padding(14)

            if model.isAssistantEnabled {
                Divider()
                HStack {
                    Text(model.lastAction)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    if clapDetector.isCalibrating {
                        ProgressView()
                            .controlSize(.small)
                    } else if clapDetector.detectedClaps > 0 {
                        Text("\(clapDetector.detectedClaps)")
                            .font(.caption.monospacedDigit())
                    }
                }
                .padding(14)
            }

            if let error = speech.errorMessage {
                Divider()
                Label(error, systemImage: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(14)
            }

            if let error = clapDetector.errorMessage {
                Divider()
                Label(error, systemImage: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(14)
            }

            Divider()

            Button("Salir de Zorah") {
                NSApplication.shared.terminate(nil)
            }
            .buttonStyle(.borderless)
            .keyboardShortcut("q")
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(width: 280)
    }
}

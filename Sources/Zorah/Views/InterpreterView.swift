import AppKit
import SwiftUI
import Translation

struct InterpreterView: View {
    @ObservedObject var model: AppModel
    @ObservedObject var speech: SpeechRecognitionService
    @ObservedObject var history: TranslationHistoryStore
    @StateObject private var speechOutput = SpeechOutputService()

    @AppStorage(AppConstants.DefaultsKey.sourceLanguage) private var sourceLanguageID = "es-MX"
    @AppStorage(AppConstants.DefaultsKey.targetLanguage) private var targetLanguageID = "en-US"

    @State private var translation = ""
    @State private var translationConfiguration: TranslationSession.Configuration?
    @State private var configuredSourceID: String?
    @State private var configuredTargetID: String?
    @State private var isTranslating = false
    @State private var translationError: String?

    private var sourceLanguage: LanguageOption {
        LanguageOption.option(for: sourceLanguageID, fallback: .supported[0])
    }

    private var targetLanguage: LanguageOption {
        LanguageOption.option(for: targetLanguageID, fallback: .supported[1])
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                languagePicker(selection: $sourceLanguageID)

                Button {
                    swapLanguages()
                } label: {
                    Image(systemName: "arrow.left.arrow.right")
                }
                .buttonStyle(.borderless)
                .help("Intercambiar idiomas")

                languagePicker(selection: $targetLanguageID)
            }
            .padding(16)

            Divider()

            VStack(spacing: 12) {
                transcriptPane
                translationPane
            }
            .padding(16)

            Divider()

            HStack {
                Button {
                    speech.clear()
                    translation = ""
                    translationError = nil
                } label: {
                    Label("Limpiar", systemImage: "trash")
                }

                Spacer()

                Button {
                    requestTranslation()
                } label: {
                    Label("Traducir", systemImage: "character.bubble")
                }
                .disabled(speech.transcript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                Button {
                    Task {
                        await model.toggleSpeech(locale: sourceLanguage.locale)
                    }
                } label: {
                    Label(
                        speech.isRecording ? "Detener" : "Hablar",
                        systemImage: speech.isRecording ? "stop.fill" : "mic.fill"
                    )
                }
                .buttonStyle(.borderedProminent)
                .tint(speech.isRecording ? .red : .accentColor)
                .keyboardShortcut(.space, modifiers: [.command])
            }
            .padding(16)
        }
        .frame(minWidth: 500, minHeight: 460)
        .navigationTitle("Intérprete")
        .translationTask(translationConfiguration) { session in
            await performTranslation(using: session)
        }
        .onChange(of: speech.isRecording) { wasRecording, isRecording in
            if wasRecording && !isRecording && !speech.transcript.isEmpty {
                requestTranslation()
            }
        }
    }

    private var transcriptPane: some View {
        GroupBox {
            TextEditor(text: $speech.transcript)
                .font(.body)
                .scrollContentBackground(.hidden)
                .frame(maxWidth: .infinity, minHeight: 120)
        } label: {
            Label(sourceLanguage.name, systemImage: speech.isRecording ? "waveform" : "text.alignleft")
        }
    }

    private var translationPane: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 8) {
                ScrollView {
                    Text(translation.isEmpty ? "La traducción aparecerá aquí." : translation)
                        .foregroundStyle(translation.isEmpty ? .secondary : .primary)
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                        .textSelection(.enabled)
                }
                .frame(maxWidth: .infinity, minHeight: 120)

                if let translationError {
                    Label(translationError, systemImage: "exclamationmark.triangle")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }

                HStack {
                    if isTranslating {
                        ProgressView()
                            .controlSize(.small)
                    }
                    Spacer()
                    Button {
                        copyTranslation()
                    } label: {
                        Image(systemName: "doc.on.doc")
                    }
                    .buttonStyle(.borderless)
                    .disabled(translation.isEmpty)
                    .help("Copiar traducción")

                    Button {
                        speechOutput.speak(translation, languageIdentifier: targetLanguageID)
                    } label: {
                        Image(systemName: "speaker.wave.2")
                    }
                    .buttonStyle(.borderless)
                    .disabled(translation.isEmpty)
                    .help("Escuchar traducción")
                }
            }
        } label: {
            Label(targetLanguage.name, systemImage: "character.bubble")
        }
    }

    private func languagePicker(selection: Binding<String>) -> some View {
        Picker("Idioma", selection: selection) {
            ForEach(LanguageOption.supported) { language in
                Text(language.name).tag(language.id)
            }
        }
        .labelsHidden()
        .frame(maxWidth: .infinity)
    }

    private func requestTranslation() {
        guard !speech.transcript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        translationError = nil
        isTranslating = true

        if configuredSourceID == sourceLanguageID,
           configuredTargetID == targetLanguageID,
           translationConfiguration != nil {
            translationConfiguration?.invalidate()
        } else {
            configuredSourceID = sourceLanguageID
            configuredTargetID = targetLanguageID
            translationConfiguration = TranslationSession.Configuration(
                source: sourceLanguage.translationLanguage,
                target: targetLanguage.translationLanguage
            )
        }
    }

    private func performTranslation(using session: TranslationSession) async {
        do {
            let response = try await session.translate(speech.transcript)
            translation = response.targetText
            translationError = nil
            history.add(
                sourceText: speech.transcript,
                translatedText: response.targetText,
                sourceLanguage: sourceLanguage.name,
                targetLanguage: targetLanguage.name
            )
        } catch {
            if error.localizedDescription.localizedCaseInsensitiveContains("cancel") {
                translationError = "La traducción se canceló antes de completar la descarga de idiomas."
            } else {
                translationError = error.localizedDescription
            }
        }
        isTranslating = false
    }

    private func swapLanguages() {
        let previousSource = sourceLanguageID
        sourceLanguageID = targetLanguageID
        targetLanguageID = previousSource

        let previousTranscript = speech.transcript
        speech.transcript = translation
        translation = previousTranscript
        translationConfiguration = nil
        configuredSourceID = nil
        configuredTargetID = nil
    }

    private func copyTranslation() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(translation, forType: .string)
    }
}

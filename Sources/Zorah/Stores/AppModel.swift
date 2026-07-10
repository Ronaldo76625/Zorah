import Combine
import Foundation

@MainActor
final class AppModel: ObservableObject {
    @Published private(set) var isAssistantEnabled = false
    @Published private(set) var lastAction = "Lista para comenzar"

    let speech = SpeechRecognitionService()
    let clapDetector = ClapDetectionService()
    let history = TranslationHistoryStore()

    private let speechOutput = SpeechOutputService()
    private let music = MusicService()
    private let weather = WeatherService()
    private let globalHotKey = GlobalHotKeyService()
    private var hasGreeted = false
    private var cancellables: Set<AnyCancellable> = []

    init() {
        clapDetector.onGesture = { [weak self] count in
            Task { @MainActor in
                await self?.handleGesture(count)
            }
        }

        globalHotKey.onPressed = { [weak self] in
            guard let self else { return }
            let identifier = UserDefaults.standard.string(
                forKey: AppConstants.DefaultsKey.sourceLanguage
            ) ?? "es-MX"
            Task { @MainActor in
                await self.toggleSpeech(locale: Locale(identifier: identifier))
            }
        }

        speech.$isRecording
            .dropFirst()
            .removeDuplicates()
            .sink { [weak self] isRecording in
                guard let self, !isRecording, self.isAssistantEnabled else { return }
                Task {
                    await self.clapDetector.start()
                }
            }
            .store(in: &cancellables)
    }

    var status: AssistantStatus {
        if speech.errorMessage != nil || clapDetector.errorMessage != nil {
            return .error
        }
        if speech.isRecording || clapDetector.isListening {
            return .listening
        }
        if speech.isProcessing || clapDetector.isCalibrating {
            return .processing
        }
        return .idle
    }

    var statusTitle: String {
        if !isAssistantEnabled { return "En pausa" }
        if speech.isRecording { return "Transcribiendo" }
        if clapDetector.isCalibrating { return "Calibrando" }
        if clapDetector.isListening { return "Esperando aplausos" }
        return status.title
    }

    func setAssistantEnabled(_ enabled: Bool) {
        guard enabled != isAssistantEnabled else { return }
        isAssistantEnabled = enabled

        if enabled {
            lastAction = "Preparando micrófono"
            Task {
                await clapDetector.start()
                lastAction = clapDetector.errorMessage == nil ? "Esperando aplausos" : "Revisa el micrófono"
            }
        } else {
            clapDetector.stop()
            if speech.isRecording {
                speech.stopRecording()
            }
            lastAction = "Zorah está en pausa"
        }
    }

    func toggleSpeech(locale: Locale) async {
        if speech.isRecording {
            speech.stopRecording()
            return
        }

        clapDetector.stop()
        await speech.startRecording(locale: locale)
        if !speech.isRecording, isAssistantEnabled {
            await clapDetector.start()
        }
    }

    private func handleGesture(_ count: Int) async {
        clapDetector.stop()

        switch count {
        case 2:
            await handleDoubleClap()
        case 3:
            await handleTripleClap()
        case 4:
            lastAction = "Cuatro aplausos detectados"
            scheduleClapRestart(after: 0.5)
        default:
            scheduleClapRestart(after: 0.5)
        }
    }

    private func handleDoubleClap() async {
        if !hasGreeted {
            lastAction = "Consultando clima"
            let defaults = UserDefaults.standard
            let latitude = defaults.object(forKey: AppConstants.DefaultsKey.latitude) as? Double ?? 21.1619
            let longitude = defaults.object(forKey: AppConstants.DefaultsKey.longitude) as? Double ?? -86.8515
            let owner = defaults.string(forKey: AppConstants.DefaultsKey.ownerName) ?? "Ronaldo"
            let weatherSummary = await weather.currentSummary(latitude: latitude, longitude: longitude)
            let phrase = "\(greeting()) \(owner). Hoy \(weatherSummary). Enseguida pongo tu música."

            speechOutput.speak(phrase, languageIdentifier: "es-MX")
            await music.play(playlist: currentPlaylist())
            hasGreeted = true
            lastAction = "Saludo y música iniciados"
            scheduleClapRestart(after: speechDuration(for: phrase))
            return
        }

        switch await music.playerState() {
        case .playing:
            await music.pause()
            let phrase = "Pausando la música."
            speechOutput.speak(phrase, languageIdentifier: "es-MX")
            lastAction = "Música pausada"
            scheduleClapRestart(after: speechDuration(for: phrase))
        default:
            await music.resume()
            let phrase = "Reanudando."
            speechOutput.speak(phrase, languageIdentifier: "es-MX")
            lastAction = "Música reanudada"
            scheduleClapRestart(after: speechDuration(for: phrase))
        }
    }

    private func handleTripleClap() async {
        if await music.playerState() == .playing {
            await music.pause()
        }
        speechOutput.speak("Desactivando Zorah. Hasta luego.", languageIdentifier: "es-MX")
        isAssistantEnabled = false
        lastAction = "Zorah se desactivó"
    }

    private func scheduleClapRestart(after delay: TimeInterval) {
        guard isAssistantEnabled else { return }
        Task {
            try? await Task.sleep(for: .seconds(delay))
            guard isAssistantEnabled, !speech.isRecording else { return }
            await clapDetector.start()
            lastAction = "Esperando aplausos"
        }
    }

    private func greeting() -> String {
        switch Calendar.current.component(.hour, from: Date()) {
        case ..<12: "Buenos días"
        case ..<19: "Buenas tardes"
        default: "Buenas noches"
        }
    }

    private func currentPlaylist() -> String {
        let defaults = UserDefaults.standard
        switch Calendar.current.component(.hour, from: Date()) {
        case ..<12:
            return defaults.string(forKey: AppConstants.DefaultsKey.playlistMorning) ?? "Canciones favoritas"
        case ..<17:
            return defaults.string(forKey: AppConstants.DefaultsKey.playlistAfternoon) ?? "Quevedo Essentials"
        case ..<21:
            return defaults.string(forKey: AppConstants.DefaultsKey.playlistEvening) ?? "Babuni chill"
        default:
            return defaults.string(forKey: AppConstants.DefaultsKey.playlistNight) ?? "Canciones favoritas"
        }
    }

    private func speechDuration(for phrase: String) -> TimeInterval {
        max(2.0, Double(phrase.split(separator: " ").count) * 0.42)
    }
}

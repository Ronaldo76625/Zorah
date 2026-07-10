import AVFoundation
import Combine
import Foundation
import Speech

@MainActor
final class SpeechRecognitionService: ObservableObject {
    @Published var transcript = ""
    @Published private(set) var isRecording = false
    @Published private(set) var isProcessing = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var onDeviceRecognitionAvailable = false

    private let audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var silenceTimer: Timer?
    private var hasInstalledTap = false

    var status: AssistantStatus {
        if errorMessage != nil { return .error }
        if isRecording { return .listening }
        if isProcessing { return .processing }
        return .idle
    }

    func toggle(locale: Locale) async {
        if isRecording {
            stopRecording()
        } else {
            await startRecording(locale: locale)
        }
    }

    func startRecording(locale: Locale) async {
        guard !isRecording else { return }

        errorMessage = nil
        transcript = ""

        guard await requestPermissions() else { return }
        guard let recognizer = SFSpeechRecognizer(locale: locale) else {
            errorMessage = "El idioma seleccionado no admite transcripción."
            return
        }
        guard recognizer.isAvailable else {
            errorMessage = "El reconocimiento de voz no está disponible ahora."
            return
        }

        onDeviceRecognitionAvailable = recognizer.supportsOnDeviceRecognition
        let requiresLocal = UserDefaults.standard.object(
            forKey: AppConstants.DefaultsKey.requiresOnDeviceRecognition
        ) as? Bool ?? true

        if requiresLocal && !recognizer.supportsOnDeviceRecognition {
            errorMessage = "Este idioma no admite transcripción local en esta Mac."
            return
        }

        resetRecognitionSession(cancelTask: true)

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        request.taskHint = .dictation
        request.contextualStrings = ["Zorah"]
        request.requiresOnDeviceRecognition = requiresLocal
        recognitionRequest = request

        let inputNode = audioEngine.inputNode
        let format = inputNode.outputFormat(forBus: 0)
        guard format.sampleRate > 0, format.channelCount > 0 else {
            errorMessage = "No se pudo preparar el micrófono seleccionado."
            recognitionRequest = nil
            return
        }

        inputNode.installTap(onBus: 0, bufferSize: 1_024, format: format) { [weak request] buffer, _ in
            request?.append(buffer)
        }
        hasInstalledTap = true

        recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
            Task { @MainActor in
                self?.handleRecognition(result: result, error: error)
            }
        }

        do {
            audioEngine.prepare()
            try audioEngine.start()
            isRecording = true
        } catch {
            errorMessage = "No se pudo iniciar el micrófono: \(error.localizedDescription)"
            resetRecognitionSession(cancelTask: true)
        }
    }

    func stopRecording() {
        guard isRecording else { return }

        silenceTimer?.invalidate()
        silenceTimer = nil
        audioEngine.stop()
        if hasInstalledTap {
            audioEngine.inputNode.removeTap(onBus: 0)
            hasInstalledTap = false
        }
        recognitionRequest?.endAudio()
        isRecording = false
        isProcessing = !transcript.isEmpty
    }

    func clear() {
        if isRecording {
            resetRecognitionSession(cancelTask: true)
        }
        transcript = ""
        errorMessage = nil
        isProcessing = false
    }

    private func handleRecognition(result: SFSpeechRecognitionResult?, error: Error?) {
        if let result {
            transcript = result.bestTranscription.formattedString
            scheduleAutomaticStop()

            if result.isFinal {
                finishRecognition()
            }
        }

        if let error, !isRecording {
            isProcessing = false
            recognitionRequest = nil
            recognitionTask = nil
            if transcript.isEmpty {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func scheduleAutomaticStop() {
        let automaticallyStops = UserDefaults.standard.object(
            forKey: AppConstants.DefaultsKey.automaticallyStopsListening
        ) as? Bool ?? true
        guard automaticallyStops else { return }

        let timeout = UserDefaults.standard.object(
            forKey: AppConstants.DefaultsKey.silenceTimeout
        ) as? Double ?? 1.5

        silenceTimer?.invalidate()
        silenceTimer = Timer.scheduledTimer(withTimeInterval: timeout, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.stopRecording()
            }
        }
    }

    private func finishRecognition() {
        if isRecording {
            audioEngine.stop()
            if hasInstalledTap {
                audioEngine.inputNode.removeTap(onBus: 0)
                hasInstalledTap = false
            }
        }
        silenceTimer?.invalidate()
        silenceTimer = nil
        isRecording = false
        isProcessing = false
        recognitionRequest = nil
        recognitionTask = nil
    }

    private func resetRecognitionSession(cancelTask: Bool) {
        silenceTimer?.invalidate()
        silenceTimer = nil
        audioEngine.stop()
        if hasInstalledTap {
            audioEngine.inputNode.removeTap(onBus: 0)
            hasInstalledTap = false
        }
        recognitionRequest?.endAudio()
        if cancelTask {
            recognitionTask?.cancel()
        }
        recognitionRequest = nil
        recognitionTask = nil
        isRecording = false
        isProcessing = false
    }

    private func requestPermissions() async -> Bool {
        let speechAuthorized = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }

        guard speechAuthorized else {
            errorMessage = "Autoriza el reconocimiento de voz en Ajustes del Sistema."
            return false
        }

        let microphoneAuthorized: Bool
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            microphoneAuthorized = true
        case .notDetermined:
            microphoneAuthorized = await withCheckedContinuation { continuation in
                AVCaptureDevice.requestAccess(for: .audio) { allowed in
                    continuation.resume(returning: allowed)
                }
            }
        default:
            microphoneAuthorized = false
        }

        if !microphoneAuthorized {
            errorMessage = "Autoriza el micrófono para que Zorah pueda escucharte."
        }
        return microphoneAuthorized
    }
}

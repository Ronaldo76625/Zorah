import AVFoundation
import Combine
import Foundation

@MainActor
final class ClapDetectionService: ObservableObject {
    @Published private(set) var isListening = false
    @Published private(set) var isCalibrating = false
    @Published private(set) var detectedClaps = 0
    @Published private(set) var lastGesture: Int?
    @Published private(set) var errorMessage: String?

    var onGesture: ((Int) -> Void)?

    private let audioEngine = AVAudioEngine()
    private var calibrationLevels: [Float] = []
    private var threshold: Float = 0.12
    private var isAboveThreshold = false
    private var lastClapTime = Date.distantPast
    private var gestureTimer: Timer?
    private var hasInstalledTap = false

    private let calibrationFrameCount = 45
    private let thresholdMultiplier: Float = 3.5
    private let minimumGap: TimeInterval = 0.15

    func start() async {
        guard !isListening else { return }

        errorMessage = nil
        guard await requestMicrophonePermission() else {
            errorMessage = "Autoriza el micrófono para detectar aplausos."
            return
        }

        stopAudioEngine()
        calibrationLevels = []
        detectedClaps = 0
        isCalibrating = true
        isAboveThreshold = false

        let inputNode = audioEngine.inputNode
        let format = inputNode.outputFormat(forBus: 0)
        guard format.sampleRate > 0, format.channelCount > 0 else {
            isCalibrating = false
            errorMessage = "No se pudo preparar el micrófono."
            return
        }

        inputNode.installTap(onBus: 0, bufferSize: 1_024, format: format) { [weak self] buffer, _ in
            let level = Self.rms(of: buffer)
            Task { @MainActor in
                self?.process(level: level)
            }
        }
        hasInstalledTap = true

        do {
            audioEngine.prepare()
            try audioEngine.start()
            isListening = true
        } catch {
            errorMessage = "No se pudo iniciar la detección: \(error.localizedDescription)"
            stopAudioEngine()
            isCalibrating = false
        }
    }

    func stop() {
        gestureTimer?.invalidate()
        gestureTimer = nil
        detectedClaps = 0
        isCalibrating = false
        stopAudioEngine()
    }

    private func process(level: Float) {
        guard isListening else { return }

        if isCalibrating {
            calibrationLevels.append(level)
            if calibrationLevels.count >= calibrationFrameCount {
                let baseline = calibrationLevels.reduce(0, +) / Float(calibrationLevels.count)
                let configuredMinimum = Float(
                    UserDefaults.standard.object(
                        forKey: AppConstants.DefaultsKey.clapMinimumThreshold
                    ) as? Double ?? 0.12
                )
                threshold = max(baseline * thresholdMultiplier, configuredMinimum)
                calibrationLevels = []
                isCalibrating = false
            }
            return
        }

        if level > threshold {
            let now = Date()
            if !isAboveThreshold && now.timeIntervalSince(lastClapTime) >= minimumGap {
                detectedClaps += 1
                lastClapTime = now
                scheduleGestureCompletion()
            }
            isAboveThreshold = true
        } else if level < threshold * 0.55 {
            isAboveThreshold = false
        }
    }

    private func scheduleGestureCompletion() {
        gestureTimer?.invalidate()

        if detectedClaps >= 4 {
            completeGesture()
            return
        }

        let delay: TimeInterval = detectedClaps >= 3 ? 0.8 : 1.0
        gestureTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.completeGesture()
            }
        }
    }

    private func completeGesture() {
        let count = detectedClaps
        detectedClaps = 0
        gestureTimer?.invalidate()
        gestureTimer = nil

        guard count >= 2 else { return }
        lastGesture = count
        onGesture?(count)
    }

    private func stopAudioEngine() {
        audioEngine.stop()
        if hasInstalledTap {
            audioEngine.inputNode.removeTap(onBus: 0)
            hasInstalledTap = false
        }
        isListening = false
    }

    private func requestMicrophonePermission() async -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            return true
        case .notDetermined:
            return await withCheckedContinuation { continuation in
                AVCaptureDevice.requestAccess(for: .audio) { allowed in
                    continuation.resume(returning: allowed)
                }
            }
        default:
            return false
        }
    }

    nonisolated private static func rms(of buffer: AVAudioPCMBuffer) -> Float {
        guard let channel = buffer.floatChannelData?[0] else { return 0 }
        let frameCount = Int(buffer.frameLength)
        guard frameCount > 0 else { return 0 }

        var sum: Float = 0
        for index in 0..<frameCount {
            let sample = channel[index]
            sum += sample * sample
        }
        return sqrt(sum / Float(frameCount))
    }
}

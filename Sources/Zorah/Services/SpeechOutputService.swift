import AVFoundation
import Combine
import Foundation

@MainActor
final class SpeechOutputService: ObservableObject {
    private let synthesizer = AVSpeechSynthesizer()

    func speak(_ text: String, languageIdentifier: String) {
        guard !text.isEmpty else { return }

        synthesizer.stopSpeaking(at: .immediate)
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: languageIdentifier)
        synthesizer.speak(utterance)
    }
}

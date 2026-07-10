import SwiftUI

struct StatusIcon: View {
    @ObservedObject var model: AppModel
    @ObservedObject var speech: SpeechRecognitionService
    @ObservedObject var clapDetector: ClapDetectionService

    var body: some View {
        Image(systemName: model.isAssistantEnabled ? model.status.systemImage : "waveform.circle")
            .symbolEffect(.pulse, isActive: speech.isRecording || clapDetector.isListening)
            .accessibilityLabel("Zorah, \(model.statusTitle)")
    }
}

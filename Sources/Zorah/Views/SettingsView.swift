import SwiftUI

struct SettingsView: View {
    @ObservedObject var speech: SpeechRecognitionService

    @AppStorage(AppConstants.DefaultsKey.requiresOnDeviceRecognition)
    private var requiresOnDeviceRecognition = true
    @AppStorage(AppConstants.DefaultsKey.automaticallyStopsListening)
    private var automaticallyStopsListening = true
    @AppStorage(AppConstants.DefaultsKey.silenceTimeout)
    private var silenceTimeout = 1.5
    @AppStorage(AppConstants.DefaultsKey.clapMinimumThreshold)
    private var clapMinimumThreshold = 0.12
    @AppStorage(AppConstants.DefaultsKey.ownerName)
    private var ownerName = "Ronaldo"
    @AppStorage(AppConstants.DefaultsKey.latitude)
    private var latitude = 21.1619
    @AppStorage(AppConstants.DefaultsKey.longitude)
    private var longitude = -86.8515
    @AppStorage(AppConstants.DefaultsKey.playlistMorning)
    private var playlistMorning = "Canciones favoritas"
    @AppStorage(AppConstants.DefaultsKey.playlistAfternoon)
    private var playlistAfternoon = "Quevedo Essentials"
    @AppStorage(AppConstants.DefaultsKey.playlistEvening)
    private var playlistEvening = "Babuni chill"
    @AppStorage(AppConstants.DefaultsKey.playlistNight)
    private var playlistNight = "Canciones favoritas"
    @AppStorage(AppConstants.DefaultsKey.translationHistoryEnabled)
    private var translationHistoryEnabled = false

    var body: some View {
        TabView {
            generalSettings
                .tabItem { Label("General", systemImage: "person.crop.circle") }

            listeningSettings
                .tabItem { Label("Escucha", systemImage: "waveform") }

            musicSettings
                .tabItem { Label("Música", systemImage: "music.note") }
        }
        .padding(20)
        .frame(width: 520, height: 420)
    }

    private var generalSettings: some View {
        Form {
            Section("Perfil") {
                TextField("Nombre", text: $ownerName)
            }

            Section("Ubicación para el clima") {
                TextField("Latitud", value: $latitude, format: .number)
                TextField("Longitud", value: $longitude, format: .number)
            }
        }
        .formStyle(.grouped)
    }

    private var listeningSettings: some View {
        Form {
            Section("Privacidad") {
                Toggle("Transcripción solo en esta Mac", isOn: $requiresOnDeviceRecognition)
                Toggle("Guardar historial de texto", isOn: $translationHistoryEnabled)
                LabeledContent("Reconocimiento local") {
                    Text(speech.onDeviceRecognitionAvailable ? "Disponible" : "Se comprobará al escuchar")
                        .foregroundStyle(.secondary)
                }
            }

            Section("Transcripción") {
                Toggle("Finalizar al detectar silencio", isOn: $automaticallyStopsListening)
                LabeledContent("Tiempo de silencio") {
                    HStack {
                        Slider(value: $silenceTimeout, in: 0.8...3.0, step: 0.1)
                            .frame(width: 180)
                        Text("\(silenceTimeout, specifier: "%.1f") s")
                            .monospacedDigit()
                            .frame(width: 42, alignment: .trailing)
                    }
                }
                .disabled(!automaticallyStopsListening)
            }

            Section("Aplausos") {
                LabeledContent("Umbral mínimo") {
                    HStack {
                        Slider(value: $clapMinimumThreshold, in: 0.04...0.25, step: 0.01)
                            .frame(width: 180)
                        Text("\(clapMinimumThreshold, specifier: "%.2f")")
                            .monospacedDigit()
                            .frame(width: 42, alignment: .trailing)
                    }
                }
            }
        }
        .formStyle(.grouped)
    }

    private var musicSettings: some View {
        Form {
            Section("Playlists por horario") {
                TextField("Mañana", text: $playlistMorning)
                TextField("Tarde", text: $playlistAfternoon)
                TextField("Atardecer", text: $playlistEvening)
                TextField("Noche", text: $playlistNight)
            }
        }
        .formStyle(.grouped)
    }
}

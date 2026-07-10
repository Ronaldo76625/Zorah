import Foundation

enum AppConstants {
    static let name = "Zorah"
    static let bundleIdentifier = "com.ronaldo.zorah"

    enum DefaultsKey {
        static let requiresOnDeviceRecognition = "requiresOnDeviceRecognition"
        static let automaticallyStopsListening = "automaticallyStopsListening"
        static let silenceTimeout = "silenceTimeout"
        static let sourceLanguage = "sourceLanguage"
        static let targetLanguage = "targetLanguage"
        static let clapMinimumThreshold = "clapMinimumThreshold"
        static let ownerName = "ownerName"
        static let latitude = "latitude"
        static let longitude = "longitude"
        static let playlistMorning = "playlistMorning"
        static let playlistAfternoon = "playlistAfternoon"
        static let playlistEvening = "playlistEvening"
        static let playlistNight = "playlistNight"
        static let translationHistoryEnabled = "translationHistoryEnabled"
        static let translationHistory = "translationHistory"
    }
}

import Combine
import Foundation

@MainActor
final class TranslationHistoryStore: ObservableObject {
    @Published private(set) var records: [TranslationRecord] = []

    private let defaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        load()
    }

    func add(
        sourceText: String,
        translatedText: String,
        sourceLanguage: String,
        targetLanguage: String
    ) {
        guard defaults.bool(forKey: AppConstants.DefaultsKey.translationHistoryEnabled) else {
            return
        }

        let record = TranslationRecord(
            id: UUID(),
            createdAt: Date(),
            sourceText: sourceText,
            translatedText: translatedText,
            sourceLanguage: sourceLanguage,
            targetLanguage: targetLanguage
        )
        records.insert(record, at: 0)
        records = Array(records.prefix(100))
        save()
    }

    func clear() {
        records = []
        defaults.removeObject(forKey: AppConstants.DefaultsKey.translationHistory)
    }

    private func load() {
        guard let data = defaults.data(forKey: AppConstants.DefaultsKey.translationHistory),
              let stored = try? decoder.decode([TranslationRecord].self, from: data) else {
            return
        }
        records = stored
    }

    private func save() {
        guard let data = try? encoder.encode(records) else { return }
        defaults.set(data, forKey: AppConstants.DefaultsKey.translationHistory)
    }
}

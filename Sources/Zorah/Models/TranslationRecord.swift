import Foundation

struct TranslationRecord: Codable, Identifiable, Hashable {
    let id: UUID
    let createdAt: Date
    let sourceText: String
    let translatedText: String
    let sourceLanguage: String
    let targetLanguage: String
}

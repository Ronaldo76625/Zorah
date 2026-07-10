import Foundation

struct LanguageOption: Identifiable, Hashable {
    let id: String
    let name: String

    var locale: Locale {
        Locale(identifier: id)
    }

    var translationLanguage: Locale.Language {
        Locale.Language(identifier: id)
    }

    static let supported: [LanguageOption] = [
        LanguageOption(id: "es-MX", name: "Español"),
        LanguageOption(id: "en-US", name: "Inglés"),
        LanguageOption(id: "fr-FR", name: "Francés"),
        LanguageOption(id: "de-DE", name: "Alemán"),
        LanguageOption(id: "it-IT", name: "Italiano"),
        LanguageOption(id: "pt-BR", name: "Portugués")
    ]

    static func option(for identifier: String, fallback: LanguageOption) -> LanguageOption {
        supported.first(where: { $0.id == identifier }) ?? fallback
    }
}

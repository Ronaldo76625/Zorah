import SwiftUI

struct HistoryView: View {
    @ObservedObject var history: TranslationHistoryStore
    @State private var confirmsDeletion = false

    var body: some View {
        VStack(spacing: 0) {
            if history.records.isEmpty {
                ContentUnavailableView(
                    "Sin traducciones",
                    systemImage: "clock.arrow.circlepath"
                )
            } else {
                List(history.records) { record in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("\(record.sourceLanguage) → \(record.targetLanguage)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(record.createdAt, style: .time)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Text(record.sourceText)
                            .lineLimit(2)
                        Text(record.translatedText)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                    .padding(.vertical, 4)
                }
            }

            Divider()

            HStack {
                Spacer()
                Button("Borrar historial", role: .destructive) {
                    confirmsDeletion = true
                }
                .disabled(history.records.isEmpty)
            }
            .padding(12)
        }
        .frame(minWidth: 440, minHeight: 360)
        .confirmationDialog(
            "¿Borrar todo el historial?",
            isPresented: $confirmsDeletion
        ) {
            Button("Borrar historial", role: .destructive) {
                history.clear()
            }
        }
    }
}

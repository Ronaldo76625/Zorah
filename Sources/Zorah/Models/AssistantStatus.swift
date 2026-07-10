enum AssistantStatus: Equatable {
    case idle
    case listening
    case processing
    case error

    var title: String {
        switch self {
        case .idle: "Lista"
        case .listening: "Escuchando"
        case .processing: "Procesando"
        case .error: "Requiere atención"
        }
    }

    var systemImage: String {
        switch self {
        case .idle: "waveform.circle"
        case .listening: "waveform.circle.fill"
        case .processing: "ellipsis.circle"
        case .error: "exclamationmark.circle"
        }
    }
}

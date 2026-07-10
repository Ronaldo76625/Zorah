import Foundation

actor WeatherService {
    private struct Forecast: Decodable {
        let currentWeather: CurrentWeather

        enum CodingKeys: String, CodingKey {
            case currentWeather = "current_weather"
        }
    }

    private struct CurrentWeather: Decodable {
        let temperature: Double
        let weatherCode: Int

        enum CodingKeys: String, CodingKey {
            case temperature
            case weatherCode = "weathercode"
        }
    }

    func currentSummary(latitude: Double, longitude: Double) async -> String {
        var components = URLComponents(string: "https://api.open-meteo.com/v1/forecast")
        components?.queryItems = [
            URLQueryItem(name: "latitude", value: String(latitude)),
            URLQueryItem(name: "longitude", value: String(longitude)),
            URLQueryItem(name: "current_weather", value: "true")
        ]

        guard let url = components?.url else {
            return "no pude preparar la consulta del clima"
        }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse,
                  200..<300 ~= httpResponse.statusCode else {
                return "no pude verificar el clima en este momento"
            }
            let forecast = try JSONDecoder().decode(Forecast.self, from: data)
            let condition = condition(for: forecast.currentWeather.weatherCode)
            return "estamos a \(Int(forecast.currentWeather.temperature)) grados y el día está \(condition)"
        } catch {
            return "no pude verificar el clima en este momento"
        }
    }

    private func condition(for code: Int) -> String {
        switch code {
        case ...1: "despejado"
        case ...3: "nublado"
        case ...69: "con lluvia"
        case ...99: "con tormenta"
        default: "con clima variable"
        }
    }
}

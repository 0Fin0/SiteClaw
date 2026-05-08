//
//  RealtimeSessionService.swift
//  SiteClaw
//

import Foundation

struct RealtimeSessionResponse: Decodable, Hashable {
    var clientSecret: String?
    var expiresAt: Int?
    var model: String?
    var transcriptionModel: String?
    var voice: String?

    enum CodingKeys: String, CodingKey {
        case clientSecret = "client_secret"
        case expiresAt = "expires_at"
        case model
        case transcriptionModel = "transcription_model"
        case voice
    }
}

enum RealtimeSessionServiceError: LocalizedError {
    case invalidResponse
    case serverError(String)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            "The backend did not return a valid Realtime session response."
        case .serverError(let message):
            message
        }
    }
}

struct RealtimeSessionService {
    var endpoint = URL(string: "http://localhost:8787/api/realtime/session")!

    func createSession(restaurantName: String) async throws -> RealtimeSessionResponse {
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode([
            "restaurantName": restaurantName
        ])

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw RealtimeSessionServiceError.invalidResponse
        }

        if !(200..<300).contains(httpResponse.statusCode) {
            let serverError = try? JSONDecoder().decode(ServerErrorResponse.self, from: data)
            throw RealtimeSessionServiceError.serverError(serverError?.error ?? "Realtime session request failed.")
        }

        let decoded = try JSONDecoder().decode(RealtimeSessionResponse.self, from: data)
        guard decoded.clientSecret?.isEmpty == false else {
            throw RealtimeSessionServiceError.invalidResponse
        }

        return decoded
    }
}

private struct ServerErrorResponse: Decodable {
    var error: String
}

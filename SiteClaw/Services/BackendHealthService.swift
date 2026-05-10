//
//  BackendHealthService.swift
//  SiteClaw
//

import Foundation

struct BackendHealthResponse: Decodable, Hashable, Sendable {
    var ok: Bool
    var service: String
    var realtimeModel: String
    var realtimeTranscriptionModel: String
    var generationModel: String

    enum CodingKeys: String, CodingKey {
        case ok
        case service
        case realtimeModel = "realtime_model"
        case realtimeTranscriptionModel = "realtime_transcription_model"
        case generationModel = "generation_model"
    }
}

enum BackendHealthServiceError: LocalizedError {
    case invalidResponse
    case unhealthy

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            "The SiteClaw backend did not return a valid health response."
        case .unhealthy:
            "The SiteClaw backend is reachable, but it did not report a healthy status."
        }
    }
}

struct BackendHealthService {
    var endpoint = URL(string: "http://localhost:8787/health")!

    func checkHealth() async throws -> BackendHealthResponse {
        let (data, response) = try await URLSession.shared.data(from: endpoint)
        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            throw BackendHealthServiceError.invalidResponse
        }

        let decoded = try JSONDecoder().decode(BackendHealthResponse.self, from: data)
        guard decoded.ok else {
            throw BackendHealthServiceError.unhealthy
        }

        return decoded
    }
}

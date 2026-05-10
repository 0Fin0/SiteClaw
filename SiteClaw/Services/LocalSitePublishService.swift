//
//  LocalSitePublishService.swift
//  SiteClaw
//

import Foundation

struct LocalSitePublishResponse: Decodable, Hashable, Sendable {
    var ok: Bool
    var slug: String
    var url: String
    var htmlPath: String
    var jsonPath: String
    var byteCount: Int

    enum CodingKeys: String, CodingKey {
        case ok
        case slug
        case url
        case htmlPath = "html_path"
        case jsonPath = "json_path"
        case byteCount = "byte_count"
    }
}

struct LocalSitePublishRequest: Encodable, Sendable {
    var slug: String
    var html: String
    var restaurantJSON: RestaurantJSON

    enum CodingKeys: String, CodingKey {
        case slug
        case html
        case restaurantJSON = "restaurant_json"
    }
}

enum LocalSitePublishServiceError: LocalizedError {
    case invalidResponse
    case serverError(String)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            "The backend did not return a valid local site response."
        case .serverError(let message):
            message
        }
    }
}

struct LocalSitePublishService {
    var endpoint = URL(string: "http://localhost:8787/api/publish/local")!

    func publish(request payload: LocalSitePublishRequest) async throws -> LocalSitePublishResponse {
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(payload)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw LocalSitePublishServiceError.invalidResponse
        }

        if !(200..<300).contains(httpResponse.statusCode) {
            let serverError = try? JSONDecoder().decode(LocalSitePublishServerErrorResponse.self, from: data)
            throw LocalSitePublishServiceError.serverError(serverError?.error ?? "Local site publish failed.")
        }

        return try JSONDecoder().decode(LocalSitePublishResponse.self, from: data)
    }
}

private struct LocalSitePublishServerErrorResponse: Decodable {
    var error: String
}

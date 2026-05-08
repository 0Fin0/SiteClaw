//
//  SiteGenerationService.swift
//  SiteClaw
//

import Foundation

struct SiteGenerationResponse: Decodable, Hashable, Sendable {
    var reply: String
    var draft: SiteGeneratedDraft
    var model: String
    var source: String
}

struct SiteGeneratedDraft: Decodable, Hashable, Sendable {
    var headline: String
    var subheadline: String
    var callToAction: String
    var pages: [String]
    var seoKeywords: [String]
    var lastGeneratedSummary: String

    enum CodingKeys: String, CodingKey {
        case headline
        case subheadline
        case callToAction = "call_to_action"
        case pages
        case seoKeywords = "seo_keywords"
        case lastGeneratedSummary = "last_generated_summary"
    }
}

enum SiteGenerationServiceError: LocalizedError {
    case invalidResponse
    case serverError(String)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            "The backend did not return a valid generated draft response."
        case .serverError(let message):
            message
        }
    }
}

struct SiteGenerationService {
    var endpoint = URL(string: "http://localhost:8787/api/generate/draft")!

    func generateDraft(request payload: SiteGenerationRequest) async throws -> SiteGenerationResponse {
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let encoder = JSONEncoder()
        request.httpBody = try encoder.encode(payload)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw SiteGenerationServiceError.invalidResponse
        }

        if !(200..<300).contains(httpResponse.statusCode) {
            let serverError = try? JSONDecoder().decode(GenerationServerErrorResponse.self, from: data)
            throw SiteGenerationServiceError.serverError(serverError?.error ?? "Website draft generation failed.")
        }

        return try JSONDecoder().decode(SiteGenerationResponse.self, from: data)
    }
}

struct SiteGenerationRequest: Encodable, Sendable {
    var transcript: String
    var restaurant: SiteGenerationRestaurant
    var draft: SiteGenerationDraft
    var restaurantJSON: RestaurantJSON

    init(studio: SiteClawStudio) {
        transcript = studio.voiceTranscript
        restaurant = SiteGenerationRestaurant(profile: studio.restaurant)
        draft = SiteGenerationDraft(draft: studio.draft)
        restaurantJSON = studio.restaurantJSON
    }

    enum CodingKeys: String, CodingKey {
        case transcript
        case restaurant
        case draft
        case restaurantJSON = "restaurant_json"
    }
}

struct SiteGenerationRestaurant: Encodable, Sendable {
    var name: String
    var cuisine: String
    var neighborhood: String
    var ownerName: String
    var phone: String
    var hours: String
    var story: String
    var menuItems: [SiteGenerationMenuItem]

    init(profile: RestaurantProfile) {
        name = profile.name
        cuisine = profile.cuisine
        neighborhood = profile.neighborhood
        ownerName = profile.ownerName
        phone = profile.phone
        hours = profile.hours
        story = profile.story
        menuItems = profile.menuItems.map(SiteGenerationMenuItem.init)
    }

    enum CodingKeys: String, CodingKey {
        case name
        case cuisine
        case neighborhood
        case ownerName = "owner_name"
        case phone
        case hours
        case story
        case menuItems = "menu_items"
    }
}

struct SiteGenerationMenuItem: Encodable, Sendable {
    var name: String
    var description: String
    var price: Double

    init(item: MenuItem) {
        name = item.name
        description = item.description
        price = item.price
    }
}

struct SiteGenerationDraft: Encodable, Sendable {
    var headline: String
    var subheadline: String
    var callToAction: String
    var pages: [String]
    var seoKeywords: [String]
    var url: String
    var lastGeneratedSummary: String

    init(draft: WebsiteDraft) {
        headline = draft.headline
        subheadline = draft.subheadline
        callToAction = draft.callToAction
        pages = draft.pages
        seoKeywords = draft.seoKeywords
        url = draft.url
        lastGeneratedSummary = draft.lastGeneratedSummary
    }

    enum CodingKeys: String, CodingKey {
        case headline
        case subheadline
        case callToAction = "call_to_action"
        case pages
        case seoKeywords = "seo_keywords"
        case url
        case lastGeneratedSummary = "last_generated_summary"
    }
}

private struct GenerationServerErrorResponse: Decodable {
    var error: String
}

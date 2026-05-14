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
    var designBrief: RestaurantDesignBrief?
    var lastGeneratedSummary: String

    enum CodingKeys: String, CodingKey {
        case headline
        case subheadline
        case callToAction = "call_to_action"
        case pages
        case seoKeywords = "seo_keywords"
        case designBrief = "design_brief"
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

struct ProfileExtractionService {
    var endpoint = URL(string: "http://localhost:8787/api/extract/profile")!

    func extractProfile(request payload: ProfileExtractionRequest) async throws -> ProfileExtractionResponse {
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(payload)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw SiteGenerationServiceError.invalidResponse
        }

        if !(200..<300).contains(httpResponse.statusCode) {
            let serverError = try? JSONDecoder().decode(GenerationServerErrorResponse.self, from: data)
            throw SiteGenerationServiceError.serverError(serverError?.error ?? "Profile extraction failed.")
        }

        return try JSONDecoder().decode(ProfileExtractionResponse.self, from: data)
    }
}

struct VoiceCoachService {
    var endpoint = URL(string: "http://localhost:8787/api/ai/coach-turn")!

    func coachTurn(request payload: VoiceCoachRequest) async throws -> VoiceCoachResponse {
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(payload)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw SiteGenerationServiceError.invalidResponse
        }

        if !(200..<300).contains(httpResponse.statusCode) {
            let serverError = try? JSONDecoder().decode(GenerationServerErrorResponse.self, from: data)
            throw SiteGenerationServiceError.serverError(serverError?.error ?? "Voice coach failed.")
        }

        return try JSONDecoder().decode(VoiceCoachResponse.self, from: data)
    }
}

struct VoiceCoachRequest: Encodable, Sendable {
    var promptKind: String
    var question: String
    var rawAnswer: String
    var cleanedAnswer: String
    var capturedAnswers: [ProfileCapturedAnswer]
    var transcript: String
    var restaurant: SiteGenerationRestaurant
    var designBrief: RestaurantDesignBrief

    init(
        studio: SiteClawStudio,
        prompt: VoiceOnboardingPrompt,
        rawAnswer: String,
        cleanedAnswer: String
    ) {
        promptKind = prompt.promptKind.rawValue
        question = prompt.question
        self.rawAnswer = rawAnswer
        self.cleanedAnswer = cleanedAnswer
        capturedAnswers = studio.voicePrompts.map { prompt in
            ProfileCapturedAnswer(
                promptKind: prompt.promptKind.rawValue,
                question: prompt.question,
                answer: prompt.capturedAnswer
            )
        }
        transcript = VoiceTranscriptNormalizer.normalize(studio.voiceTranscript)
        restaurant = SiteGenerationRestaurant(profile: studio.restaurant)
        designBrief = studio.draft.designBrief.normalized
    }

    enum CodingKeys: String, CodingKey {
        case promptKind = "prompt_kind"
        case question
        case rawAnswer = "raw_answer"
        case cleanedAnswer = "cleaned_answer"
        case capturedAnswers = "captured_answers"
        case transcript
        case restaurant
        case designBrief = "design_brief"
    }
}

struct VoiceCoachResponse: Decodable, Hashable, Sendable {
    var cleanedAnswer: String
    var restaurantPatch: ProfileRestaurantPatch
    var confidence: VoiceCoachConfidence
    var missingDetails: [String]
    var suggestedFollowUp: String
    var archetypeHint: RestaurantSiteArchetype?
    var designNotes: [String]
    var statusMessage: String

    enum CodingKeys: String, CodingKey {
        case cleanedAnswer = "cleaned_answer"
        case restaurantPatch = "restaurant_patch"
        case confidence
        case missingDetails = "missing_details"
        case suggestedFollowUp = "suggested_follow_up"
        case archetypeHint = "archetype_hint"
        case designNotes = "design_notes"
        case statusMessage = "status_message"
    }
}

struct ProfileExtractionRequest: Encodable, Sendable {
    var transcript: String
    var capturedAnswers: [ProfileCapturedAnswer]
    var restaurant: SiteGenerationRestaurant

    init(studio: SiteClawStudio) {
        transcript = VoiceTranscriptNormalizer.normalize(studio.voiceTranscript)
        capturedAnswers = studio.voicePrompts.map { prompt in
            ProfileCapturedAnswer(
                promptKind: prompt.promptKind.rawValue,
                question: prompt.question,
                answer: prompt.capturedAnswer
            )
        }
        restaurant = SiteGenerationRestaurant(profile: studio.restaurant)
    }

    enum CodingKeys: String, CodingKey {
        case transcript
        case capturedAnswers = "captured_answers"
        case restaurant
    }
}

struct ProfileCapturedAnswer: Encodable, Hashable, Sendable {
    var promptKind: String
    var question: String
    var answer: String

    enum CodingKeys: String, CodingKey {
        case promptKind = "prompt_kind"
        case question
        case answer
    }
}

struct ProfileExtractionResponse: Decodable, Hashable, Sendable {
    var reply: String
    var restaurantPatch: ProfileRestaurantPatch
    var suggestedArchetype: RestaurantSiteArchetype?

    enum CodingKeys: String, CodingKey {
        case reply
        case restaurantPatch = "restaurant_patch"
        case suggestedArchetype = "suggested_archetype"
    }
}

struct ProfileRestaurantPatch: Decodable, Hashable, Sendable {
    var name: String
    var cuisine: String
    var neighborhood: String
    var hours: String
    var story: String
    var menuItems: [ProfileExtractionMenuItem]

    enum CodingKeys: String, CodingKey {
        case name
        case cuisine
        case neighborhood
        case hours
        case story
        case menuItems = "menu_items"
    }
}

struct ProfileExtractionMenuItem: Decodable, Hashable, Sendable {
    var name: String
    var description: String
    var price: Double?
}

struct SiteGenerationRequest: Encodable, Sendable {
    var transcript: String
    var restaurant: SiteGenerationRestaurant
    var draft: SiteGenerationDraft
    var restaurantJSON: RestaurantJSON
    var siteStrategy: SiteGenerationStrategy

    init(studio: SiteClawStudio) {
        transcript = VoiceTranscriptNormalizer.normalize(studio.voiceTranscript)
        restaurant = SiteGenerationRestaurant(profile: studio.restaurant)
        draft = SiteGenerationDraft(draft: studio.draft)
        restaurantJSON = studio.restaurantJSON
        siteStrategy = SiteGenerationStrategy(studio: studio)
    }

    enum CodingKeys: String, CodingKey {
        case transcript
        case restaurant
        case draft
        case restaurantJSON = "restaurant_json"
        case siteStrategy = "site_strategy"
    }
}

struct SiteGenerationRestaurant: Encodable, Sendable {
    var name: String
    var cuisine: String
    var neighborhood: String
    var streetAddress: String
    var state: String
    var postalCode: String
    var ownerName: String
    var phone: String
    var cateringEmail: String
    var hours: String
    var story: String
    var menuItems: [SiteGenerationMenuItem]
    var features: RestaurantSiteFeatures
    var growthTools: RestaurantGrowthTools

    init(profile: RestaurantProfile) {
        name = profile.name
        cuisine = profile.cuisine
        neighborhood = profile.neighborhood
        streetAddress = profile.streetAddress
        state = profile.state
        postalCode = profile.postalCode
        ownerName = profile.ownerName
        phone = profile.phone
        cateringEmail = profile.cateringEmail
        hours = profile.hours
        story = profile.story
        menuItems = profile.menuItems.map { SiteGenerationMenuItem(item: $0) }
        features = profile.features
        growthTools = profile.growthTools
    }

    enum CodingKeys: String, CodingKey {
        case name
        case cuisine
        case neighborhood
        case streetAddress = "street_address"
        case state
        case postalCode = "postal_code"
        case ownerName = "owner_name"
        case phone
        case cateringEmail = "catering_email"
        case hours
        case story
        case menuItems = "menu_items"
        case features
        case growthTools = "growth_tools"
    }
}

struct SiteGenerationMenuItem: Encodable, Sendable {
    var name: String
    var description: String
    var price: Double?

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
    var designBrief: RestaurantDesignBrief
    var url: String
    var lastGeneratedSummary: String

    init(draft: WebsiteDraft) {
        headline = draft.headline
        subheadline = draft.subheadline
        callToAction = draft.callToAction
        pages = draft.pages
        seoKeywords = draft.seoKeywords
        designBrief = draft.designBrief
        url = draft.url
        lastGeneratedSummary = draft.lastGeneratedSummary
    }

    enum CodingKeys: String, CodingKey {
        case headline
        case subheadline
        case callToAction = "call_to_action"
        case pages
        case seoKeywords = "seo_keywords"
        case designBrief = "design_brief"
        case url
        case lastGeneratedSummary = "last_generated_summary"
    }
}

struct SiteGenerationStrategy: Encodable, Sendable {
    var designDecisions: [String]
    var storyOpportunities: [String]
    var recommendedModules: [String]
    var voiceCoachNotes: [String]

    init(studio: SiteClawStudio) {
        designDecisions = studio.aiDesignDecisionSummary
        storyOpportunities = studio.draft.designBrief.storyOpportunities
        recommendedModules = studio.draft.designBrief.recommendedModules
        voiceCoachNotes = studio.voiceCoachTurns.flatMap(\.designNotes)
    }

    enum CodingKeys: String, CodingKey {
        case designDecisions = "design_decisions"
        case storyOpportunities = "story_opportunities"
        case recommendedModules = "recommended_modules"
        case voiceCoachNotes = "voice_coach_notes"
    }
}

private struct GenerationServerErrorResponse: Decodable {
    var error: String
}

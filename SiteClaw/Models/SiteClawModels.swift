//
//  SiteClawModels.swift
//  SiteClaw
//

import Foundation

struct RestaurantProfile: Hashable {
    var name: String
    var cuisine: String
    var neighborhood: String
    var ownerName: String
    var phone: String
    var hours: String
    var story: String
    var menuItems: [MenuItem]
}

struct MenuItem: Identifiable, Hashable {
    let id = UUID()
    var name: String
    var description: String
    var price: Double
}

struct WebsiteDraft: Hashable {
    var headline: String
    var subheadline: String
    var callToAction: String
    var pages: [String]
    var seoKeywords: [String]
    var url: String
    var lastGeneratedSummary: String
}

struct BuilderMessage: Identifiable, Hashable {
    enum Role: Hashable {
        case owner
        case assistant
    }

    let id = UUID()
    var role: Role
    var text: String
}

struct SiteUpdate: Identifiable, Hashable {
    enum UpdateType: String, Hashable {
        case hours = "Hours"
        case menu = "Menu"
        case announcement = "Announcement"
        case photo = "Photo"
        case publish = "Publish"
    }

    let id = UUID()
    var type: UpdateType
    var title: String
    var detail: String
    var timeLabel: String
}

struct DashboardMetric: Identifiable, Hashable {
    let id = UUID()
    var label: String
    var value: String
    var trend: String
    var systemImage: String
}

struct QuickUpdateTemplate: Identifiable, Hashable {
    let id = UUID()
    var title: String
    var prompt: String
    var systemImage: String
}

struct VoiceOnboardingPrompt: Identifiable, Hashable {
    let id = UUID()
    var question: String
    var capturedAnswer: String
    var systemImage: String
}

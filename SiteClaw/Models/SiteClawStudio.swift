//
//  SiteClawStudio.swift
//  SiteClaw
//

import Foundation
import Observation

@Observable
final class SiteClawStudio {
    var restaurant: RestaurantProfile
    var draft: WebsiteDraft
    var messages: [BuilderMessage]
    var updates: [SiteUpdate]
    var metrics: [DashboardMetric]
    var isPublished: Bool
    var isDraftGenerated: Bool
    var monthlyPrice: Int

    init(
        restaurant: RestaurantProfile,
        draft: WebsiteDraft,
        messages: [BuilderMessage],
        updates: [SiteUpdate],
        metrics: [DashboardMetric],
        isPublished: Bool = false,
        isDraftGenerated: Bool = true,
        monthlyPrice: Int = 19
    ) {
        self.restaurant = restaurant
        self.draft = draft
        self.messages = messages
        self.updates = updates
        self.metrics = metrics
        self.isPublished = isPublished
        self.isDraftGenerated = isDraftGenerated
        self.monthlyPrice = monthlyPrice
    }

    var publishStatus: String {
        isPublished ? "Live" : isDraftGenerated ? "Ready to publish" : "Draft needed"
    }

    var completionPercent: Int {
        var completed = 0
        completed += restaurant.name.isEmpty ? 0 : 1
        completed += restaurant.cuisine.isEmpty ? 0 : 1
        completed += restaurant.hours.isEmpty ? 0 : 1
        completed += restaurant.menuItems.isEmpty ? 0 : 1
        completed += isDraftGenerated ? 1 : 0
        return Int((Double(completed) / 5.0) * 100)
    }

    func generateDraft() {
        let restaurantName = restaurant.name.isEmpty ? "your restaurant" : restaurant.name
        let cuisine = restaurant.cuisine.isEmpty ? "local food" : restaurant.cuisine
        let neighborhood = restaurant.neighborhood.isEmpty ? "your neighborhood" : restaurant.neighborhood

        draft = WebsiteDraft(
            headline: "\(restaurantName) brings \(cuisine.lowercased()) to \(neighborhood)",
            subheadline: restaurant.story.isEmpty
                ? "Fresh food, clear hours, and a menu customers can trust before they visit."
                : restaurant.story,
            callToAction: "View Menu",
            pages: ["Home", "Menu", "Hours", "Location", "About"],
            seoKeywords: [restaurantName, cuisine, "\(neighborhood) restaurant", "best \(cuisine.lowercased()) near me"],
            url: slugURL(for: restaurantName),
            lastGeneratedSummary: "Generated a five-page restaurant site with menu, hours, local SEO, and mobile-ready content."
        )

        isDraftGenerated = true
        messages.append(
            BuilderMessage(
                role: .assistant,
                text: "I generated a restaurant website draft with your menu, hours, location, and local SEO pages. You can preview it now."
            )
        )
        addUpdate(
            type: .announcement,
            title: "Website draft generated",
            detail: "AI created a first version of the site from the owner conversation.",
            timeLabel: "Just now"
        )
    }

    func publishDraft() {
        isPublished = true
        addUpdate(
            type: .publish,
            title: "Site published",
            detail: "\(restaurant.name) is live at \(draft.url)",
            timeLabel: "Just now"
        )
    }

    func applyQuickUpdate(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let lowercased = trimmed.lowercased()
        let type: SiteUpdate.UpdateType

        if lowercased.contains("hour") || lowercased.contains("close") || lowercased.contains("open") {
            type = .hours
        } else if lowercased.contains("menu") || lowercased.contains("special") || lowercased.contains("price") {
            type = .menu
        } else if lowercased.contains("photo") || lowercased.contains("image") {
            type = .photo
        } else {
            type = .announcement
        }

        messages.append(BuilderMessage(role: .owner, text: trimmed))
        messages.append(BuilderMessage(role: .assistant, text: "Done. I turned that request into a website update and prepared it for publishing."))
        addUpdate(type: type, title: "Quick update prepared", detail: trimmed, timeLabel: "Just now")
    }

    func loadVoiceExample() {
        restaurant = RestaurantProfile.sample
        messages.append(
            BuilderMessage(
                role: .owner,
                text: "We are a family-owned Vietnamese restaurant in San Jose. Here is our menu, hours, and story. I need a simple site customers can trust."
            )
        )
        generateDraft()
    }

    private func addUpdate(type: SiteUpdate.UpdateType, title: String, detail: String, timeLabel: String) {
        updates.insert(
            SiteUpdate(type: type, title: title, detail: detail, timeLabel: timeLabel),
            at: 0
        )
    }

    private func slugURL(for name: String) -> String {
        let slug = name
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: "-")

        return "https://\(slug.isEmpty ? "restaurant" : slug).siteclaw.app"
    }
}

extension RestaurantProfile {
    static let empty = RestaurantProfile(
        name: "",
        cuisine: "",
        neighborhood: "",
        ownerName: "",
        phone: "",
        hours: "",
        story: "",
        menuItems: []
    )

    static let sample = RestaurantProfile(
        name: "Pho Lotus Kitchen",
        cuisine: "Vietnamese comfort food",
        neighborhood: "San Jose",
        ownerName: "Mai Nguyen",
        phone: "(408) 555-0148",
        hours: "Mon-Sat 11 AM-9 PM, Sun 11 AM-7 PM",
        story: "Family recipes, slow-simmered broth, and quick lunches for the neighborhood.",
        menuItems: [
            MenuItem(name: "House Pho", description: "Beef broth, rice noodles, brisket, herbs, lime.", price: 14.99),
            MenuItem(name: "Lemongrass Chicken Bowl", description: "Grilled chicken, jasmine rice, pickled vegetables.", price: 13.49),
            MenuItem(name: "Spring Rolls", description: "Shrimp, herbs, vermicelli, peanut dipping sauce.", price: 8.99)
        ]
    )
}

extension WebsiteDraft {
    static let placeholder = WebsiteDraft(
        headline: "Build a restaurant website by talking to SiteClaw",
        subheadline: "Capture the menu, hours, story, photos, and local SEO in one guided conversation.",
        callToAction: "Start Building",
        pages: ["Home", "Menu", "Hours"],
        seoKeywords: ["restaurant website", "local restaurant", "menu online"],
        url: "https://preview.siteclaw.app",
        lastGeneratedSummary: "No generated site yet. Add restaurant details or use the voice example."
    )

    static let sample = WebsiteDraft(
        headline: "Pho Lotus Kitchen brings Vietnamese comfort food to San Jose",
        subheadline: "Family recipes, slow-simmered broth, and quick lunches for the neighborhood.",
        callToAction: "View Menu",
        pages: ["Home", "Menu", "Hours", "Location", "About"],
        seoKeywords: ["Pho Lotus Kitchen", "Vietnamese comfort food", "San Jose restaurant", "best pho near me"],
        url: "https://pho-lotus-kitchen.siteclaw.app",
        lastGeneratedSummary: "Generated a mobile-first restaurant website with menu, hours, location, and local SEO content."
    )
}

extension SiteClawStudio {
    static let preview = SiteClawStudio(
        restaurant: .sample,
        draft: .sample,
        messages: [
            BuilderMessage(role: .assistant, text: "Tell me about your restaurant. You can type or use voice."),
            BuilderMessage(role: .owner, text: "We are a family-owned Vietnamese restaurant in San Jose with pho, rice bowls, and spring rolls."),
            BuilderMessage(role: .assistant, text: "Great. I can turn that into a mobile-friendly site with menu, hours, location, and local SEO.")
        ],
        updates: [
            SiteUpdate(type: .menu, title: "Menu imported", detail: "Added House Pho, Lemongrass Chicken Bowl, and Spring Rolls.", timeLabel: "8 min ago"),
            SiteUpdate(type: .hours, title: "Hours added", detail: "Mon-Sat 11 AM-9 PM, Sun 11 AM-7 PM.", timeLabel: "11 min ago")
        ],
        metrics: [
            DashboardMetric(label: "Completion", value: "92%", trend: "Ready for owner review", systemImage: "checkmark.seal.fill"),
            DashboardMetric(label: "Pages", value: "5", trend: "Home, Menu, Hours, Location, About", systemImage: "doc.text.fill"),
            DashboardMetric(label: "SEO Terms", value: "4", trend: "Local search phrases generated", systemImage: "magnifyingglass"),
            DashboardMetric(label: "Monthly Plan", value: "$19", trend: "Small operator pricing", systemImage: "creditcard.fill")
        ],
        isPublished: false,
        isDraftGenerated: true,
        monthlyPrice: 19
    )
}

extension QuickUpdateTemplate {
    static let samples: [QuickUpdateTemplate] = [
        QuickUpdateTemplate(
            title: "Update Hours",
            prompt: "We are closing at 8 PM tonight because of a private event.",
            systemImage: "clock.fill"
        ),
        QuickUpdateTemplate(
            title: "Add Special",
            prompt: "Add a weekend special: spicy garlic noodles for $12.99.",
            systemImage: "fork.knife"
        ),
        QuickUpdateTemplate(
            title: "Post Notice",
            prompt: "Tell customers we now accept catering orders for office lunches.",
            systemImage: "megaphone.fill"
        )
    ]
}

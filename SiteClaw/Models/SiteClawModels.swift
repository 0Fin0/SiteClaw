//
//  SiteClawModels.swift
//  SiteClaw
//

import Foundation
import CoreGraphics
import SwiftUI

struct RestaurantProfile: Hashable {
    var name: String
    var cuisine: String
    var neighborhood: String
    var streetAddress: String = ""
    var state: String = ""
    var postalCode: String = ""
    var ownerName: String
    var phone: String
    var cateringEmail: String = ""
    var hours: String
    var story: String
    var menuItems: [MenuItem]
    var uploadedMenu: UploadedMenuAsset? = nil
    var branding: SiteBrandingSettings = .demo
    var visibility: RestaurantVisibilitySettings = .demo
    var features: RestaurantSiteFeatures = .empty
    var growthTools: RestaurantGrowthTools = .recommended
}

extension RestaurantProfile {
    mutating func applyUploadedMenuAsset(_ asset: UploadedMenuAsset) -> UploadedMenuExtractionResult {
        uploadedMenu = asset
        let extraction = UploadedMenuItemExtractor.extractItems(from: asset)

        if extraction.didExtractItems {
            menuItems = extraction.items
        }

        return extraction
    }
}

struct MenuItem: Identifiable, Hashable {
    let id = UUID()
    var name: String
    var description: String
    var price: Double?
    var image: MenuItemImageAsset? = nil
}

struct MenuItemImageAsset: Hashable {
    var filename: String
    var mediaType: String
    var dataURL: String
    var byteCount: Int

    var sizeLabel: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useBytes]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(byteCount))
    }

    var portableAssetName: String {
        Self.portableAssetName(filename: filename, fallbackExtension: mediaType.contains("png") ? "png" : "jpg")
    }

    static func make(
        filename: String,
        mediaType: String,
        data: Data
    ) -> MenuItemImageAsset {
        MenuItemImageAsset(
            filename: filename,
            mediaType: mediaType,
            dataURL: "data:\(mediaType);base64,\(data.base64EncodedString())",
            byteCount: data.count
        )
    }

    static func portableAssetName(filename: String, fallbackExtension: String) -> String {
        let trimmed = filename.trimmingCharacters(in: .whitespacesAndNewlines)
        let base = trimmed.isEmpty ? "dish-photo.\(fallbackExtension)" : trimmed
        let sanitized = base
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: "-")
        return sanitized.isEmpty ? "dish-photo-\(UUID().uuidString).\(fallbackExtension)" : sanitized
    }
}

enum VoicePromptKind: String, Codable, Hashable, Sendable {
    case restaurantName = "restaurant_name"
    case cuisineLocation = "cuisine_location"
    case hours = "hours"
    case featuredDishes = "featured_dishes"
    case ownerStory = "owner_story"
    case custom
}

struct RestaurantVisibilitySettings: Codable, Hashable, Sendable {
    var googleBusinessProfileURL: String = ""
    var googleReviewURL: String = ""
    var yelpBusinessURL: String = ""
    var instagramURL: String = ""
    var facebookURL: String = ""
    var googleBusinessProfileClaimed: Bool = false
    var restaurantPhotosAdded: Bool = false
    var websiteLinkedOnProfiles: Bool = false

    static let demo = RestaurantVisibilitySettings()

    static let sunsetGrillDemo = RestaurantVisibilitySettings(
        googleBusinessProfileURL: "https://example.com/sunset-grill/google-business-profile",
        googleReviewURL: "https://example.com/sunset-grill/google-review",
        yelpBusinessURL: "https://example.com/sunset-grill/yelp",
        instagramURL: "https://example.com/sunset-grill/instagram",
        facebookURL: "https://example.com/sunset-grill/facebook",
        googleBusinessProfileClaimed: true,
        restaurantPhotosAdded: true,
        websiteLinkedOnProfiles: true
    )
}

struct RestaurantSiteFeatures: Codable, Hashable, Sendable {
    var onlineOrderingURL: String = ""
    var reservationURL: String = ""
    var giftCardURL: String = ""
    var cateringURL: String = ""
    var privateDiningURL: String = ""

    enum CodingKeys: String, CodingKey {
        case onlineOrderingURL = "online_ordering_url"
        case reservationURL = "reservation_url"
        case giftCardURL = "gift_card_url"
        case cateringURL = "catering_url"
        case privateDiningURL = "private_dining_url"
    }

    static let empty = RestaurantSiteFeatures()

    static let sunsetGrillDemo = RestaurantSiteFeatures(
        onlineOrderingURL: "https://example.com/sunset-grill/order",
        reservationURL: "https://example.com/sunset-grill/reservations",
        giftCardURL: "https://example.com/sunset-grill/gift-cards",
        cateringURL: "https://example.com/sunset-grill/catering",
        privateDiningURL: "https://example.com/sunset-grill/private-dining"
    )
}

struct RestaurantGrowthTools: Codable, Hashable, Sendable {
    var specialsEnabled: Bool = false
    var eventsEnabled: Bool = false
    var cateringLeadFormEnabled: Bool = true
    var giftCardsEnabled: Bool = false
    var reviewLinksEnabled: Bool = true
    var qrMenuEnabled: Bool = true
    var newsletterEnabled: Bool = false
    var analyticsEnabled: Bool = false

    enum CodingKeys: String, CodingKey {
        case specialsEnabled = "specials_enabled"
        case eventsEnabled = "events_enabled"
        case cateringLeadFormEnabled = "catering_lead_form_enabled"
        case giftCardsEnabled = "gift_cards_enabled"
        case reviewLinksEnabled = "review_links_enabled"
        case qrMenuEnabled = "qr_menu_enabled"
        case newsletterEnabled = "newsletter_enabled"
        case analyticsEnabled = "analytics_enabled"
    }

    static let recommended = RestaurantGrowthTools()

    static let fullyLoadedDemo = RestaurantGrowthTools(
        specialsEnabled: true,
        eventsEnabled: true,
        cateringLeadFormEnabled: true,
        giftCardsEnabled: true,
        reviewLinksEnabled: true,
        qrMenuEnabled: true,
        newsletterEnabled: true,
        analyticsEnabled: true
    )

    var enabledLabels: [String] {
        [
            specialsEnabled ? "Specials" : nil,
            eventsEnabled ? "Events" : nil,
            cateringLeadFormEnabled ? "Catering Leads" : nil,
            giftCardsEnabled ? "Gift Cards" : nil,
            reviewLinksEnabled ? "Review Links" : nil,
            qrMenuEnabled ? "QR Menu" : nil,
            newsletterEnabled ? "Newsletter" : nil,
            analyticsEnabled ? "Analytics" : nil
        ].compactMap { $0 }
    }
}

enum RestaurantSiteArchetype: String, CaseIterable, Codable, Hashable, Identifiable, Sendable {
    case neighborhoodUtility = "neighborhood_utility"
    case fastCasualOrderFirst = "fast_casual_order_first"
    case fineDiningReservationFirst = "fine_dining_reservation_first"
    case culturalHeritage = "cultural_heritage"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .neighborhoodUtility:
            "Neighborhood"
        case .fastCasualOrderFirst:
            "Order First"
        case .fineDiningReservationFirst:
            "Fine Dining"
        case .culturalHeritage:
            "Heritage"
        }
    }

    var detail: String {
        switch self {
        case .neighborhoodUtility:
            "Clear menu, hours, call, and directions for everyday local visitors."
        case .fastCasualOrderFirst:
            "Bold ordering path with best sellers and immediate takeout energy."
        case .fineDiningReservationFirst:
            "Restrained, reservation-led flow for premium or chef-driven dining."
        case .culturalHeritage:
            "Story-rich direction for regional, family, or signature-product restaurants."
        }
    }

    var defaultPrimaryCTA: String {
        switch self {
        case .neighborhoodUtility:
            "View Menu"
        case .fastCasualOrderFirst:
            "Order Online"
        case .fineDiningReservationFirst:
            "Reserve a Table"
        case .culturalHeritage:
            "View Menu"
        }
    }

    var defaultSecondaryCTAs: [String] {
        switch self {
        case .neighborhoodUtility:
            ["Call Now", "Get Directions"]
        case .fastCasualOrderFirst:
            ["View Menu", "Get Directions"]
        case .fineDiningReservationFirst:
            ["View Menu", "Private Dining"]
        case .culturalHeritage:
            ["Order Online", "Visit Us"]
        }
    }

    var defaultSiteSections: [String] {
        switch self {
        case .neighborhoodUtility:
            ["Hero", "Featured Dishes", "Visit", "Story"]
        case .fastCasualOrderFirst:
            ["Hero", "Best Sellers", "Order Options", "Menu", "Visit"]
        case .fineDiningReservationFirst:
            ["Hero", "Reservations", "Experience", "Menu", "Visit"]
        case .culturalHeritage:
            ["Hero", "Signature Dishes", "Heritage Story", "Menu", "Visit"]
        }
    }

    var defaultMenuPresentation: String {
        switch self {
        case .neighborhoodUtility:
            "practical_cards"
        case .fastCasualOrderFirst:
            "visual_product_cards"
        case .fineDiningReservationFirst:
            "curated_minimal"
        case .culturalHeritage:
            "featured_with_story_notes"
        }
    }

    var defaultVisualDirection: RestaurantVisualDirection {
        switch self {
        case .neighborhoodUtility:
            RestaurantVisualDirection(density: "medium", tone: "warm_local", motion: "minimal")
        case .fastCasualOrderFirst:
            RestaurantVisualDirection(density: "high", tone: "playful_direct", motion: "light_playful")
        case .fineDiningReservationFirst:
            RestaurantVisualDirection(density: "low", tone: "quiet_luxury", motion: "subtle")
        case .culturalHeritage:
            RestaurantVisualDirection(density: "medium", tone: "rooted_expressive", motion: "minimal")
        }
    }

    static func suggested(for restaurant: RestaurantProfile) -> RestaurantSiteArchetype {
        let searchable = [
            restaurant.cuisine,
            restaurant.story,
            restaurant.draftIntentText,
            restaurant.menuItems.map(\.name).joined(separator: " ")
        ]
            .joined(separator: " ")
            .lowercased()

        if !restaurant.features.onlineOrderingURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || searchable.contains("takeout")
            || searchable.contains("delivery")
            || searchable.contains("pizza")
            || searchable.contains("taco")
            || searchable.contains("burger")
            || searchable.contains("bowls")
            || searchable.contains("coffee")
            || searchable.contains("bakery")
            || searchable.contains("ice cream") {
            return .fastCasualOrderFirst
        }

        if !restaurant.features.reservationURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || searchable.contains("fine dining")
            || searchable.contains("tasting menu")
            || searchable.contains("chef")
            || searchable.contains("reservation")
            || searchable.contains("private dining") {
            return .fineDiningReservationFirst
        }

        if searchable.contains("family recipe")
            || searchable.contains("heritage")
            || searchable.contains("tradition")
            || searchable.contains("regional")
            || searchable.contains("authentic")
            || searchable.contains("argentinian")
            || searchable.contains("mexican")
            || searchable.contains("vietnamese")
            || searchable.contains("thai")
            || searchable.contains("italian") {
            return .culturalHeritage
        }

        return .neighborhoodUtility
    }
}

enum RestaurantPreviewSection: String, CaseIterable, Hashable, Sendable {
    case story
    case menu
    case visit

    var displayName: String {
        switch self {
        case .story:
            "Story"
        case .menu:
            "Menu"
        case .visit:
            "Visit"
        }
    }
}

struct RestaurantArchetypePreviewSpec: Hashable, Sendable {
    var archetype: RestaurantSiteArchetype
    var heroKicker: String
    var storyHeading: String
    var menuHeading: String
    var primaryCTA: String
    var sectionOrder: [RestaurantPreviewSection]

    static func spec(for archetype: RestaurantSiteArchetype) -> RestaurantArchetypePreviewSpec {
        switch archetype {
        case .neighborhoodUtility:
            RestaurantArchetypePreviewSpec(
                archetype: archetype,
                heroKicker: "Neighborhood favorite",
                storyHeading: "Why Customers Visit",
                menuHeading: "Featured Dishes",
                primaryCTA: "View Menu",
                sectionOrder: [.story, .menu, .visit]
            )
        case .fastCasualOrderFirst:
            RestaurantArchetypePreviewSpec(
                archetype: archetype,
                heroKicker: "Order ahead",
                storyHeading: "Made For Right Now",
                menuHeading: "Best Sellers",
                primaryCTA: "Order Online",
                sectionOrder: [.menu, .story, .visit]
            )
        case .fineDiningReservationFirst:
            RestaurantArchetypePreviewSpec(
                archetype: archetype,
                heroKicker: "Reservations",
                storyHeading: "The Experience",
                menuHeading: "Menu",
                primaryCTA: "Reserve a Table",
                sectionOrder: [.story, .visit, .menu]
            )
        case .culturalHeritage:
            RestaurantArchetypePreviewSpec(
                archetype: archetype,
                heroKicker: "Rooted in tradition",
                storyHeading: "Our Roots",
                menuHeading: "Signature Dishes",
                primaryCTA: "View Menu",
                sectionOrder: [.story, .menu, .visit]
            )
        }
    }
}

private extension RestaurantProfile {
    var draftIntentText: String {
        [
            features.reservationURL.isEmpty ? "" : "reservation",
            features.onlineOrderingURL.isEmpty ? "" : "online ordering",
            features.privateDiningURL.isEmpty ? "" : "private dining",
            features.cateringURL.isEmpty ? "" : "catering",
            features.giftCardURL.isEmpty ? "" : "gift cards"
        ]
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }
}

struct RestaurantVisualDirection: Codable, Hashable, Sendable {
    var density: String
    var tone: String
    var motion: String
}

struct RestaurantDesignBrief: Codable, Hashable, Sendable {
    var archetype: String
    var primaryCTA: String
    var secondaryCTAs: [String]
    var siteSections: [String]
    var menuPresentation: String
    var visualDirection: RestaurantVisualDirection
    var designDecisions: [String]
    var storyOpportunities: [String]
    var recommendedModules: [String]

    enum CodingKeys: String, CodingKey {
        case archetype
        case primaryCTA = "primary_cta"
        case secondaryCTAs = "secondary_ctas"
        case siteSections = "site_sections"
        case menuPresentation = "menu_presentation"
        case visualDirection = "visual_direction"
        case designDecisions = "design_decisions"
        case storyOpportunities = "story_opportunities"
        case recommendedModules = "recommended_modules"
    }

    init(
        archetype: RestaurantSiteArchetype,
        primaryCTA: String? = nil,
        secondaryCTAs: [String]? = nil,
        siteSections: [String]? = nil,
        menuPresentation: String? = nil,
        visualDirection: RestaurantVisualDirection? = nil,
        designDecisions: [String] = [],
        storyOpportunities: [String] = [],
        recommendedModules: [String] = []
    ) {
        self.archetype = archetype.rawValue
        self.primaryCTA = primaryCTA ?? archetype.defaultPrimaryCTA
        self.secondaryCTAs = secondaryCTAs ?? archetype.defaultSecondaryCTAs
        self.siteSections = siteSections ?? archetype.defaultSiteSections
        self.menuPresentation = menuPresentation ?? archetype.defaultMenuPresentation
        self.visualDirection = visualDirection ?? archetype.defaultVisualDirection
        self.designDecisions = Self.cleanedList(designDecisions)
        self.storyOpportunities = Self.cleanedList(storyOpportunities)
        self.recommendedModules = Self.cleanedList(recommendedModules)
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        archetype = try container.decodeIfPresent(String.self, forKey: .archetype)
            ?? RestaurantSiteArchetype.neighborhoodUtility.rawValue
        let resolvedArchetype = RestaurantSiteArchetype(rawValue: archetype) ?? .neighborhoodUtility
        primaryCTA = try container.decodeIfPresent(String.self, forKey: .primaryCTA)
            ?? resolvedArchetype.defaultPrimaryCTA
        secondaryCTAs = try container.decodeIfPresent([String].self, forKey: .secondaryCTAs)
            ?? resolvedArchetype.defaultSecondaryCTAs
        siteSections = try container.decodeIfPresent([String].self, forKey: .siteSections)
            ?? resolvedArchetype.defaultSiteSections
        menuPresentation = try container.decodeIfPresent(String.self, forKey: .menuPresentation)
            ?? resolvedArchetype.defaultMenuPresentation
        visualDirection = try container.decodeIfPresent(RestaurantVisualDirection.self, forKey: .visualDirection)
            ?? resolvedArchetype.defaultVisualDirection
        designDecisions = Self.cleanedList(try container.decodeIfPresent([String].self, forKey: .designDecisions) ?? [])
        storyOpportunities = Self.cleanedList(try container.decodeIfPresent([String].self, forKey: .storyOpportunities) ?? [])
        recommendedModules = Self.cleanedList(try container.decodeIfPresent([String].self, forKey: .recommendedModules) ?? [])
    }

    var resolvedArchetype: RestaurantSiteArchetype {
        RestaurantSiteArchetype(rawValue: archetype) ?? .neighborhoodUtility
    }

    var normalized: RestaurantDesignBrief {
        let archetype = resolvedArchetype
        return RestaurantDesignBrief(
            archetype: archetype,
            primaryCTA: primaryCTA.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : primaryCTA,
            secondaryCTAs: secondaryCTAs.isEmpty ? nil : secondaryCTAs,
            siteSections: siteSections.isEmpty ? nil : siteSections,
            menuPresentation: menuPresentation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : menuPresentation,
            visualDirection: visualDirection,
            designDecisions: designDecisions,
            storyOpportunities: storyOpportunities,
            recommendedModules: recommendedModules
        )
    }

    static let fallback = RestaurantDesignBrief(archetype: .neighborhoodUtility)

    private static func cleanedList(_ values: [String]) -> [String] {
        values.reduce(into: [String]()) { result, value in
            let cleaned = value.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !cleaned.isEmpty,
                  !result.contains(where: { $0.caseInsensitiveCompare(cleaned) == .orderedSame })
            else { return }
            result.append(cleaned)
        }
    }
}

struct VisibilityChecklistItem: Identifiable, Hashable {
    var id: String { title }
    var title: String
    var detail: String
    var isComplete: Bool
    var systemImage: String
}

struct RestaurantExternalProfileLink: Identifiable, Hashable {
    var id: String { url }
    var title: String
    var url: String
}

enum UploadedMenuAssetKind: String, Hashable {
    case pdf
    case image
}

struct UploadedMenuAsset: Identifiable, Hashable {
    let id = UUID()
    var filename: String
    var mediaType: String
    var kind: UploadedMenuAssetKind
    var dataURL: String
    var byteCount: Int

    var sizeLabel: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useBytes]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(byteCount))
    }

    var portableAssetName: String {
        MenuItemImageAsset.portableAssetName(
            filename: filename,
            fallbackExtension: kind == .pdf ? "pdf" : "png"
        )
    }

    static func make(
        filename: String,
        mediaType: String,
        kind: UploadedMenuAssetKind,
        data: Data
    ) -> UploadedMenuAsset {
        UploadedMenuAsset(
            filename: filename,
            mediaType: mediaType,
            kind: kind,
            dataURL: "data:\(mediaType);base64,\(data.base64EncodedString())",
            byteCount: data.count
        )
    }

    static var sunsetGrillDemo: UploadedMenuAsset {
        return UploadedMenuAsset.make(
            filename: sunsetGrillDemoFilename,
            mediaType: "image/png",
            kind: .image,
            data: sunsetGrillDemoData
        )
    }

    static let sunsetGrillDemoFilename = "sunset-grill-demo-menu.png"

    var isSunsetGrillDemo: Bool {
        filename == Self.sunsetGrillDemoFilename && mediaType == "image/png"
    }

    private static var sunsetGrillDemoData: Data {
        for bundle in candidateBundles {
            if let data = data(named: "sunset-grill-demo-menu", extension: "png", in: bundle) {
                return data
            }
        }

        assertionFailure("Missing bundled Sunset Grill demo menu image.")
        return Data()
    }

    private static var candidateBundles: [Bundle] {
        [Bundle.main, Bundle(for: UploadedMenuAssetBundleToken.self)] + Bundle.allBundles + Bundle.allFrameworks
    }

    private static func data(named resourceName: String, extension resourceExtension: String, in bundle: Bundle) -> Data? {
        for subdirectory in [nil, "Resources"] as [String?] {
            guard let url = bundle.url(
                forResource: resourceName,
                withExtension: resourceExtension,
                subdirectory: subdirectory
            ),
            let data = try? Data(contentsOf: url) else {
                continue
            }

            return data
        }

        return nil
    }
}

private final class UploadedMenuAssetBundleToken {}

struct UploadedMenuExtractionResult: Hashable {
    var items: [MenuItem]
    var statusMessage: String

    var didExtractItems: Bool {
        !items.isEmpty
    }
}

enum UploadedMenuItemExtractor {
    static func extractItems(from asset: UploadedMenuAsset) -> UploadedMenuExtractionResult {
        if asset.isSunsetGrillDemo {
            return UploadedMenuExtractionResult(
                items: sunsetGrillDemoFeaturedItems,
                statusMessage: "Demo menu loaded; featured burgers and sandwiches were added."
            )
        }

        guard asset.kind == .image,
              asset.mediaType.localizedCaseInsensitiveContains("svg"),
              let svg = decodedText(from: asset) else {
            return UploadedMenuExtractionResult(
                items: [],
                statusMessage: "Menu uploaded; structured extraction coming soon."
            )
        }

        let textNodes = SVGTextNodeParser.textNodes(from: svg)
        let featuredItems = featuredItems(
            from: textNodes,
            sectionTitle: "BURGERS & SANDWICHES",
            restaurantName: "Sunset Grill",
            cuisine: "American restaurant"
        )

        guard !featuredItems.isEmpty else {
            return UploadedMenuExtractionResult(
                items: [],
                statusMessage: "Menu uploaded; structured extraction coming soon."
            )
        }

        return UploadedMenuExtractionResult(
            items: featuredItems,
            statusMessage: "Demo menu loaded; featured burgers and sandwiches were added."
        )
    }

    private static var sunsetGrillDemoFeaturedItems: [MenuItem] {
        [
            MenuItem(
                name: "Sunset Smash Burger",
                description: MenuDescriptionPolisher.defaultDescription(
                    for: "Sunset Smash Burger",
                    cuisine: "American restaurant",
                    restaurantName: "Sunset Grill"
                ),
                price: 17
            ),
            MenuItem(
                name: "BBQ Bacon Cheeseburger",
                description: MenuDescriptionPolisher.defaultDescription(
                    for: "BBQ Bacon Cheeseburger",
                    cuisine: "American restaurant",
                    restaurantName: "Sunset Grill"
                ),
                price: 18
            ),
            MenuItem(
                name: "Crispy Chicken Sandwich",
                description: MenuDescriptionPolisher.defaultDescription(
                    for: "Crispy Chicken Sandwich",
                    cuisine: "American restaurant",
                    restaurantName: "Sunset Grill"
                ),
                price: 16
            ),
            MenuItem(
                name: "Grilled Mahi Sandwich",
                description: MenuDescriptionPolisher.defaultDescription(
                    for: "Grilled Mahi Sandwich",
                    cuisine: "American restaurant",
                    restaurantName: "Sunset Grill"
                ),
                price: 18
            )
        ]
    }

    private static func decodedText(from asset: UploadedMenuAsset) -> String? {
        guard let base64 = asset.dataURL.components(separatedBy: "base64,").last,
              let data = Data(base64Encoded: base64) else {
            return nil
        }

        return String(data: data, encoding: .utf8)
    }

    private static func featuredItems(
        from textNodes: [String],
        sectionTitle: String,
        restaurantName: String,
        cuisine: String
    ) -> [MenuItem] {
        guard let sectionIndex = textNodes.firstIndex(where: { normalizedSectionTitle($0) == sectionTitle }) else {
            return []
        }

        var items: [MenuItem] = []
        var pendingName: String?
        let stopTitles: Set<String> = [
            "STARTERS",
            "SOUPS & SALADS",
            "SIDES",
            "TACOS & HANDHELDS",
            "ENTREES",
            "COCKTAILS",
            "DRAFT BEER",
            "NON-ALCOHOLIC"
        ]

        for text in textNodes.dropFirst(sectionIndex + 1) {
            let normalized = normalizedSectionTitle(text)
            if stopTitles.contains(normalized) || text.localizedCaseInsensitiveContains("served with") {
                break
            }

            if let price = price(from: text), let name = pendingName {
                items.append(
                    MenuItem(
                        name: name,
                        description: MenuDescriptionPolisher.defaultDescription(
                            for: name,
                            cuisine: cuisine,
                            restaurantName: restaurantName
                        ),
                        price: price
                    )
                )
                pendingName = nil

                if items.count == 4 {
                    break
                }
            } else if !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                pendingName = text
            }
        }

        return items
    }

    private static func price(from text: String) -> Double? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.range(of: #"^\d+(\.\d{1,2})?$"#, options: .regularExpression) != nil else {
            return nil
        }

        return Double(trimmed)
    }

    private static func normalizedSectionTitle(_ text: String) -> String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .uppercased()
    }
}

private final class SVGTextNodeParser: NSObject, XMLParserDelegate {
    private var textNodes: [String] = []
    private var isCollectingText = false
    private var currentText = ""

    static func textNodes(from svg: String) -> [String] {
        guard let data = svg.data(using: .utf8) else { return [] }

        let parser = XMLParser(data: data)
        let delegate = SVGTextNodeParser()
        parser.delegate = delegate
        parser.parse()
        return delegate.textNodes
    }

    func parser(
        _ parser: XMLParser,
        didStartElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?,
        attributes attributeDict: [String: String] = [:]
    ) {
        guard elementName == "text" else { return }
        isCollectingText = true
        currentText = ""
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        guard isCollectingText else { return }
        currentText += string
    }

    func parser(
        _ parser: XMLParser,
        didEndElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?
    ) {
        guard elementName == "text" else { return }
        let trimmed = currentText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            textNodes.append(trimmed)
        }
        isCollectingText = false
        currentText = ""
    }
}

enum MenuDescriptionPolisher {
    static func defaultDescription(for itemName: String, cuisine: String, restaurantName: String) -> String {
        let name = itemName.trimmingCharacters(in: .whitespacesAndNewlines)
        let key = MissingDetailAnswerExtractor.menuKey(name)
        let restaurant = restaurantName.trimmingCharacters(in: .whitespacesAndNewlines)
        let place = restaurant.isEmpty ? "the menu" : "\(restaurant)'s menu"
        let restaurantLabel = restaurant.isEmpty ? "the restaurant" : restaurant

        if key.contains("smashburger") {
            return "A signature smash burger with crisp edges, melty cheese, and casual grill flavor."
        }

        if key.contains("bacon") && key.contains("cheeseburger") {
            return "A bacon cheeseburger built for guests who want a bigger, smoky bite."
        }

        if key.contains("mahi") && key.contains("sandwich") {
            return "A grilled mahi sandwich with a lighter coastal feel and a satisfying finish."
        }

        if key.contains("cheeseburger") {
            return "A classic cheeseburger with the fresh, friendly feel customers expect at \(restaurantLabel)."
        }

        if key.contains("chicken") && key.contains("sandwich") {
            return "A satisfying chicken sandwich made for a quick lunch or casual dinner."
        }

        if key == "fries" || key == "frie" || key.contains("fries") || key.contains("frie") {
            return "Crisp fries that pair naturally with burgers, sandwiches, and cold drinks."
        }

        if key.contains("lemonade") {
            return "A bright, refreshing lemonade for lunch, dinner, or a quick stop."
        }

        if key.contains("pho") {
            return "A comforting bowl built around slow-simmered broth and fresh herbs."
        }

        if key.contains("rice bowl") {
            return "A hearty rice bowl with fresh toppings and a simple, satisfying finish."
        }

        if key.contains("spring roll") {
            return "Fresh spring rolls made for a light start or shareable side."
        }

        let cuisineLabel = cuisine.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if cuisineLabel.isEmpty {
            return "A customer favorite from \(place)."
        }

        return "A customer favorite from the \(cuisineLabel) lineup at \(restaurantLabel)."
    }

    static func shouldReplaceGeneratedDescription(_ description: String, for itemName: String) -> Bool {
        let key = MissingDetailAnswerExtractor.menuKey(itemName)
        let lowercasedDescription = description.lowercased()
        let isKnownPolishedItem = key.contains("smashburger")
            || (key.contains("bacon") && key.contains("cheeseburger"))
            || (key.contains("mahi") && key.contains("sandwich"))
            || key.contains("cheeseburger")
            || (key.contains("chicken") && key.contains("sandwich"))
            || key.contains("fries")
            || key.contains("frie")
            || key.contains("lemonade")
            || key.contains("pho")
            || key.contains("rice bowl")
            || key.contains("spring roll")

        guard isKnownPolishedItem else { return false }

        return lowercasedDescription.contains("description not captured")
            || lowercasedDescription.contains("customer favorite from the")
            || lowercasedDescription.contains("american restaurant lineup")
    }
}

struct SiteBrandingSettings: Hashable {
    var primaryColorHex: String
    var accentColorHex: String
    var fontStyle: String

    static let demo = SiteBrandingSettings(
        primaryColorHex: "#0D1A2B",
        accentColorHex: "#E84F3C",
        fontStyle: "Modern"
    )
}

struct SiteClawBillingPlan: Identifiable, Hashable {
    var id: String { name }
    var name: String
    var price: Int
    var subtitle: String
    var features: [String]

    var displayName: String {
        "\(name) - $\(price)/mo"
    }

    static let options: [SiteClawBillingPlan] = [
        SiteClawBillingPlan(
            name: "Starter",
            price: 19,
            subtitle: "Launch one restaurant site with voice intake and local export.",
            features: ["One restaurant site", "Talk to Build workflow", "PDF/photo menu display"]
        ),
        SiteClawBillingPlan(
            name: "Growth",
            price: 49,
            subtitle: "Adds stronger owner tools for active menu and domain updates.",
            features: ["Custom domain setup", "Menu upload updates", "Review-ready SEO fields"]
        ),
        SiteClawBillingPlan(
            name: "Pro",
            price: 99,
            subtitle: "A placeholder path for multi-location and analytics work.",
            features: ["Multi-location roadmap", "Analytics placeholder", "Priority publish support"]
        )
    ]

    static var starter: SiteClawBillingPlan {
        options[0]
    }
}

struct SiteClawAccountSettings: Hashable {
    var ownerName: String
    var email: String
    var siteSubdomain: String
    var customDomain: String
    var billingPlan: String
    var isSignedIn: Bool
    var appearancePreference: SiteClawAppearancePreference = .system
    var dataRetentionNote: String = "Local prototype data stays on this Mac unless you export or publish it."

    static let demo = SiteClawAccountSettings(
        ownerName: "Demo Owner",
        email: "owner@siteclaw.test",
        siteSubdomain: "sunset-grill",
        customDomain: "",
        billingPlan: SiteClawBillingPlan.starter.displayName,
        isSignedIn: true
    )
}

enum SiteClawAppearancePreference: String, CaseIterable, Codable, Hashable, Identifiable {
    case system
    case light
    case dark

    var id: Self { self }

    var title: String {
        switch self {
        case .system: "System"
        case .light: "Light"
        case .dark: "Dark"
        }
    }

    var detail: String {
        switch self {
        case .system: "System default"
        case .light: "Light"
        case .dark: "Dark"
        }
    }

    var systemImage: String {
        switch self {
        case .system: "circle.lefthalf.filled"
        case .light: "sun.max.fill"
        case .dark: "moon.fill"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}

enum SitePublishStage: String, Codable, Hashable, CaseIterable {
    case draft
    case preview
    case published
    case needsRepublish

    var title: String {
        switch self {
        case .draft: "Draft"
        case .preview: "Preview Ready"
        case .published: "Published"
        case .needsRepublish: "Needs Republish"
        }
    }

    var systemImage: String {
        switch self {
        case .draft: "doc.text"
        case .preview: "eye.fill"
        case .published: "checkmark.seal.fill"
        case .needsRepublish: "arrow.clockwise.circle.fill"
        }
    }
}

struct SitePublishHistoryItem: Identifiable, Hashable, Codable {
    var id: UUID = UUID()
    var stage: SitePublishStage
    var title: String
    var detail: String
    var url: String
    var timestamp: Date

    var timeLabel: String {
        timestamp.formatted(date: .abbreviated, time: .shortened)
    }
}

enum SiteQualitySeverity: String, Codable, Hashable {
    case blocker
    case warning
    case passed

    var title: String {
        switch self {
        case .blocker: "Blocker"
        case .warning: "Warning"
        case .passed: "Passed"
        }
    }
}

struct SiteQualityAuditItem: Identifiable, Hashable {
    var id: String { title }
    var title: String
    var detail: String
    var severity: SiteQualitySeverity
    var systemImage: String

    var isPassing: Bool {
        severity == .passed
    }
}

struct VoiceCaptureReviewItem: Identifiable, Hashable {
    var id: String { title }
    var title: String
    var value: String
    var confidence: Double
    var detail: String
    var systemImage: String

    var isReady: Bool {
        confidence >= 0.74 && !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var statusLabel: String {
        isReady ? "Ready" : "Review"
    }
}

enum VoiceCoachConfidence: String, Codable, Hashable, Sendable, CaseIterable {
    case high
    case medium
    case low

    var displayName: String {
        switch self {
        case .high: "High"
        case .medium: "Medium"
        case .low: "Low"
        }
    }

    var score: Double {
        switch self {
        case .high: 0.9
        case .medium: 0.68
        case .low: 0.38
        }
    }
}

struct VoiceCoachTurn: Identifiable, Codable, Hashable, Sendable {
    var id = UUID()
    var promptKind: VoicePromptKind
    var question: String
    var rawAnswer: String
    var cleanedAnswer: String
    var confidence: VoiceCoachConfidence
    var missingDetails: [String]
    var suggestedFollowUp: String
    var archetypeHint: RestaurantSiteArchetype?
    var designNotes: [String]
    var statusMessage: String
    var createdAt = Date()

    var hasFollowUp: Bool {
        !suggestedFollowUp.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var hasMissingDetails: Bool {
        !missingDetails.isEmpty
    }
}

enum PreviewDeviceMode: String, CaseIterable, Identifiable, Hashable {
    case phone
    case tablet
    case desktop

    var id: String { rawValue }

    var title: String {
        switch self {
        case .phone: "Phone"
        case .tablet: "Tablet"
        case .desktop: "Desktop"
        }
    }

    var systemImage: String {
        switch self {
        case .phone: "iphone"
        case .tablet: "ipad"
        case .desktop: "desktopcomputer"
        }
    }

    var previewWidth: CGFloat {
        switch self {
        case .phone: 460
        case .tablet: 720
        case .desktop: 980
        }
    }

    var previewHeight: CGFloat {
        switch self {
        case .phone: 580
        case .tablet: 640
        case .desktop: 720
        }
    }
}

struct WebsiteDraft: Hashable {
    var headline: String
    var subheadline: String
    var callToAction: String
    var pages: [String]
    var seoKeywords: [String]
    var designBrief: RestaurantDesignBrief
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

enum MissingDetailKind: String, Hashable {
    case restaurantName
    case menuPrices
    case dishDescriptions
    case phone
    case address
}

struct MissingDetail: Identifiable, Hashable {
    var id: MissingDetailKind { kind }
    var kind: MissingDetailKind
    var title: String
    var detail: String
    var prompt: String
    var systemImage: String
    var isOptional: Bool
}

struct VoiceOnboardingPrompt: Identifiable, Hashable {
    let id = UUID()
    var question: String
    var helperText: String
    var capturedAnswer: String
    var systemImage: String
    var promptKind: VoicePromptKind = .custom
    var missingDetailKind: MissingDetailKind? = nil
}

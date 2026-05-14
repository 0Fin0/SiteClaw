//
//  RestaurantJSONModels.swift
//  SiteClaw
//

import Foundation

struct RestaurantJSON: Codable, Hashable, Sendable {
    var schemaVersion: String
    var restaurantID: String
    var lastUpdated: String
    var basics: RestaurantJSONBasics
    var contact: RestaurantJSONContact
    var hours: RestaurantJSONHours
    var menu: RestaurantJSONMenu
    var seo: RestaurantJSONSEO
    var branding: RestaurantJSONBranding
    var visibility: RestaurantJSONVisibility
    var features: RestaurantSiteFeatures
    var growthTools: RestaurantGrowthTools
    var designBrief: RestaurantDesignBrief

    enum CodingKeys: String, CodingKey {
        case schemaVersion = "schema_version"
        case restaurantID = "restaurant_id"
        case lastUpdated = "last_updated"
        case basics
        case contact
        case hours
        case menu
        case seo
        case branding
        case visibility
        case features
        case growthTools = "growth_tools"
        case designBrief = "design_brief"
    }

    init(
        schemaVersion: String,
        restaurantID: String,
        lastUpdated: String,
        basics: RestaurantJSONBasics,
        contact: RestaurantJSONContact,
        hours: RestaurantJSONHours,
        menu: RestaurantJSONMenu,
        seo: RestaurantJSONSEO,
        branding: RestaurantJSONBranding,
        visibility: RestaurantJSONVisibility,
        features: RestaurantSiteFeatures = .empty,
        growthTools: RestaurantGrowthTools = .recommended,
        designBrief: RestaurantDesignBrief = .fallback
    ) {
        self.schemaVersion = schemaVersion
        self.restaurantID = restaurantID
        self.lastUpdated = lastUpdated
        self.basics = basics
        self.contact = contact
        self.hours = hours
        self.menu = menu
        self.seo = seo
        self.branding = branding
        self.visibility = visibility
        self.features = features
        self.growthTools = growthTools
        self.designBrief = designBrief.normalized
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        schemaVersion = try container.decode(String.self, forKey: .schemaVersion)
        restaurantID = try container.decode(String.self, forKey: .restaurantID)
        lastUpdated = try container.decode(String.self, forKey: .lastUpdated)
        basics = try container.decode(RestaurantJSONBasics.self, forKey: .basics)
        contact = try container.decode(RestaurantJSONContact.self, forKey: .contact)
        hours = try container.decode(RestaurantJSONHours.self, forKey: .hours)
        menu = try container.decode(RestaurantJSONMenu.self, forKey: .menu)
        seo = try container.decode(RestaurantJSONSEO.self, forKey: .seo)
        branding = try container.decode(RestaurantJSONBranding.self, forKey: .branding)
        visibility = try container.decode(RestaurantJSONVisibility.self, forKey: .visibility)
        features = try container.decodeIfPresent(RestaurantSiteFeatures.self, forKey: .features) ?? .empty
        growthTools = try container.decodeIfPresent(RestaurantGrowthTools.self, forKey: .growthTools) ?? .recommended
        designBrief = (try container.decodeIfPresent(RestaurantDesignBrief.self, forKey: .designBrief) ?? .fallback).normalized
    }
}

struct RestaurantJSONBasics: Codable, Hashable, Sendable {
    var name: String
    var tagline: String
    var description: String
    var cuisineType: [String]
    var priceRange: String

    enum CodingKeys: String, CodingKey {
        case name
        case tagline
        case description
        case cuisineType = "cuisine_type"
        case priceRange = "price_range"
    }
}

struct RestaurantJSONContact: Codable, Hashable, Sendable {
    var phone: String
    var cateringEmail: String
    var address: RestaurantJSONAddress

    init(
        phone: String,
        cateringEmail: String = "",
        address: RestaurantJSONAddress
    ) {
        self.phone = phone
        self.cateringEmail = cateringEmail
        self.address = address
    }

    enum CodingKeys: String, CodingKey {
        case phone
        case cateringEmail = "catering_email"
        case address
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        phone = try container.decode(String.self, forKey: .phone)
        cateringEmail = try container.decodeIfPresent(String.self, forKey: .cateringEmail) ?? ""
        address = try container.decode(RestaurantJSONAddress.self, forKey: .address)
    }
}

struct RestaurantJSONAddress: Codable, Hashable, Sendable {
    var street: String
    var city: String
    var state: String
    var zip: String
    var country: String
}

struct RestaurantJSONHours: Codable, Hashable, Sendable {
    var monday: [RestaurantJSONTimeRange]
    var tuesday: [RestaurantJSONTimeRange]
    var wednesday: [RestaurantJSONTimeRange]
    var thursday: [RestaurantJSONTimeRange]
    var friday: [RestaurantJSONTimeRange]
    var saturday: [RestaurantJSONTimeRange]
    var sunday: [RestaurantJSONTimeRange]
}

struct RestaurantJSONTimeRange: Codable, Hashable, Sendable {
    var open: String
    var close: String
}

struct RestaurantJSONMenu: Codable, Hashable, Sendable {
    var categories: [RestaurantJSONMenuCategory]
    var notes: String
    var uploadedAsset: RestaurantJSONUploadedMenuAsset?

    enum CodingKeys: String, CodingKey {
        case categories
        case notes
        case uploadedAsset = "uploaded_asset"
    }
}

struct RestaurantJSONUploadedMenuAsset: Codable, Hashable, Sendable {
    var filename: String
    var mediaType: String
    var kind: String
    var dataURL: String
    var byteCount: Int

    enum CodingKeys: String, CodingKey {
        case filename
        case mediaType = "media_type"
        case kind
        case dataURL = "data_url"
        case byteCount = "byte_count"
    }
}

struct RestaurantJSONMenuCategory: Codable, Hashable, Sendable {
    var name: String
    var description: String
    var sortOrder: Int
    var items: [RestaurantJSONMenuItem]

    enum CodingKeys: String, CodingKey {
        case name
        case description
        case sortOrder = "sort_order"
        case items
    }
}

struct RestaurantJSONMenuItem: Codable, Hashable, Sendable {
    var name: String
    var description: String
    var price: Double?
    var imageURL: String?
    var dietary: [String]
    var featured: Bool
    var available: Bool

    enum CodingKeys: String, CodingKey {
        case name
        case description
        case price
        case imageURL = "image_url"
        case dietary
        case featured
        case available
    }
}

struct RestaurantJSONSEO: Codable, Hashable, Sendable {
    var title: String
    var description: String
    var keywords: [String]
}

struct RestaurantJSONVisibility: Codable, Hashable, Sendable {
    var googleBusinessProfileURL: String
    var googleReviewURL: String
    var yelpBusinessURL: String
    var instagramURL: String
    var facebookURL: String
    var googleBusinessProfileClaimed: Bool
    var restaurantPhotosAdded: Bool
    var websiteLinkedOnProfiles: Bool

    enum CodingKeys: String, CodingKey {
        case googleBusinessProfileURL = "google_business_profile_url"
        case googleReviewURL = "google_review_url"
        case yelpBusinessURL = "yelp_business_url"
        case instagramURL = "instagram_url"
        case facebookURL = "facebook_url"
        case googleBusinessProfileClaimed = "google_business_profile_claimed"
        case restaurantPhotosAdded = "restaurant_photos_added"
        case websiteLinkedOnProfiles = "website_linked_on_profiles"
    }
}

struct RestaurantJSONBranding: Codable, Hashable, Sendable {
    var primaryColor: String
    var accentColor: String
    var fontStyle: String

    enum CodingKeys: String, CodingKey {
        case primaryColor = "primary_color"
        case accentColor = "accent_color"
        case fontStyle = "font_style"
    }
}

enum RestaurantJSONExporter {
    static func makeRestaurantJSON(from restaurant: RestaurantProfile, draft: WebsiteDraft) -> RestaurantJSON {
        let name = RestaurantNameResolver.displayName(
            restaurantName: restaurant.name,
            headline: draft.headline,
            seoKeywords: draft.seoKeywords,
            fallback: "Restaurant"
        )
        let city = restaurant.neighborhood.trimmingCharacters(in: .whitespacesAndNewlines)
        let cuisine = restaurant.cuisine.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Local Restaurant" : restaurant.cuisine.trimmingCharacters(in: .whitespacesAndNewlines)
        let description = ownerDescription(from: restaurant, draft: draft)
        let tagline = liveSafeTagline(
            restaurantName: name,
            cuisine: cuisine,
            city: city,
            draftHeadline: draft.headline,
            menuItems: restaurant.menuItems
        )
        let hasOwnerProvidedPrices = restaurant.menuItems.contains { ($0.price ?? 0) > 0 }

        return RestaurantJSON(
            schemaVersion: "1.0",
            restaurantID: "00000000-0000-0000-0000-000000000001",
            lastUpdated: ISO8601DateFormatter().string(from: Date()),
            basics: RestaurantJSONBasics(
                name: name,
                tagline: tagline,
                description: description,
                cuisineType: cuisine
                    .components(separatedBy: CharacterSet(charactersIn: ",/&"))
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty },
                priceRange: hasOwnerProvidedPrices ? "$$" : ""
            ),
            contact: RestaurantJSONContact(
                phone: restaurant.phone,
                cateringEmail: restaurant.cateringEmail,
                address: RestaurantJSONAddress(
                    street: restaurant.streetAddress,
                    city: city,
                    state: restaurant.state,
                    zip: restaurant.postalCode,
                    country: restaurant.streetAddress.isEmpty && restaurant.state.isEmpty && restaurant.postalCode.isEmpty ? "" : "US"
                )
            ),
            hours: makeHours(from: restaurant.hours),
            menu: makeMenu(from: restaurant.menuItems, uploadedMenu: restaurant.uploadedMenu),
            seo: RestaurantJSONSEO(
                title: city.isEmpty ? "\(name) | \(cuisine)" : "\(name) | \(cuisine) in \(city)",
                description: description,
                keywords: draft.seoKeywords
            ),
            branding: RestaurantJSONBranding(
                primaryColor: restaurant.branding.primaryColorHex,
                accentColor: restaurant.branding.accentColorHex,
                fontStyle: restaurant.branding.fontStyle
            ),
            visibility: RestaurantJSONVisibility(
                googleBusinessProfileURL: restaurant.visibility.googleBusinessProfileURL,
                googleReviewURL: restaurant.visibility.googleReviewURL,
                yelpBusinessURL: restaurant.visibility.yelpBusinessURL,
                instagramURL: restaurant.visibility.instagramURL,
                facebookURL: restaurant.visibility.facebookURL,
                googleBusinessProfileClaimed: restaurant.visibility.googleBusinessProfileClaimed,
                restaurantPhotosAdded: restaurant.visibility.restaurantPhotosAdded,
                websiteLinkedOnProfiles: restaurant.visibility.websiteLinkedOnProfiles
            ),
            features: restaurant.features,
            growthTools: restaurant.growthTools,
            designBrief: draft.designBrief
        )
    }

    private static func ownerDescription(from restaurant: RestaurantProfile, draft: WebsiteDraft) -> String {
        let story = restaurant.story.trimmingCharacters(in: .whitespacesAndNewlines)
        return story.isEmpty ? draft.subheadline : story
    }

    private static func liveSafeTagline(
        restaurantName: String,
        cuisine: String,
        city: String,
        draftHeadline: String,
        menuItems: [MenuItem]
    ) -> String {
        let headline = draftHeadline.trimmingCharacters(in: .whitespacesAndNewlines)
        let name = restaurantName.trimmingCharacters(in: .whitespacesAndNewlines)

        if !headline.isEmpty,
           (name.isEmpty || headline.localizedCaseInsensitiveContains(name)) {
            return headline
        }

        return liveTagline(restaurantName: name, cuisine: cuisine, city: city, menuItems: menuItems)
    }

    private static func liveTagline(
        restaurantName: String,
        cuisine: String,
        city: String,
        menuItems: [MenuItem]
    ) -> String {
        let name = restaurantName.isEmpty ? "This restaurant" : restaurantName
        let offer = customerOfferPhrase(cuisine: cuisine, menuItems: menuItems)

        if city.isEmpty {
            return "\(name) serves \(offer)"
        }

        return "\(name) serves \(offer) in \(city)"
    }

    private static func customerOfferPhrase(cuisine: String, menuItems: [MenuItem]) -> String {
        let trimmedCuisine = cuisine.trimmingCharacters(in: .whitespacesAndNewlines)
        let lowercasedCuisine = trimmedCuisine.lowercased()

        if lowercasedCuisine.hasSuffix(" restaurant") {
            let base = trimmedCuisine
                .dropLast(" restaurant".count)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            return base.isEmpty ? "fresh food" : "\(base) food"
        }

        if !trimmedCuisine.isEmpty && lowercasedCuisine != "local restaurant" {
            return trimmedCuisine
        }

        let items = menuItems
            .map(\.name)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
            .filter { !$0.isEmpty }
            .prefix(2)

        return items.isEmpty ? "fresh food" : items.joined(separator: " and ")
    }

    static func prettyJSONString(from restaurantJSON: RestaurantJSON) -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]

        guard let data = try? encoder.encode(restaurantJSON),
              let string = String(data: data, encoding: .utf8) else {
            return "{}"
        }

        return string
    }

    private static func makeMenu(
        from menuItems: [MenuItem],
        uploadedMenu: UploadedMenuAsset?
    ) -> RestaurantJSONMenu {
        let items = menuItems.enumerated().map { index, item in
            let description = item.description.trimmingCharacters(in: .whitespacesAndNewlines)

            return RestaurantJSONMenuItem(
                name: item.name,
                description: description,
                price: item.price,
                imageURL: item.image?.dataURL,
                dietary: [],
                featured: index == 0,
                available: true
            )
        }

        return RestaurantJSONMenu(
            categories: [
                RestaurantJSONMenuCategory(
                    name: "Featured Dishes",
                    description: "Popular dishes selected during SiteClaw voice onboarding.",
                    sortOrder: 0,
                    items: items
                )
            ],
            notes: "Menu items and prices come from the owner conversation. Review drafted descriptions, dietary details, and availability before publishing.",
            uploadedAsset: uploadedMenu.map {
                RestaurantJSONUploadedMenuAsset(
                    filename: $0.filename,
                    mediaType: $0.mediaType,
                    kind: $0.kind.rawValue,
                    dataURL: $0.dataURL,
                    byteCount: $0.byteCount
                )
            }
        )
    }

    private static func makeHours(from hoursText: String) -> RestaurantJSONHours {
        let trimmedHours = hoursText.trimmingCharacters(in: .whitespacesAndNewlines)
        let empty: [RestaurantJSONTimeRange] = []
        guard let primaryRange = parseTimeRange(from: trimmedHours) else {
            return RestaurantJSONHours(
                monday: empty,
                tuesday: empty,
                wednesday: empty,
                thursday: empty,
                friday: empty,
                saturday: empty,
                sunday: empty
            )
        }

        let lowercasedHours = trimmedHours.lowercased()
        let everyDay = lowercasedHours.contains("daily")
            || lowercasedHours.contains("every day")
            || lowercasedHours.contains("seven days")

        var rangesByDay = Array(repeating: empty, count: Self.weekdays.count)

        if everyDay {
            for index in rangesByDay.indices {
                rangesByDay[index] = [primaryRange]
            }
        } else if let dayRange = primaryDayRange(from: trimmedHours) {
            for index in dayRange {
                rangesByDay[index] = [primaryRange]
            }
        }

        if let sundayRange = daySpecificRange(for: 6, from: trimmedHours) {
            rangesByDay[6] = sundayRange
        }

        return RestaurantJSONHours(
            monday: rangesByDay[0],
            tuesday: rangesByDay[1],
            wednesday: rangesByDay[2],
            thursday: rangesByDay[3],
            friday: rangesByDay[4],
            saturday: rangesByDay[5],
            sunday: rangesByDay[6]
        )
    }

    private static let weekdays = [
        ["monday", "mon"],
        ["tuesday", "tue", "tues"],
        ["wednesday", "wed"],
        ["thursday", "thu", "thur", "thurs"],
        ["friday", "fri"],
        ["saturday", "sat"],
        ["sunday", "sun"]
    ]

    private static func primaryDayRange(from hoursText: String) -> ClosedRange<Int>? {
        let dayPattern = #"(monday|mon|tuesday|tue|tues|wednesday|wed|thursday|thu|thur|thurs|friday|fri|saturday|sat|sunday|sun)"#
        let pattern = #"\b\#(dayPattern)\b\s*(?:-|–|to|through)\s*\b\#(dayPattern)\b"#

        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
            return nil
        }

        let range = NSRange(hoursText.startIndex..<hoursText.endIndex, in: hoursText)
        guard let match = regex.firstMatch(in: hoursText, range: range),
              match.numberOfRanges >= 3,
              let startRange = Range(match.range(at: 1), in: hoursText),
              let endRange = Range(match.range(at: 2), in: hoursText),
              let startIndex = dayIndex(for: String(hoursText[startRange])),
              let endIndex = dayIndex(for: String(hoursText[endRange])) else {
            return nil
        }

        if startIndex <= endIndex {
            return startIndex...endIndex
        }

        return nil
    }

    private static func daySpecificRange(for dayIndex: Int, from hoursText: String) -> [RestaurantJSONTimeRange]? {
        guard weekdays.indices.contains(dayIndex) else { return nil }
        let dayAlternatives = weekdays[dayIndex]
            .map { NSRegularExpression.escapedPattern(for: $0) }
            .joined(separator: "|")

        guard let dayRange = hoursText.range(
            of: #"\b(\#(dayAlternatives))\b[^,.;]*"#,
            options: [.regularExpression, .caseInsensitive]
        ) else {
            return nil
        }

        return parseTimeRange(from: String(hoursText[dayRange])).map { [$0] }
    }

    private static func dayIndex(for value: String) -> Int? {
        let normalized = value.lowercased()
        return weekdays.firstIndex { aliases in
            aliases.contains(normalized)
        }
    }

    private static func parseTimeRange(from text: String) -> RestaurantJSONTimeRange? {
        guard let match = text.range(
            of: #"(\d{1,2})(?::(\d{2}))?\s*(AM|PM|am|pm)?\s*(?:-|–|to)\s*(\d{1,2})(?::(\d{2}))?\s*(AM|PM|am|pm)?"#,
            options: .regularExpression
        ) else {
            return nil
        }

        let rangeText = String(text[match])
        let parts = rangeText
            .replacingOccurrences(of: "–", with: "-")
            .replacingOccurrences(of: " to ", with: "-")
            .components(separatedBy: "-")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }

        guard parts.count == 2,
              let open = normalizedTime(parts[0], fallbackPeriod: "AM"),
              let close = normalizedTime(parts[1], fallbackPeriod: "PM") else {
            return nil
        }

        return RestaurantJSONTimeRange(open: open, close: close)
    }

    private static func normalizedTime(_ value: String, fallbackPeriod: String) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let hourMatch = trimmed.range(of: #"\d{1,2}"#, options: .regularExpression),
              var hour = Int(trimmed[hourMatch]) else {
            return nil
        }

        var minute = 0
        if let minuteRange = trimmed.range(of: #"(?<=:)\d{2}"#, options: .regularExpression),
           let parsedMinute = Int(trimmed[minuteRange]) {
            minute = parsedMinute
        }

        let uppercased = trimmed.uppercased()
        let period = uppercased.contains("AM") || uppercased.contains("PM")
            ? uppercased
            : fallbackPeriod

        if period.contains("PM"), hour < 12 {
            hour += 12
        } else if period.contains("AM"), hour == 12 {
            hour = 0
        }

        return String(format: "%02d:%02d", hour, minute)
    }
}

enum RestaurantNameResolver {
    static func displayName(
        restaurantName: String,
        headline: String,
        seoKeywords: [String],
        fallback: String
    ) -> String {
        let trimmedName = restaurantName.trimmingCharacters(in: .whitespacesAndNewlines)
        if isUsableName(trimmedName) {
            return titleCasedName(trimmedName)
        }

        for keyword in seoKeywords {
            if let inferredName = inferredName(from: keyword) {
                return inferredName
            }
        }

        if let inferredName = inferredName(from: headline) {
            return inferredName
        }

        return fallback
    }

    static func inferredName(from text: String) -> String? {
        let patterns = [
            #"^([A-Z][A-Za-z0-9&'.-]*(?:\s+[A-Z][A-Za-z0-9&'.-]*){0,5}\s+(?:Kitchen|Cafe|Coffee|Bakery|Grill|Restaurant|Diner|Bistro|Taqueria|Pizzeria|Bar|House|Market|Deli|Truck))\b"#,
            #"^([A-Z][A-Za-z0-9&'.-]*(?:\s+[A-Z][A-Za-z0-9&'.-]*){1,5})(?=\s+(?:brings|serves|offers|is|has)\b)"#
        ]

        for pattern in patterns {
            guard let candidate = firstMatch(pattern, in: text),
                  isUsableName(candidate) else {
                continue
            }

            return titleCasedName(candidate)
        }

        return nil
    }

    private static func isUsableName(_ value: String) -> Bool {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        let lowercased = trimmed.lowercased()
        let genericNames = [
            "", "restaurant", "unnamed restaurant", "local restaurant", "vietnamese restaurant",
            "mexican restaurant", "italian restaurant", "chinese restaurant", "thai restaurant",
            "japanese restaurant", "korean restaurant", "indian restaurant", "american restaurant"
        ]

        return !genericNames.contains(lowercased)
            && !lowercased.contains(" near me")
            && !lowercased.contains(" in ")
    }

    private static func titleCasedName(_ value: String) -> String {
        value
            .split(separator: " ")
            .map { word in
                let lowercased = word.lowercased()
                if lowercased == "pho" { return "Pho" }
                if lowercased == "bbq" { return "BBQ" }
                return lowercased.prefix(1).uppercased() + String(lowercased.dropFirst())
            }
            .joined(separator: " ")
    }

    private static func firstMatch(_ pattern: String, in text: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return nil
        }

        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        guard let match = regex.firstMatch(in: text, range: range),
              match.numberOfRanges > 1,
              let matchRange = Range(match.range(at: 1), in: text) else {
            return nil
        }

        return String(text[matchRange]).trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

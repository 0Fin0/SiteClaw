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
    var address: RestaurantJSONAddress
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
    var dietary: [String]
    var featured: Bool
    var available: Bool
}

struct RestaurantJSONSEO: Codable, Hashable, Sendable {
    var title: String
    var description: String
    var keywords: [String]
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
        let name = restaurant.name.isEmpty ? "Unnamed Restaurant" : restaurant.name
        let city = restaurant.neighborhood
        let cuisine = restaurant.cuisine.isEmpty ? "Local Restaurant" : restaurant.cuisine
        let hasOwnerProvidedPrices = restaurant.menuItems.contains { ($0.price ?? 0) > 0 }

        return RestaurantJSON(
            schemaVersion: "1.0",
            restaurantID: "00000000-0000-0000-0000-000000000001",
            lastUpdated: ISO8601DateFormatter().string(from: Date()),
            basics: RestaurantJSONBasics(
                name: name,
                tagline: draft.headline,
                description: draft.subheadline,
                cuisineType: cuisine
                    .components(separatedBy: CharacterSet(charactersIn: ",/&"))
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty },
                priceRange: hasOwnerProvidedPrices ? "$$" : ""
            ),
            contact: RestaurantJSONContact(
                phone: restaurant.phone,
                address: RestaurantJSONAddress(
                    street: "",
                    city: city,
                    state: "",
                    zip: "",
                    country: ""
                )
            ),
            hours: makeHours(from: restaurant.hours),
            menu: makeMenu(from: restaurant.menuItems),
            seo: RestaurantJSONSEO(
                title: "\(name) | \(cuisine) in \(city)",
                description: draft.subheadline,
                keywords: draft.seoKeywords
            ),
            branding: RestaurantJSONBranding(
                primaryColor: "#0D1A2B",
                accentColor: "#E84F3C",
                fontStyle: "modern"
            )
        )
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

    private static func makeMenu(from menuItems: [MenuItem]) -> RestaurantJSONMenu {
        let items = menuItems.enumerated().map { index, item in
            RestaurantJSONMenuItem(
                name: item.name,
                description: item.description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    ? "Owner-provided menu item."
                    : item.description,
                price: item.price,
                dietary: [],
                featured: index == 0,
                available: true
            )
        }

        return RestaurantJSONMenu(
            categories: [
                RestaurantJSONMenuCategory(
                    name: "Featured Menu",
                    description: "Popular dishes selected during SiteClaw voice onboarding.",
                    sortOrder: 0,
                    items: items
                )
            ],
            notes: "Only owner-provided menu details are included. Add missing prices, dietary details, and availability before publishing."
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
        let mondayThroughSaturday = lowercasedHours.contains("mon-sat")
            || lowercasedHours.contains("monday through saturday")
            || lowercasedHours.contains("monday to saturday")
        let everyDay = lowercasedHours.contains("daily")
            || lowercasedHours.contains("every day")
            || lowercasedHours.contains("seven days")

        let weekdayRange = mondayThroughSaturday || everyDay ? [primaryRange] : empty
        let sundayRange = sundayRange(from: trimmedHours) ?? (everyDay ? [primaryRange] : empty)

        return RestaurantJSONHours(
            monday: weekdayRange,
            tuesday: weekdayRange,
            wednesday: weekdayRange,
            thursday: weekdayRange,
            friday: weekdayRange,
            saturday: weekdayRange,
            sunday: sundayRange
        )
    }

    private static func sundayRange(from hoursText: String) -> [RestaurantJSONTimeRange]? {
        guard let sundayRange = hoursText.range(
            of: #"(Sun|Sunday)[^,.;]*"#,
            options: [.regularExpression, .caseInsensitive]
        ) else {
            return nil
        }

        return parseTimeRange(from: String(hoursText[sundayRange])).map { [$0] }
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

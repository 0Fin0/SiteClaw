//
//  RestaurantJSONModels.swift
//  SiteClaw
//

import Foundation

struct RestaurantJSON: Codable, Hashable {
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

struct RestaurantJSONBasics: Codable, Hashable {
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

struct RestaurantJSONContact: Codable, Hashable {
    var phone: String
    var address: RestaurantJSONAddress
}

struct RestaurantJSONAddress: Codable, Hashable {
    var street: String
    var city: String
    var state: String
    var zip: String
    var country: String
}

struct RestaurantJSONHours: Codable, Hashable {
    var monday: [RestaurantJSONTimeRange]
    var tuesday: [RestaurantJSONTimeRange]
    var wednesday: [RestaurantJSONTimeRange]
    var thursday: [RestaurantJSONTimeRange]
    var friday: [RestaurantJSONTimeRange]
    var saturday: [RestaurantJSONTimeRange]
    var sunday: [RestaurantJSONTimeRange]
}

struct RestaurantJSONTimeRange: Codable, Hashable {
    var open: String
    var close: String
}

struct RestaurantJSONMenu: Codable, Hashable {
    var categories: [RestaurantJSONMenuCategory]
    var notes: String
}

struct RestaurantJSONMenuCategory: Codable, Hashable {
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

struct RestaurantJSONMenuItem: Codable, Hashable {
    var name: String
    var description: String
    var price: Double
    var dietary: [String]
    var featured: Bool
    var available: Bool
}

struct RestaurantJSONSEO: Codable, Hashable {
    var title: String
    var description: String
    var keywords: [String]
}

struct RestaurantJSONBranding: Codable, Hashable {
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
        let city = restaurant.neighborhood.isEmpty ? "San Jose" : restaurant.neighborhood
        let cuisine = restaurant.cuisine.isEmpty ? "Local Restaurant" : restaurant.cuisine
        let phone = restaurant.phone.isEmpty ? "(408) 555-0100" : restaurant.phone

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
                priceRange: "$$"
            ),
            contact: RestaurantJSONContact(
                phone: phone,
                address: RestaurantJSONAddress(
                    street: "123 Main Street",
                    city: city,
                    state: "CA",
                    zip: "95112",
                    country: "US"
                )
            ),
            hours: makeHours(),
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
                description: item.description,
                price: item.price,
                dietary: index == 2 ? ["gluten-free"] : [],
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
            notes: "Prices and availability may change. Contact the restaurant to confirm current menu items."
        )
    }

    private static func makeHours() -> RestaurantJSONHours {
        let weekday = [RestaurantJSONTimeRange(open: "11:00", close: "21:00")]
        let sunday = [RestaurantJSONTimeRange(open: "11:00", close: "19:00")]

        return RestaurantJSONHours(
            monday: weekday,
            tuesday: weekday,
            wednesday: weekday,
            thursday: weekday,
            friday: weekday,
            saturday: weekday,
            sunday: sunday
        )
    }
}

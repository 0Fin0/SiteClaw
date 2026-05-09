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
    var gallery: [RestaurantJSONGalleryImage] = []
    var social: RestaurantJSONSocial?
    var features: RestaurantJSONFeatures?
    var specials: [RestaurantJSONSpecial] = []

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
        case gallery
        case social
        case features
        case specials
    }
}

struct RestaurantJSONBasics: Codable, Hashable, Sendable {
    var name: String
    var tagline: String
    var description: String
    var cuisineType: [String]
    var priceRange: String
    var yearEstablished: Int? = nil

    enum CodingKeys: String, CodingKey {
        case name
        case tagline
        case description
        case cuisineType = "cuisine_type"
        case priceRange = "price_range"
        case yearEstablished = "year_established"
    }
}

struct RestaurantJSONContact: Codable, Hashable, Sendable {
    var phone: String
    var email: String? = nil
    var address: RestaurantJSONAddress
    var coordinates: RestaurantJSONCoordinates? = nil
}

struct RestaurantJSONAddress: Codable, Hashable, Sendable {
    var street: String
    var city: String
    var state: String
    var zip: String
    var country: String
}

struct RestaurantJSONCoordinates: Codable, Hashable, Sendable {
    var lat: Double
    var lng: Double
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
    var label: String? = nil
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
    var priceNote: String? = nil
    var imageURL: String? = nil
    var dietary: [String]
    var featured: Bool
    var available: Bool

    enum CodingKeys: String, CodingKey {
        case name
        case description
        case price
        case priceNote = "price_note"
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
    var ogImageURL: String? = nil

    enum CodingKeys: String, CodingKey {
        case title
        case description
        case keywords
        case ogImageURL = "og_image_url"
    }
}

struct RestaurantJSONBranding: Codable, Hashable, Sendable {
    var logoURL: String? = nil
    var primaryColor: String
    var secondaryColor: String? = nil
    var accentColor: String
    var fontStyle: String
    var heroImageURL: String? = nil

    enum CodingKeys: String, CodingKey {
        case logoURL = "logo_url"
        case primaryColor = "primary_color"
        case secondaryColor = "secondary_color"
        case accentColor = "accent_color"
        case fontStyle = "font_style"
        case heroImageURL = "hero_image_url"
    }
}

struct RestaurantJSONGalleryImage: Codable, Hashable, Identifiable, Sendable {
    var id: String { url }
    var url: String
    var alt: String?
    var caption: String?
    var sortOrder: Int?

    enum CodingKeys: String, CodingKey {
        case url
        case alt
        case caption
        case sortOrder = "sort_order"
    }
}

struct RestaurantJSONSocial: Codable, Hashable, Sendable {
    var facebook: String?
    var instagram: String?
    var twitter: String?
    var tiktok: String?
    var yelp: String?
    var googleMaps: String?
    var doordash: String?
    var ubereats: String?
    var grubhub: String?

    enum CodingKeys: String, CodingKey {
        case facebook
        case instagram
        case twitter
        case tiktok
        case yelp
        case googleMaps = "google_maps"
        case doordash
        case ubereats
        case grubhub
    }
}

struct RestaurantJSONFeatures: Codable, Hashable, Sendable {
    var onlineOrderingURL: String?
    var reservationURL: String?
    var showMap: Bool?
    var showReviews: Bool?
    var testimonials: [RestaurantJSONTestimonial]?

    enum CodingKeys: String, CodingKey {
        case onlineOrderingURL = "online_ordering_url"
        case reservationURL = "reservation_url"
        case showMap = "show_map"
        case showReviews = "show_reviews"
        case testimonials
    }
}

struct RestaurantJSONTestimonial: Codable, Hashable, Identifiable, Sendable {
    var id: String { "\(author)-\(quote)" }
    var quote: String
    var author: String
    var source: String?
    var rating: Int?
}

struct RestaurantJSONSpecial: Codable, Hashable, Identifiable, Sendable {
    var id: String { title }
    var title: String
    var description: String?
    var startDate: String?
    var endDate: String?
    var recurring: String?
    var imageURL: String?

    enum CodingKeys: String, CodingKey {
        case title
        case description
        case startDate = "start_date"
        case endDate = "end_date"
        case recurring
        case imageURL = "image_url"
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
                    street: restaurant.streetAddress,
                    city: city,
                    state: restaurant.state,
                    zip: restaurant.postalCode,
                    country: restaurant.streetAddress.isEmpty && restaurant.state.isEmpty && restaurant.postalCode.isEmpty ? "" : "US"
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
            let description = item.description.trimmingCharacters(in: .whitespacesAndNewlines)

            return RestaurantJSONMenuItem(
                name: item.name,
                description: description,
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

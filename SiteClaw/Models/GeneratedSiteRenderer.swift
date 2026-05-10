//
//  GeneratedSiteRenderer.swift
//  SiteClaw
//

import Foundation

struct GeneratedSiteExport: Hashable {
    var html: String
    var slug: String
    var defaultFilename: String
    var byteCount: Int

    var sizeLabel: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useBytes]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(byteCount))
    }
}

enum GeneratedSiteRenderer {
    static func makeExport(from restaurantJSON: RestaurantJSON, draft: WebsiteDraft) -> GeneratedSiteExport {
        let slug = slug(for: restaurantJSON.basics.name)
        let html = makeHTML(from: restaurantJSON, draft: draft, slug: slug)

        return GeneratedSiteExport(
            html: html,
            slug: slug,
            defaultFilename: "\(slug)-index",
            byteCount: Data(html.utf8).count
        )
    }

    private static func makeHTML(from data: RestaurantJSON, draft: WebsiteDraft, slug: String) -> String {
        let title = escape(data.seo.title.isEmpty ? data.basics.name : data.seo.title)
        let publicDescription = publicStory(from: data.seo.description.isEmpty ? data.basics.description : data.seo.description)
        let description = escape(publicDescription)
        let rawRestaurantName = data.basics.name.trimmingCharacters(in: .whitespacesAndNewlines)
        let restaurantName = escape(data.basics.name)
        let tagline = escape(data.basics.tagline.isEmpty ? draft.headline : data.basics.tagline)
        let story = escape(publicStory(from: data.basics.description))
        let cuisine = escape(data.basics.cuisineType.joined(separator: " / "))
        let address = data.contact.address
        let addressLine = fullAddressLine(from: address)
        let addressDisplay = escape(addressLine.isEmpty ? "Location coming soon" : addressLine)
        let locationName = customerLocationName(from: address)
        let phone = data.contact.phone.trimmingCharacters(in: .whitespacesAndNewlines)
        let phoneActionHTML = phone.isEmpty
            ? ""
            : #"<a class="button secondary" href="tel:\#(escape(phone))">Call \#(escape(phone))</a>"#
        let phoneCardHTML = phone.isEmpty
            ? ""
            : """
              <div class="info-card">
                <h3>Phone</h3>
                <p><a href="tel:\(escape(phone))">\(escape(phone))</a></p>
              </div>
            """
        let menuHTML = makeMenuHTML(from: data.menu)
        let menuCount = data.menu.categories.flatMap(\.items).count
        let menuSummary = menuCount == 0 ? "Menu details coming soon" : "\(menuCount) featured menu items"
        let menuLead = escape(makeMenuLead(from: data.menu))
        let hoursHTML = makeHoursHTML(from: data.hours)
        let hoursSummary = escape(makeHoursSummary(from: data.hours))
        let keywords = escape(data.seo.keywords.joined(separator: ", "))
        let primaryColor = sanitizeHexColor(data.branding.primaryColor, fallback: "#0D1A2B")
        let accentColor = sanitizeHexColor(data.branding.accentColor, fallback: "#E84F3C")
        let callToAction = escape(draft.callToAction.isEmpty ? "View Menu" : draft.callToAction)
        let visitHeadline = escape(makeVisitHeadline(restaurantName: rawRestaurantName, locationName: locationName))
        let visitCopy = escape(makeVisitCopy(from: data, locationName: locationName))

        return """
        <!doctype html>
        <html lang="en">
        <head>
          <meta charset="utf-8">
          <meta name="viewport" content="width=device-width, initial-scale=1">
          <title>\(title)</title>
          <meta name="description" content="\(description)">
          <meta name="keywords" content="\(keywords)">
          <meta property="og:title" content="\(title)">
          <meta property="og:description" content="\(description)">
          <meta property="og:type" content="restaurant.restaurant">
          <style>
            :root {
              --primary: \(primaryColor);
              --accent: \(accentColor);
              --ink: #17202A;
              --paper: #FFFDF8;
              --muted: #65717D;
              --line: rgba(23, 32, 42, 0.12);
            }

            * { box-sizing: border-box; }
            html { scroll-behavior: smooth; }
            body {
              margin: 0;
              font-family: Inter, ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
              color: var(--ink);
              background: var(--paper);
              line-height: 1.5;
            }
            a {
              color: inherit;
              text-decoration: none;
            }
            header {
              min-height: 62vh;
              display: grid;
              align-items: end;
              color: white;
              background:
                linear-gradient(135deg, rgba(13, 26, 43, 0.94), rgba(232, 79, 60, 0.76)),
                url("https://images.unsplash.com/photo-1552566626-52f8b828add9?auto=format&fit=crop&w=1600&q=80") center / cover;
            }
            nav {
              position: absolute;
              inset: 0 0 auto 0;
              display: flex;
              justify-content: space-between;
              align-items: center;
              gap: 18px;
              padding: 22px clamp(20px, 5vw, 72px);
              font-weight: 800;
              letter-spacing: 0;
            }
            nav .brand { font-size: 1.02rem; }
            nav .links {
              display: flex;
              flex-wrap: wrap;
              gap: 18px;
              font-size: 0.92rem;
            }
            nav .links a { color: rgba(255, 255, 255, 0.86); }
            nav .links a:hover { color: white; }
            .hero {
              width: min(1120px, calc(100% - 40px));
              margin: 0 auto;
              padding: 112px 0 58px;
            }
            .eyebrow {
              margin: 0 0 12px;
              text-transform: uppercase;
              font-size: 0.78rem;
              font-weight: 800;
              letter-spacing: 0.12em;
              color: rgba(255, 255, 255, 0.78);
            }
            .section-kicker {
              margin: 0 0 8px;
              color: var(--accent);
              font-size: 0.78rem;
              font-weight: 900;
              text-transform: uppercase;
            }
            h1 {
              max-width: 820px;
              margin: 0;
              font-size: clamp(3rem, 8vw, 6.6rem);
              line-height: 0.96;
              letter-spacing: 0;
            }
            .hero p {
              max-width: 680px;
              margin: 22px 0 0;
              font-size: clamp(1.08rem, 2vw, 1.35rem);
              color: rgba(255, 255, 255, 0.88);
            }
            .actions {
              display: flex;
              flex-wrap: wrap;
              gap: 12px;
              margin-top: 30px;
            }
            .button {
              display: inline-flex;
              align-items: center;
              justify-content: center;
              min-height: 46px;
              padding: 0 18px;
              border-radius: 8px;
              text-decoration: none;
              font-weight: 800;
              background: #F8C95A;
              color: #111827;
            }
            .button.secondary {
              background: rgba(255, 255, 255, 0.14);
              color: white;
              border: 1px solid rgba(255, 255, 255, 0.28);
            }
            .fact-strip {
              display: grid;
              grid-template-columns: repeat(3, minmax(0, 1fr));
              gap: 12px;
              width: min(1120px, calc(100% - 40px));
              margin: -34px auto 0;
              position: relative;
              z-index: 2;
            }
            .fact {
              min-height: 92px;
              padding: 16px;
              border-radius: 8px;
              background: white;
              border: 1px solid var(--line);
              box-shadow: 0 18px 42px rgba(13, 26, 43, 0.10);
            }
            .fact span {
              display: block;
              margin-bottom: 6px;
              color: var(--muted);
              font-size: 0.78rem;
              font-weight: 800;
              text-transform: uppercase;
            }
            .fact strong { font-size: 1rem; }
            main {
              width: min(1120px, calc(100% - 40px));
              margin: 0 auto;
            }
            section { padding: 58px 0; border-bottom: 1px solid var(--line); }
            h2 {
              margin: 0 0 18px;
              font-size: clamp(2rem, 4vw, 3.2rem);
              line-height: 1;
              letter-spacing: 0;
            }
            .split {
              display: grid;
              grid-template-columns: minmax(0, 0.9fr) minmax(280px, 1.1fr);
              gap: clamp(24px, 4vw, 54px);
              align-items: start;
            }
            .lead { color: var(--muted); font-size: 1.08rem; }
            .menu-grid {
              display: grid;
              grid-template-columns: repeat(2, minmax(0, 1fr));
              gap: 16px;
            }
            .menu-item {
              display: flex;
              flex-direction: column;
              justify-content: space-between;
              gap: 10px;
              min-height: 148px;
              padding: 17px;
              border: 1px solid var(--line);
              border-radius: 8px;
              background: white;
              box-shadow: 0 16px 34px rgba(13, 26, 43, 0.06);
            }
            .item-top {
              display: flex;
              align-items: start;
              justify-content: space-between;
              gap: 16px;
            }
            .menu-item h3 { margin: 0 0 4px; font-size: 1.08rem; }
            .menu-item p { margin: 0; color: var(--muted); }
            .price { font-weight: 900; color: var(--accent); }
            .info-grid {
              display: grid;
              grid-template-columns: repeat(3, minmax(0, 1fr));
              gap: 14px;
            }
            .info-card {
              padding: 18px;
              border: 1px solid var(--line);
              border-radius: 8px;
              background: white;
            }
            .info-card h3 { margin: 0 0 8px; }
            .info-card p { margin: 0; color: var(--muted); }
            .info-card a { color: var(--primary); font-weight: 800; }
            .hours-list {
              display: grid;
              gap: 8px;
              margin: 0;
              padding: 0;
              list-style: none;
            }
            .hours-list li {
              display: flex;
              justify-content: space-between;
              gap: 14px;
              padding-bottom: 8px;
              border-bottom: 1px solid var(--line);
            }
            .visit-cta {
              display: flex;
              align-items: center;
              justify-content: space-between;
              gap: 24px;
              margin: 48px 0 0;
              padding: clamp(24px, 5vw, 40px);
              border: 1px solid var(--line);
              border-radius: 8px;
              background: var(--primary);
              color: white;
            }
            .visit-cta h2 {
              max-width: 720px;
              margin-bottom: 10px;
            }
            .visit-cta p { margin: 0; color: rgba(255, 255, 255, 0.78); }
            .visit-cta .actions {
              margin: 0;
              flex: 0 0 auto;
              justify-content: flex-end;
            }
            footer {
              padding: 34px 20px;
              text-align: center;
              color: var(--muted);
            }
            @media (max-width: 760px) {
              nav {
                align-items: flex-start;
                flex-direction: column;
                gap: 12px;
              }
              nav .links {
                gap: 8px;
                font-size: 0.84rem;
              }
              nav .links a {
                min-height: 32px;
                display: inline-flex;
                align-items: center;
                padding: 0 10px;
                border-radius: 999px;
                background: rgba(255, 255, 255, 0.14);
              }
              header { min-height: 70vh; }
              .hero { padding-top: 144px; padding-bottom: 46px; }
              section { padding: 46px 0; }
              .split { gap: 18px; }
              .split, .info-grid, .menu-grid, .fact-strip { grid-template-columns: 1fr; }
              .fact-strip { margin-top: -22px; }
              .menu-item { min-height: auto; }
              .visit-cta {
                align-items: stretch;
                flex-direction: column;
              }
              .visit-cta .actions {
                justify-content: stretch;
              }
              .visit-cta .button {
                width: 100%;
              }
            }
          </style>
          <script type="application/ld+json">
          \(makeStructuredData(from: data, slug: slug))
          </script>
        </head>
        <body>
          <header id="home">
            <nav>
              <a class="brand" href="#home">\(restaurantName)</a>
              <div class="links">
                <a href="#home">Home</a>
                <a href="#menu">Menu</a>
                <a href="#hours">Hours</a>
                <a href="#location">Location</a>
              </div>
            </nav>
            <div class="hero">
              <p class="eyebrow">\(cuisine)</p>
              <h1>\(restaurantName)</h1>
              <p>\(tagline)</p>
              <div class="actions">
                <a class="button" href="#menu">\(callToAction)</a>
                \(phoneActionHTML)
              </div>
            </div>
          </header>

          <div class="fact-strip">
            <div class="fact">
              <span>Location</span>
              <strong>\(addressDisplay)</strong>
            </div>
            <div class="fact">
              <span>Hours</span>
              <strong>\(hoursSummary)</strong>
            </div>
            <div class="fact">
              <span>Menu</span>
              <strong>\(escape(menuSummary))</strong>
            </div>
          </div>

          <main>
            <section class="split">
              <div>
                <h2>Our Story</h2>
              </div>
              <p class="lead">\(story)</p>
            </section>

            <section id="menu" class="split">
              <div>
                <h2>Featured Menu</h2>
                <p class="lead">\(menuLead)</p>
              </div>
              <div class="menu-grid">
                \(menuHTML)
              </div>
            </section>

            <section id="visit">
              <h2>Visit Us</h2>
              <div class="info-grid">
                <div class="info-card" id="location">
                  <h3>Address</h3>
                  <p>\(addressDisplay)</p>
                </div>
                \(phoneCardHTML)
                <div class="info-card" id="hours">
                  <h3>Hours</h3>
                  <ul class="hours-list">
                    \(hoursHTML)
                  </ul>
                </div>
              </div>
            </section>

            <section class="visit-cta" aria-label="Plan a visit">
              <div>
                <p class="section-kicker">Plan your visit</p>
                <h2>\(visitHeadline)</h2>
                <p>\(visitCopy)</p>
              </div>
              <div class="actions">
                <a class="button" href="#menu">View Menu</a>
                <a class="button secondary" href="#hours">Hours &amp; Location</a>
              </div>
            </section>
          </main>

          <footer>
            <p>\(restaurantName) &middot; \(addressDisplay)</p>
          </footer>
        </body>
        </html>
        """
    }

    private static func makeMenuHTML(from menu: RestaurantJSONMenu) -> String {
        let items = menu.categories.flatMap(\.items)

        guard !items.isEmpty else {
            return """
            <div class="menu-item">
              <div>
                <h3>Menu coming soon</h3>
                <p>Check back soon for featured dishes and pricing.</p>
              </div>
              <div class="price">-</div>
            </div>
            """
        }

        return items.map { item in
            let description = item.description.trimmingCharacters(in: .whitespacesAndNewlines)
            let hasDescription = !description.isEmpty
            let hasPrice = (item.price ?? 0) > 0
            let descriptionHTML = hasDescription
                ? "<p>\(escape(description))</p>"
                : ""
            let priceHTML = hasPrice
                ? #"<strong class="price">\#(formatPrice(item.price))</strong>"#
                : ""

            return """
            <div class="menu-item">
              <div class="item-top">
                <h3>\(escape(item.name))</h3>
                \(priceHTML)
              </div>
              \(descriptionHTML)
            </div>
            """
        }
        .joined(separator: "\n")
    }

    private static func makeHoursHTML(from hours: RestaurantJSONHours) -> String {
        let rows = [
            ("Monday", hours.monday),
            ("Tuesday", hours.tuesday),
            ("Wednesday", hours.wednesday),
            ("Thursday", hours.thursday),
            ("Friday", hours.friday),
            ("Saturday", hours.saturday),
            ("Sunday", hours.sunday),
        ]
        .filter { _, ranges in !ranges.isEmpty }
        .map { day, ranges in
            "<li><span>\(day)</span><strong>\(escape(formatHours(ranges)))</strong></li>"
        }
        .joined(separator: "\n")

        return rows.isEmpty
            ? "<li><span>Hours</span><strong>Not provided yet</strong></li>"
            : rows
    }

    private static func makeStructuredData(from data: RestaurantJSON, slug: String) -> String {
        let address = data.contact.address
        var structuredData: [String: Any] = [
            "@context": "https://schema.org",
            "@type": "Restaurant",
            "name": data.basics.name,
            "description": publicStory(from: data.basics.description),
            "servesCuisine": data.basics.cuisineType,
            "url": "https://\(slug).siteclaw.app",
        ]

        let priceRange = data.basics.priceRange.trimmingCharacters(in: .whitespacesAndNewlines)
        if !priceRange.isEmpty {
            structuredData["priceRange"] = priceRange
        }

        let phone = data.contact.phone.trimmingCharacters(in: .whitespacesAndNewlines)
        if !phone.isEmpty {
            structuredData["telephone"] = phone
        }

        var structuredAddress: [String: String] = [
            "@type": "PostalAddress",
        ]
        let addressFields = [
            "streetAddress": address.street,
            "addressLocality": address.city,
            "addressRegion": address.state,
            "postalCode": address.zip,
            "addressCountry": address.country,
        ]
        for (key, value) in addressFields {
            let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                structuredAddress[key] = trimmed
            }
        }

        if structuredAddress.count > 1 {
            structuredData["address"] = structuredAddress
        }

        guard JSONSerialization.isValidJSONObject(structuredData),
              let jsonData = try? JSONSerialization.data(withJSONObject: structuredData, options: [.prettyPrinted, .sortedKeys]),
              let json = String(data: jsonData, encoding: .utf8) else {
            return "{}"
        }

        return json
    }

    private static func formatHours(_ ranges: [RestaurantJSONTimeRange]) -> String {
        guard !ranges.isEmpty else { return "Not provided yet" }
        return ranges
            .map { range in
                range.close.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    ? formatTime(range.open)
                    : "\(formatTime(range.open)) to \(formatTime(range.close))"
            }
            .joined(separator: ", ")
    }

    private static func makeHoursSummary(from hours: RestaurantJSONHours) -> String {
        let weekdayRanges = [
            hours.monday,
            hours.tuesday,
            hours.wednesday,
            hours.thursday,
            hours.friday,
            hours.saturday,
        ]

        if let first = weekdayRanges.first, !first.isEmpty, weekdayRanges.allSatisfy({ $0 == first }) {
            if !hours.sunday.isEmpty, hours.sunday != first {
                return "Mon-Sat \(formatHours(first)); Sun \(formatHours(hours.sunday))"
            }

            if !hours.sunday.isEmpty {
                return "Daily \(formatHours(first))"
            }

            return "Mon-Sat \(formatHours(first))"
        }

        if let firstOpenDay = weekdayRanges.first(where: { !$0.isEmpty }) {
            return formatHours(firstOpenDay)
        }

        if !hours.sunday.isEmpty {
            return "Sunday \(formatHours(hours.sunday))"
        }

        return "Hours not provided yet"
    }

    private static func formatTime(_ value: String) -> String {
        let parts = value.split(separator: ":")
        guard let first = parts.first,
              let hour = Int(first) else {
            return value
        }

        let minute = parts.dropFirst().first.flatMap { Int($0) } ?? 0
        let period = hour >= 12 ? "PM" : "AM"
        let displayHour = hour % 12 == 0 ? 12 : hour % 12

        if minute == 0 {
            return "\(displayHour) \(period)"
        }

        return String(format: "%d:%02d %@", displayHour, minute, period)
    }

    private static func fullAddressLine(from address: RestaurantJSONAddress) -> String {
        let cityStateZip = [
            address.city,
            [address.state, address.zip]
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
                .joined(separator: " "),
        ]
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: ", ")

        return [address.street, cityStateZip, address.country]
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: ", ")
    }

    private static func customerLocationName(from address: RestaurantJSONAddress) -> String {
        let city = address.city.trimmingCharacters(in: .whitespacesAndNewlines)
        if !city.isEmpty {
            return city
        }

        let state = address.state.trimmingCharacters(in: .whitespacesAndNewlines)
        if !state.isEmpty {
            return state
        }

        return ""
    }

    private static func makeMenuLead(from menu: RestaurantJSONMenu) -> String {
        let items = menu.categories
            .flatMap(\.items)
            .map(\.name)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .prefix(4)

        guard !items.isEmpty else {
            return "Featured dishes and prices will be posted here soon."
        }

        return "Popular picks include \(items.joined(separator: ", "))."
    }

    private static func makeVisitHeadline(restaurantName: String, locationName: String) -> String {
        let name = restaurantName.isEmpty ? "the restaurant" : restaurantName
        let location = locationName.trimmingCharacters(in: .whitespacesAndNewlines)

        if location.isEmpty {
            return "Visit \(name)"
        }

        return "Visit \(name) in \(location)"
    }

    private static func makeVisitCopy(from data: RestaurantJSON, locationName: String) -> String {
        let menuPhrase = makeVisitMenuPhrase(from: data.menu)
        let location = locationName.trimmingCharacters(in: .whitespacesAndNewlines)
        let story = publicStory(from: data.basics.description)

        if !menuPhrase.isEmpty, !location.isEmpty {
            return "Stop by for \(menuPhrase), and a friendly neighborhood meal in \(location)."
        }

        if !story.isEmpty {
            return story
        }

        return "Check the menu, hours, and location before your next visit."
    }

    private static func makeVisitMenuPhrase(from menu: RestaurantJSONMenu) -> String {
        menu.categories
            .flatMap(\.items)
            .map(\.name)
            .map(customerMenuLabel)
            .filter { !$0.isEmpty }
            .prefix(4)
            .joined(separator: ", ")
    }

    nonisolated private static func customerMenuLabel(from name: String) -> String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalized = trimmed.lowercased()

        if normalized.contains("cheeseburger") || normalized == "burger" || normalized == "burgers" {
            return "burgers"
        }

        if normalized.contains("sandwich") {
            return "sandwiches"
        }

        if normalized.contains("fries") {
            return "fries"
        }

        if normalized.contains("lemonade") {
            return "lemonade"
        }

        return normalized
    }

    private static func formatPrice(_ price: Double?) -> String {
        guard let price, price > 0 else {
            return "Price TBD"
        }

        return String(format: "$%.2f", price)
    }

    private static func slug(for name: String) -> String {
        let slug = name
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: "-")

        return slug.isEmpty ? "restaurant" : slug
    }

    private static func sanitizeHexColor(_ value: String, fallback: String) -> String {
        let pattern = /^#[0-9a-fA-F]{6}$/
        return value.wholeMatch(of: pattern) == nil ? fallback : value
    }

    private static func publicStory(from value: String) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        let prefixes = ["It's ", "Its ", "It is "]

        for prefix in prefixes where trimmed.range(of: prefix, options: [.caseInsensitive, .anchored]) != nil {
            let remainder = trimmed.dropFirst(prefix.count).trimmingCharacters(in: .whitespacesAndNewlines)
            return sentenceCased(String(remainder))
        }

        return trimmed
    }

    private static func sentenceCased(_ value: String) -> String {
        guard let first = value.first else {
            return value
        }

        return first.uppercased() + value.dropFirst()
    }

    private static func escape(_ value: String) -> String {
        value
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&#39;")
    }
}

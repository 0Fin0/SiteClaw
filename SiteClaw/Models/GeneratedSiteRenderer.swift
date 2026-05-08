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
        let description = escape(data.seo.description.isEmpty ? data.basics.description : data.seo.description)
        let restaurantName = escape(data.basics.name)
        let tagline = escape(data.basics.tagline.isEmpty ? draft.headline : data.basics.tagline)
        let story = escape(data.basics.description)
        let cuisine = escape(data.basics.cuisineType.joined(separator: " / "))
        let address = data.contact.address
        let addressLine = fullAddressLine(from: address)
        let addressDisplay = escape(addressLine.isEmpty ? "Location not provided yet" : addressLine)
        let phone = data.contact.phone.trimmingCharacters(in: .whitespacesAndNewlines)
        let phoneActionHTML = phone.isEmpty
            ? ""
            : #"<a class="button secondary" href="tel:\#(escape(phone))">Call \#(escape(phone))</a>"#
        let phoneCardHTML = phone.isEmpty
            ? "<p>Phone not provided yet</p>"
            : #"<p><a href="tel:\#(escape(phone))">\#(escape(phone))</a></p>"#
        let menuHTML = makeMenuHTML(from: data.menu)
        let hoursHTML = makeHoursHTML(from: data.hours)
        let keywords = escape(data.seo.keywords.joined(separator: ", "))
        let primaryColor = sanitizeHexColor(data.branding.primaryColor, fallback: "#0D1A2B")
        let accentColor = sanitizeHexColor(data.branding.accentColor, fallback: "#E84F3C")
        let callToAction = escape(draft.callToAction.isEmpty ? "View Menu" : draft.callToAction)

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
            body {
              margin: 0;
              font-family: Inter, ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
              color: var(--ink);
              background: var(--paper);
              line-height: 1.5;
            }
            a { color: inherit; }
            header {
              min-height: 64vh;
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
              padding: 22px clamp(20px, 5vw, 72px);
              font-weight: 800;
              letter-spacing: 0;
            }
            nav .links {
              display: flex;
              gap: 18px;
              font-size: 0.92rem;
            }
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
              gap: clamp(26px, 5vw, 64px);
              align-items: start;
            }
            .lead { color: var(--muted); font-size: 1.08rem; }
            .menu-grid {
              display: grid;
              gap: 14px;
            }
            .menu-item {
              display: grid;
              grid-template-columns: minmax(0, 1fr) auto;
              gap: 18px;
              padding: 18px 0;
              border-bottom: 1px solid var(--line);
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
            footer {
              padding: 34px 20px;
              text-align: center;
              color: var(--muted);
            }
            @media (max-width: 760px) {
              nav .links { display: none; }
              header { min-height: 72vh; }
              .split, .info-grid { grid-template-columns: 1fr; }
              .menu-item { grid-template-columns: 1fr; gap: 8px; }
            }
          </style>
          <script type="application/ld+json">
          \(makeStructuredData(from: data, slug: slug))
          </script>
        </head>
        <body>
          <header>
            <nav>
              <div>\(restaurantName)</div>
              <div class="links">
                <a href="#menu">Menu</a>
                <a href="#hours">Hours</a>
                <a href="#visit">Visit</a>
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
                <p class="lead">Selected dishes from the restaurant profile captured in SiteClaw.</p>
              </div>
              <div class="menu-grid">
                \(menuHTML)
              </div>
            </section>

            <section id="visit">
              <h2>Visit Us</h2>
              <div class="info-grid">
                <div class="info-card">
                  <h3>Address</h3>
                  <p>\(addressDisplay)</p>
                </div>
                <div class="info-card">
                  <h3>Phone</h3>
                  \(phoneCardHTML)
                </div>
                <div class="info-card" id="hours">
                  <h3>Hours</h3>
                  <ul class="hours-list">
                    \(hoursHTML)
                  </ul>
                </div>
              </div>
            </section>
          </main>

          <footer>
            <p>Generated by SiteClaw for \(restaurantName).</p>
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
            """
            <div class="menu-item">
              <div>
                <h3>\(escape(item.name))</h3>
                <p>\(escape(item.description))</p>
              </div>
              <div class="price">\(formatPrice(item.price))</div>
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
            "description": data.basics.description,
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
                    ? range.open
                    : "\(range.open)-\(range.close)"
            }
            .joined(separator: ", ")
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

    private static func formatPrice(_ price: Double) -> String {
        String(format: "$%.2f", price)
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

    private static func escape(_ value: String) -> String {
        value
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&#39;")
    }
}

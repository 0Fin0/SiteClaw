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
        let designBrief = data.designBrief.normalized
        let archetype = designBrief.resolvedArchetype
        let bodyClass = "archetype-\(archetype.rawValue)"
        let rawRestaurantName = data.basics.name.trimmingCharacters(in: .whitespacesAndNewlines)
        let restaurantName = escape(data.basics.name)
        let story = escape(publicStory(from: data.basics.description))
        let cuisineText = data.basics.cuisineType.joined(separator: " / ")
        let cuisine = escape(cuisineText)
        let address = data.contact.address
        let addressLine = fullAddressLine(from: address)
        let addressDisplay = escape(addressLine.isEmpty ? "Location coming soon" : addressLine)
        let locationName = customerLocationName(from: address)
        let tagline = escape(
            currentHeroTagline(
                from: data.basics.tagline.isEmpty ? draft.headline : data.basics.tagline,
                restaurantName: rawRestaurantName,
                cuisine: cuisineText,
                locationName: locationName
            )
        )
        let phone = data.contact.phone.trimmingCharacters(in: .whitespacesAndNewlines)
        let phoneHref = phoneHref(from: phone)
        let phoneCardHTML = phone.isEmpty
            ? ""
            : """
              <div class="info-card">
                <h3>Phone</h3>
                <p><a href="tel:\(escape(phoneHref))">\(escape(phone))</a></p>
              </div>
            """
        let cateringEmail = data.contact.cateringEmail.trimmingCharacters(in: .whitespacesAndNewlines)
        let cateringEmailCardHTML = mailtoHref(from: cateringEmail).map { href in
            """
              <div class="info-card">
                <h3>Catering Contact</h3>
                <p><a href="\(escape(href))">\(escape(cateringEmail))</a></p>
              </div>
            """
        } ?? ""
        let menuHTML = makeMenuHTML(from: data.menu)
        let uploadedMenuHTML = makeUploadedMenuHTML(from: data.menu.uploadedAsset)
        let fullMenuActionHTML = data.menu.uploadedAsset == nil
            ? ""
            : ##"<div class="menu-actions"><a class="button outline" href="#full-menu">View Full Menu</a></div>"##
        let menuLead = escape(makeMenuLead(from: data.menu, archetype: archetype))
        let hoursHTML = makeHoursHTML(from: data.hours)
        let keywords = escape(data.seo.keywords.joined(separator: ", "))
        let primaryColor = sanitizeHexColor(data.branding.primaryColor, fallback: "#0D1A2B")
        let accentColor = sanitizeHexColor(data.branding.accentColor, fallback: "#E84F3C")
        let fontFamily = fontFamily(for: data.branding.fontStyle)
        let preferredCallToAction = draft.callToAction.isEmpty ? designBrief.primaryCTA : draft.callToAction
        let heroActionsHTML = makeActionsHTML(
            primaryLabel: preferredCallToAction,
            secondaryLabels: designBrief.secondaryCTAs,
            data: data,
            secondaryClass: "secondary"
        )
        let visitActionsHTML = makeActionsHTML(
            primaryLabel: designBrief.primaryCTA,
            secondaryLabels: ["View Menu"] + designBrief.secondaryCTAs,
            data: data,
            secondaryClass: "secondary"
        )
        let storyHeading = escape(storyHeading(for: archetype))
        let menuHeading = escape(menuHeading(for: archetype))
        let ctaKicker = escape(ctaKicker(for: archetype))
        let visitHeadline = escape(makeVisitHeadline(restaurantName: rawRestaurantName, locationName: locationName))
        let visitCopy = escape(makeVisitCopy(from: data, locationName: locationName, archetype: archetype))
        let onlineLinksHTML = makeOnlineLinksHTML(
            from: data.visibility,
            features: data.features,
            restaurantName: rawRestaurantName
        )
        let growthToolsHTML = makeGrowthToolsHTML(from: data)
        let storySectionHTML = """
            <section class="split story-section">
              <div>
                <h2>\(storyHeading)</h2>
              </div>
              <p class="lead">\(story)</p>
            </section>
        """
        let menuSectionHTML = """
            <section id="menu" class="split menu-section">
              <div>
                <h2>\(menuHeading)</h2>
                <p class="lead">\(menuLead)</p>
              </div>
              <div>
                <div class="menu-grid">
                  \(menuHTML)
                </div>
                \(fullMenuActionHTML)
                \(uploadedMenuHTML)
              </div>
            </section>
        """
        let visitSectionHTML = """
            <section id="visit" class="visit-section">
              <h2>Visit Us</h2>
              <div class="info-grid">
                <div class="info-card" id="location">
                  <h3>Address</h3>
                  <p>\(addressDisplay)</p>
                </div>
                \(phoneCardHTML)
                \(cateringEmailCardHTML)
                <div class="info-card" id="hours">
                  <h3>Hours</h3>
                  <ul class="hours-list">
                    \(hoursHTML)
                  </ul>
                </div>
              </div>
            </section>
        """
        let ctaSectionHTML = """
            <section class="visit-cta" aria-label="Plan a visit">
              <div>
                <p class="section-kicker">\(ctaKicker)</p>
                <h2>\(visitHeadline)</h2>
                <p>\(visitCopy)</p>
              </div>
              <div class="actions">
                \(visitActionsHTML)
              </div>
            </section>
        """
        let orderedSectionsHTML = orderedSectionsHTML(
            archetype: archetype,
            storySection: storySectionHTML,
            menuSection: menuSectionHTML,
            visitSection: visitSectionHTML,
            ctaSection: ctaSectionHTML,
            onlineLinksSection: onlineLinksHTML,
            growthToolsSection: growthToolsHTML
        )

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
              font-family: \(fontFamily);
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
            body.archetype-fast_casual_order_first header {
              background:
                linear-gradient(135deg, rgba(109, 42, 34, 0.92), rgba(248, 201, 90, 0.72)),
                url("https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?auto=format&fit=crop&w=1600&q=80") center / cover;
            }
            body.archetype-fine_dining_reservation_first header {
              background:
                linear-gradient(135deg, rgba(12, 15, 22, 0.96), rgba(52, 38, 30, 0.84)),
                url("https://images.unsplash.com/photo-1414235077428-338989a2e8c0?auto=format&fit=crop&w=1600&q=80") center / cover;
            }
            body.archetype-cultural_heritage header {
              background:
                linear-gradient(135deg, rgba(67, 36, 24, 0.94), rgba(125, 67, 36, 0.74)),
                url("https://images.unsplash.com/photo-1551218808-94e220e084d2?auto=format&fit=crop&w=1600&q=80") center / cover;
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
            .button.outline {
              background: transparent;
              color: var(--primary);
              border: 1px solid var(--line);
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
            .dish-image {
              display: block;
              width: 100%;
              aspect-ratio: 4 / 3;
              object-fit: cover;
              border-radius: 8px;
              background: #F4F0E8;
            }
            .menu-item h3 { margin: 0 0 4px; font-size: 1.08rem; }
            .menu-item p { margin: 0; color: var(--muted); }
            .price { font-weight: 900; color: var(--accent); }
            body.archetype-fast_casual_order_first .menu-item {
              border-color: rgba(232, 79, 60, 0.22);
            }
            body.archetype-fine_dining_reservation_first .menu-item {
              box-shadow: none;
              background: transparent;
            }
            body.archetype-cultural_heritage .section-kicker,
            body.archetype-cultural_heritage .price {
              color: #9B4E2F;
            }
            .uploaded-menu {
              margin-top: 18px;
              padding: 16px;
              border: 1px solid var(--line);
              border-radius: 8px;
              background: white;
              box-shadow: 0 16px 34px rgba(13, 26, 43, 0.06);
              overflow: hidden;
            }
            .uploaded-menu h3 { margin: 0 0 6px; }
            .uploaded-menu p { margin: 0 0 12px; color: var(--muted); }
            .uploaded-menu-image,
            .uploaded-menu-frame {
              display: block;
              width: 100%;
              max-width: 100%;
              box-sizing: border-box;
              border: 1px solid var(--line);
              border-radius: 8px;
              background: #fff;
            }
            .uploaded-menu-image {
              height: auto;
              max-height: none;
              object-fit: contain;
            }
            .uploaded-menu-frame {
              min-height: 620px;
            }
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
            .menu-actions {
              margin-top: 16px;
            }
            .online-links {
              padding-bottom: 36px;
            }
            .growth-tools {
              padding-bottom: 36px;
            }
            .growth-tool-grid {
              display: grid;
              grid-template-columns: repeat(4, minmax(0, 1fr));
              gap: 12px;
            }
            .growth-tool-card {
              padding: 16px;
              border: 1px solid var(--line);
              border-radius: 8px;
              background: white;
              box-shadow: 0 12px 26px rgba(13, 26, 43, 0.05);
            }
            .growth-tool-card h3 { margin: 0 0 6px; }
            .growth-tool-card p { margin: 0; color: var(--muted); }
            .growth-tool-card a { color: var(--primary); font-weight: 800; }
            .online-link-grid {
              display: flex;
              flex-wrap: wrap;
              gap: 10px;
            }
            .online-link-grid a {
              display: inline-flex;
              align-items: center;
              min-height: 40px;
              padding: 0 14px;
              border: 1px solid var(--line);
              border-radius: 8px;
              color: var(--primary);
              font-weight: 800;
              background: white;
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
              .split, .info-grid, .menu-grid, .growth-tool-grid { grid-template-columns: 1fr; }
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
        <body class="\(bodyClass)">
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
                \(heroActionsHTML)
              </div>
            </div>
          </header>

          <main>
            \(orderedSectionsHTML)
          </main>

          <footer>
            <p>\(restaurantName) &middot; \(addressDisplay)</p>
          </footer>
        </body>
        </html>
        """
    }

    private struct RenderAction: Hashable {
        var label: String
        var href: String
        var isExternal: Bool
    }

    private static func orderedSectionsHTML(
        archetype: RestaurantSiteArchetype,
        storySection: String,
        menuSection: String,
        visitSection: String,
        ctaSection: String,
        onlineLinksSection: String,
        growthToolsSection: String
    ) -> String {
        let sections: [String]

        switch archetype {
        case .fastCasualOrderFirst:
            sections = [menuSection, ctaSection, storySection, visitSection, growthToolsSection, onlineLinksSection]
        case .fineDiningReservationFirst:
            sections = [storySection, ctaSection, menuSection, visitSection, growthToolsSection, onlineLinksSection]
        case .culturalHeritage:
            sections = [storySection, menuSection, ctaSection, visitSection, growthToolsSection, onlineLinksSection]
        case .neighborhoodUtility:
            sections = [storySection, menuSection, visitSection, ctaSection, growthToolsSection, onlineLinksSection]
        }

        return sections
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .joined(separator: "\n")
    }

    private static func makeActionsHTML(
        primaryLabel: String,
        secondaryLabels: [String],
        data: RestaurantJSON,
        secondaryClass: String
    ) -> String {
        var actions: [RenderAction] = []

        if let primary = makeAction(label: primaryLabel, data: data)
            ?? makeAction(label: "View Menu", data: data)
            ?? makeAction(label: "Call Now", data: data)
            ?? makeAction(label: "Get Directions", data: data) {
            actions.append(primary)
        }

        for label in secondaryLabels {
            guard let action = makeAction(label: label, data: data),
                  !actions.contains(where: { $0.href == action.href || $0.label == action.label }) else {
                continue
            }

            actions.append(action)
        }

        return actions.enumerated().map { index, action in
            let className = index == 0 ? "button" : "button \(secondaryClass)"
            let externalAttributes = action.isExternal ? #" target="_blank" rel="noopener""# : ""
            return #"<a class="\#(className)" href="\#(escape(action.href))"\#(externalAttributes)>\#(escape(action.label))</a>"#
        }
        .joined(separator: "\n")
    }

    private static func makeAction(label: String, data: RestaurantJSON) -> RenderAction? {
        let trimmed = label.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalized = trimmed.lowercased()
        let displayLabel = trimmed.isEmpty ? "View Menu" : trimmed

        if normalized.contains("order") {
            return externalAction(label: displayLabel, url: data.features.onlineOrderingURL)
        }

        if normalized.contains("reserve") || normalized.contains("reservation") || normalized.contains("book") {
            return externalAction(label: displayLabel, url: data.features.reservationURL)
        }

        if normalized.contains("gift") {
            return externalAction(label: displayLabel, url: data.features.giftCardURL)
        }

        if normalized.contains("catering") {
            return externalAction(label: displayLabel, url: data.features.cateringURL)
        }

        if normalized.contains("private") {
            return externalAction(label: displayLabel, url: data.features.privateDiningURL)
        }

        if normalized.contains("call") {
            let phone = data.contact.phone.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !phone.isEmpty else { return nil }
            return RenderAction(label: "Call \(phone)", href: "tel:\(phoneHref(from: phone))", isExternal: false)
        }

        if normalized.contains("direction") {
            let addressLine = fullAddressLine(from: data.contact.address)
            guard hasFullAddress(data.contact.address) else { return nil }
            return RenderAction(label: "Get Directions", href: mapsSearchURL(from: addressLine), isExternal: true)
        }

        if normalized.contains("visit") {
            return RenderAction(label: displayLabel, href: "#visit", isExternal: false)
        }

        return RenderAction(label: displayLabel, href: "#menu", isExternal: false)
    }

    private static func externalAction(label: String, url: String) -> RenderAction? {
        guard let safeURL = safeExternalURL(url) else {
            return nil
        }

        return RenderAction(label: label, href: safeURL, isExternal: true)
    }

    private static func safeExternalURL(_ value: String) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let components = URLComponents(string: trimmed),
              let scheme = components.scheme?.lowercased(),
              ["http", "https"].contains(scheme),
              components.host?.isEmpty == false else {
            return nil
        }

        return trimmed
    }

    private static func storyHeading(for archetype: RestaurantSiteArchetype) -> String {
        switch archetype {
        case .fineDiningReservationFirst:
            "The Experience"
        case .culturalHeritage:
            "Our Roots"
        case .fastCasualOrderFirst:
            "Made For Right Now"
        case .neighborhoodUtility:
            "Our Story"
        }
    }

    private static func menuHeading(for archetype: RestaurantSiteArchetype) -> String {
        switch archetype {
        case .fastCasualOrderFirst:
            "Best Sellers"
        case .fineDiningReservationFirst:
            "Menu"
        case .culturalHeritage:
            "Signature Dishes"
        case .neighborhoodUtility:
            "Featured Dishes"
        }
    }

    private static func menuFactLabel(for archetype: RestaurantSiteArchetype) -> String {
        switch archetype {
        case .fastCasualOrderFirst:
            "Best Sellers"
        case .fineDiningReservationFirst:
            "Menu"
        case .culturalHeritage:
            "Signatures"
        case .neighborhoodUtility:
            "Menu"
        }
    }

    private static func ctaKicker(for archetype: RestaurantSiteArchetype) -> String {
        switch archetype {
        case .fastCasualOrderFirst:
            "Order ahead"
        case .fineDiningReservationFirst:
            "Reservations"
        case .culturalHeritage:
            "Plan your visit"
        case .neighborhoodUtility:
            "Plan your visit"
        }
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
            let imageURL = item.imageURL?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let imageHTML = imageURL.isEmpty
                ? ""
                : #"<img class="dish-image" src="\#(escape(imageURL))" alt="\#(escape(item.name))">"#

            return """
            <div class="menu-item">
              \(imageHTML)
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

    private static func makeUploadedMenuHTML(from asset: RestaurantJSONUploadedMenuAsset?) -> String {
        guard let asset,
              !asset.dataURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return ""
        }

        let filename = escape(asset.filename.isEmpty ? "Uploaded menu" : asset.filename)
        let dataURL = escape(asset.dataURL)
        let mediaType = escape(asset.mediaType)

        if asset.kind == UploadedMenuAssetKind.pdf.rawValue {
            return """
            <div class="uploaded-menu" id="full-menu">
              <h3>Full Menu</h3>
              <p>View the latest uploaded menu from the restaurant.</p>
              <object class="uploaded-menu-frame" data="\(dataURL)" type="\(mediaType)">
                <a class="button" href="\(dataURL)">Open \(filename)</a>
              </object>
            </div>
            """
        }

        return """
        <div class="uploaded-menu" id="full-menu">
          <h3>Full Menu</h3>
          <p>View the latest uploaded menu from the restaurant.</p>
          <img class="uploaded-menu-image" src="\(dataURL)" alt="Uploaded menu \(filename)">
        </div>
        """
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

        if let email = safeEmail(data.contact.cateringEmail) {
            structuredData["email"] = email
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

        let sameAs = sameAsLinks(from: data.visibility)
        if !sameAs.isEmpty {
            structuredData["sameAs"] = sameAs
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

        return [address.street, cityStateZip]
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: ", ")
    }

    private static func hasFullAddress(_ address: RestaurantJSONAddress) -> Bool {
        !address.street.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !address.city.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !address.state.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !address.zip.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private static func phoneHref(from phone: String) -> String {
        let allowed = CharacterSet(charactersIn: "+0123456789")
        let cleaned = phone.unicodeScalars.filter { allowed.contains($0) }.map(String.init).joined()
        return cleaned.isEmpty ? phone : cleaned
    }

    private static func mailtoHref(from email: String) -> String? {
        safeEmail(email).map { "mailto:\($0)" }
    }

    private static func safeEmail(_ value: String) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.range(
            of: #"^[A-Z0-9._%+\-]+@[A-Z0-9.\-]+\.[A-Z]{2,}$"#,
            options: [.regularExpression, .caseInsensitive]
        ) != nil else {
            return nil
        }

        return trimmed
    }

    private static func mapsSearchURL(from address: String) -> String {
        let encoded = address.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? address
        return "https://www.google.com/maps/search/?api=1&query=\(encoded)"
    }

    private static func makeOnlineLinksHTML(
        from visibility: RestaurantJSONVisibility,
        features: RestaurantSiteFeatures,
        restaurantName: String
    ) -> String {
        let featureLinks = [
            ("Order Online", safeExternalURL(features.onlineOrderingURL)),
            ("Reserve a Table", safeExternalURL(features.reservationURL)),
            ("Gift Cards", safeExternalURL(features.giftCardURL)),
            ("Catering", safeExternalURL(features.cateringURL)),
            ("Private Dining", safeExternalURL(features.privateDiningURL))
        ]
            .compactMap { title, url in
                url.map { (title, $0) }
            }

        let socialLinks = [
            ("Google Business Profile", visibility.googleBusinessProfileURL),
            ("Google Reviews", visibility.googleReviewURL),
            ("Find us on Yelp", visibility.yelpBusinessURL),
            ("Instagram", visibility.instagramURL),
            ("Facebook", visibility.facebookURL)
        ]
        .compactMap { title, url in
            safeExternalURL(url).map { (title, $0) }
        }
        let links = featureLinks + socialLinks

        guard !links.isEmpty else { return "" }

        let linkHTML = links.map { title, url in
            #"<a href="\#(escape(url))" target="_blank" rel="noopener">\#(escape(title))</a>"#
        }
        .joined(separator: "\n")
        let headingName = restaurantName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? "the restaurant"
            : restaurantName

        return """
        <section class="online-links" aria-label="Find us online">
          <p class="section-kicker">Find us online</p>
          <h2>Follow \(escape(headingName))</h2>
          <div class="online-link-grid">
            \(linkHTML)
          </div>
        </section>
        """
    }

    private static func makeGrowthToolsHTML(from data: RestaurantJSON) -> String {
        let tools = data.growthTools
        var cards: [(title: String, detail: String, link: (label: String, href: String)?)] = []

        if tools.specialsEnabled {
            cards.append(("Specials", "Ask about current specials, seasonal dishes, and happy hour updates.", nil))
        }

        if tools.eventsEnabled {
            cards.append(("Events", "Check back for tastings, pop-ups, private events, and restaurant happenings.", nil))
        }

        if tools.cateringLeadFormEnabled {
            let cateringHref = safeExternalURL(data.features.cateringURL)
                ?? mailtoHref(from: data.contact.cateringEmail)
            cards.append(("Catering", "Plan office lunches, parties, and group orders with the restaurant team.", cateringHref.map { ("Catering Contact", $0) }))
        }

        if tools.giftCardsEnabled, let giftCardURL = safeExternalURL(data.features.giftCardURL) {
            cards.append(("Gift Cards", "Send a meal, celebrate a regular, or make the next visit easy.", ("Buy Gift Cards", giftCardURL)))
        }

        if tools.reviewLinksEnabled, let reviewURL = safeExternalURL(data.visibility.googleReviewURL) {
            cards.append(("Reviews", "Share feedback on Google after your visit.", ("Google Reviews", reviewURL)))
        }

        if tools.qrMenuEnabled {
            cards.append(("QR Menu", "Use this site as the restaurant's mobile menu for tables, flyers, and local promos.", nil))
        }

        if tools.newsletterEnabled {
            cards.append(("Updates", "Join future email updates for specials, events, and seasonal menus.", nil))
        }

        if tools.analyticsEnabled {
            cards.append(("Launch Insights", "Track which calls, menu views, and links matter after the site goes live.", nil))
        }

        guard !cards.isEmpty else { return "" }

        let cardsHTML = cards.map { card in
            let linkHTML = card.link.map { link in
                #"<p><a href="\#(escape(link.href))"\#(link.href.hasPrefix("http") ? #" target="_blank" rel="noopener""# : "")>\#(escape(link.label))</a></p>"#
            } ?? ""
            return """
            <div class="growth-tool-card">
              <h3>\(escape(card.title))</h3>
              <p>\(escape(card.detail))</p>
              \(linkHTML)
            </div>
            """
        }
        .joined(separator: "\n")

        return """
        <section class="growth-tools" aria-label="Restaurant tools">
          <p class="section-kicker">More ways to connect</p>
          <h2>Restaurant Tools</h2>
          <div class="growth-tool-grid">
            \(cardsHTML)
          </div>
        </section>
        """
    }

    private static func sameAsLinks(from visibility: RestaurantJSONVisibility) -> [String] {
        [
            visibility.googleBusinessProfileURL,
            visibility.yelpBusinessURL,
            visibility.instagramURL,
            visibility.facebookURL
        ]
        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        .compactMap { safeExternalURL($0) }
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

    private static func makeMenuLead(from menu: RestaurantJSONMenu, archetype: RestaurantSiteArchetype) -> String {
        let items = menu.categories
            .flatMap(\.items)
            .map(\.name)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .prefix(4)

        guard !items.isEmpty else {
            switch archetype {
            case .fineDiningReservationFirst:
                return "Menu details will be shared as the experience is finalized."
            case .fastCasualOrderFirst:
                return "Best sellers and ordering details will be posted here soon."
            case .culturalHeritage:
                return "Signature dishes and family favorites will be posted here soon."
            case .neighborhoodUtility:
                return "Featured dishes and prices will be posted here soon."
            }
        }

        switch archetype {
        case .fineDiningReservationFirst:
            return "A focused look at the dishes and experiences guests can expect, including \(items.joined(separator: ", "))."
        case .fastCasualOrderFirst:
            return "Customer favorites ready for pickup, delivery, or a quick visit: \(items.joined(separator: ", "))."
        case .culturalHeritage:
            return "Signature picks rooted in the restaurant's style include \(items.joined(separator: ", "))."
        case .neighborhoodUtility:
            return "Popular picks include \(items.joined(separator: ", "))."
        }
    }

    private static func makeVisitHeadline(restaurantName: String, locationName: String) -> String {
        let name = restaurantName.isEmpty ? "the restaurant" : restaurantName
        let location = locationName.trimmingCharacters(in: .whitespacesAndNewlines)

        if location.isEmpty {
            return "Visit \(name)"
        }

        return "Visit \(name) in \(location)"
    }

    private static func makeVisitCopy(from data: RestaurantJSON, locationName: String, archetype: RestaurantSiteArchetype) -> String {
        let menuPhrase = makeVisitMenuPhrase(from: data.menu)
        let location = locationName.trimmingCharacters(in: .whitespacesAndNewlines)
        let story = publicStory(from: data.basics.description)

        if archetype == .fineDiningReservationFirst {
            if !location.isEmpty {
                return "Reserve ahead, review the menu, and plan a polished dining experience in \(location)."
            }

            return "Reserve ahead, review the menu, and plan a polished dining experience."
        }

        if archetype == .fastCasualOrderFirst {
            if !menuPhrase.isEmpty, !location.isEmpty {
                return "Order ahead or stop by for \(menuPhrase) in \(location)."
            }

            return "Order ahead, check the menu, or stop by when you are nearby."
        }

        if !menuPhrase.isEmpty, !location.isEmpty {
            return "Stop by for \(menuPhrase), and a friendly neighborhood meal in \(location)."
        }

        if !story.isEmpty {
            return story
        }

        return "Check the menu, hours, and location before your next visit."
    }

    private static func currentHeroTagline(
        from rawTagline: String,
        restaurantName: String,
        cuisine: String,
        locationName: String
    ) -> String {
        let tagline = rawTagline.trimmingCharacters(in: .whitespacesAndNewlines)
        let name = restaurantName.trimmingCharacters(in: .whitespacesAndNewlines)

        if !tagline.isEmpty,
           (name.isEmpty || tagline.localizedCaseInsensitiveContains(name) || !tagline.localizedCaseInsensitiveContains("serves")) {
            return tagline
        }

        let offer = customerOfferPhrase(cuisine: cuisine)
        let displayName = name.isEmpty ? "This restaurant" : name
        let location = locationName.trimmingCharacters(in: .whitespacesAndNewlines)

        if location.isEmpty {
            return "\(displayName) serves \(offer)"
        }

        return "\(displayName) serves \(offer) in \(location)"
    }

    private static func customerOfferPhrase(cuisine: String) -> String {
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

        return "fresh food"
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

        if price.rounded() == price {
            return "$\(Int(price))"
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

    private static func fontFamily(for style: String) -> String {
        switch style.lowercased() {
        case "classic":
            return #"Georgia, "Times New Roman", serif"#
        case "friendly":
            return #""Avenir Next", Avenir, ui-sans-serif, system-ui, -apple-system, sans-serif"#
        default:
            return #"Inter, ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif"#
        }
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

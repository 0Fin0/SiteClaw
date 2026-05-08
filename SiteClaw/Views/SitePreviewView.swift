//
//  SitePreviewView.swift
//  SiteClaw
//

import SwiftUI
import UniformTypeIdentifiers

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

struct SitePreviewView: View {
    @Bindable var studio: SiteClawStudio

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    SectionHeader(
                        title: "Live Site Preview",
                        subtitle: "This is the restaurant website SiteClaw generated from the conversation."
                    )

                    RestaurantWebsiteMock(studio: studio)

                    DraftReadinessCard(studio: studio)

                    StaticSiteExportCard(studio: studio)

                    SEOSection(draft: studio.draft)
                }
                .padding(16)
            }
            .background(SiteClawTheme.background.ignoresSafeArea())
            .navigationTitle("Preview")
        }
    }
}

private struct StaticSiteExportCard: View {
    @Bindable var studio: SiteClawStudio
    @State private var exportDocument = SiteExportDocument()
    @State private var isExportingHTML = false
    @State private var didCopyHTML = false
    @State private var exportMessage: String?

    var body: some View {
        ClawCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Static Site Export")
                            .font(.title2.bold())
                        Text(studio.siteExportDetail)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer()

                    Image(systemName: "shippingbox.fill")
                        .font(.title2)
                        .foregroundStyle(SiteClawTheme.coral)
                }

                HStack {
                    ExportMetric(title: "File", value: "index.html")
                    ExportMetric(title: "Slug", value: studio.siteExport.slug)
                    ExportMetric(title: "Size", value: studio.siteExport.sizeLabel)
                }

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    Button {
                        studio.prepareSiteExport()
                        exportMessage = "Static site export prepared."
                    } label: {
                        Label("Prepare", systemImage: "hammer.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)

                    Button {
                        saveHTML()
                    } label: {
                        Label("Save HTML", systemImage: "square.and.arrow.down")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(SiteClawTheme.coral)

                    Button {
                        copyHTML()
                    } label: {
                        Label(didCopyHTML ? "Copied" : "Copy HTML", systemImage: didCopyHTML ? "checkmark" : "doc.on.doc")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }

                if let exportMessage {
                    Text(exportMessage)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(SiteClawTheme.mint)
                }
            }
        }
        .fileExporter(
            isPresented: $isExportingHTML,
            document: exportDocument,
            contentType: .html,
            defaultFilename: studio.siteExport.defaultFilename
        ) { result in
            switch result {
            case .success:
                exportMessage = "HTML file saved."
            case .failure(let error):
                exportMessage = error.localizedDescription
            }
        }
    }

    private func saveHTML() {
        let export = studio.siteExport
        studio.prepareSiteExport()
        exportDocument = SiteExportDocument(text: export.html)
        isExportingHTML = true
    }

    private func copyHTML() {
        let html = studio.siteExport.html
        studio.prepareSiteExport()

        #if os(iOS)
        UIPasteboard.general.string = html
        #elseif os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(html, forType: .string)
        #endif

        didCopyHTML = true
        exportMessage = "HTML copied."
    }
}

private struct ExportMetric: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.headline)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .foregroundStyle(SiteClawTheme.ink)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct RestaurantWebsiteMock: View {
    let studio: SiteClawStudio

    var body: some View {
        VStack(spacing: 0) {
            WebsiteHero(studio: studio)
            WebsiteStorySection(studio: studio)
            WebsiteMenuSection(menuItems: studio.restaurant.menuItems)
            WebsiteInfoSection(studio: studio)
        }
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(.black.opacity(0.08), lineWidth: 1)
        }
    }
}

private struct WebsiteHero: View {
    let studio: SiteClawStudio

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            AsyncImage(url: Self.backgroundImageURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                default:
                    LinearGradient(
                        colors: [SiteClawTheme.navy, SiteClawTheme.coral],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
            }
            .frame(maxWidth: .infinity, minHeight: 320)
            .clipped()

            LinearGradient(
                colors: [.black.opacity(0.76), .black.opacity(0.34), .black.opacity(0.16)],
                startPoint: .bottomLeading,
                endPoint: .topTrailing
            )

            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    Label(studio.restaurant.name.isEmpty ? "Restaurant" : studio.restaurant.name, systemImage: "fork.knife")
                        .font(.headline)
                    Spacer()
                    Text("Menu")
                        .font(.subheadline.weight(.semibold))
                }

                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 8) {
                        if !studio.restaurant.cuisine.isEmpty {
                            HeroPill(title: studio.restaurant.cuisine)
                        }
                        if !studio.restaurant.neighborhood.isEmpty {
                            HeroPill(title: studio.restaurant.neighborhood)
                        }
                    }

                    Text(studio.draft.headline)
                        .font(.largeTitle.bold())
                        .foregroundStyle(.white)
                        .frame(maxWidth: 780, alignment: .leading)
                    Text(studio.draft.subheadline)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.9))
                        .frame(maxWidth: 680, alignment: .leading)
                }

                Button {} label: {
                    Text(studio.draft.callToAction)
                        .font(.headline)
                        .foregroundStyle(SiteClawTheme.navy)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(SiteClawTheme.gold)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .buttonStyle(.plain)
            }
            .padding(22)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .foregroundStyle(.white)
    }

    private static let backgroundImageURL = URL(
        string: "https://images.unsplash.com/photo-1552566626-52f8b828add9?auto=format&fit=crop&w=1600&q=80"
    )
}

private struct HeroPill: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.caption.weight(.bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(.white.opacity(0.18))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct WebsiteStorySection: View {
    let studio: SiteClawStudio

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Why Customers Visit")
                .font(.title3.bold())
            Text(storyText)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            FlowLayout(spacing: 8) {
                if !studio.restaurant.cuisine.isEmpty {
                    LabelPill(title: studio.restaurant.cuisine, systemImage: "fork.knife", color: SiteClawTheme.mint)
                }
                if !studio.restaurant.neighborhood.isEmpty {
                    LabelPill(title: studio.restaurant.neighborhood, systemImage: "mappin.and.ellipse", color: SiteClawTheme.sky)
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .foregroundStyle(SiteClawTheme.ink)
        .background(.white)
    }

    private var storyText: String {
        let story = studio.restaurant.story.trimmingCharacters(in: .whitespacesAndNewlines)
        if !story.isEmpty {
            return story
        }

        return studio.draft.subheadline
    }
}

private struct WebsiteMenuSection: View {
    let menuItems: [MenuItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .firstTextBaseline) {
                Text("Featured Menu")
                    .font(.title3.bold())
                Spacer()
                Text(menuItems.isEmpty ? "Needs menu" : "\(menuItems.count) items")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(SiteClawTheme.mint)
            }

            if menuItems.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Menu not provided yet")
                        .font(.headline)
                    Text("Add owner-approved dishes and prices before publishing this section.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.vertical, 4)
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 220), spacing: 12)], spacing: 12) {
                    ForEach(menuItems) { item in
                        WebsiteMenuItemCard(item: item)
                    }
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .foregroundStyle(SiteClawTheme.ink)
        .background(.white)
    }
}

private struct WebsiteMenuItemCard: View {
    let item: MenuItem

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 10) {
                Text(item.name)
                    .font(.headline)
                    .foregroundStyle(SiteClawTheme.ink)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer()

                Text(priceLabel)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(hasPrice ? SiteClawTheme.coral : SiteClawTheme.gold)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 6)
                    .background((hasPrice ? SiteClawTheme.coral : SiteClawTheme.gold).opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }

            Text(descriptionText)
                .font(.caption)
                .foregroundStyle(hasDescription ? .secondary : SiteClawTheme.gold)
                .fixedSize(horizontal: false, vertical: true)

            Label(hasDescription ? "Owner-provided detail" : "Add description", systemImage: hasDescription ? "checkmark.circle" : "pencil")
                .font(.caption.weight(.semibold))
                .foregroundStyle(hasDescription ? SiteClawTheme.mint : SiteClawTheme.gold)
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 128, alignment: .topLeading)
        .background(Color(red: 0.99, green: 0.99, blue: 0.97))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(.black.opacity(0.07), lineWidth: 1)
        }
    }

    private var hasPrice: Bool {
        guard let price = item.price else { return false }
        return price > 0
    }

    private var hasDescription: Bool {
        !item.description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var priceLabel: String {
        guard let price = item.price, price > 0 else {
            return "Price TBD"
        }

        return price.formatted(.currency(code: "USD"))
    }

    private var descriptionText: String {
        let description = item.description.trimmingCharacters(in: .whitespacesAndNewlines)
        return description.isEmpty ? "Description not captured yet." : description
    }
}

private struct WebsiteInfoSection: View {
    let studio: SiteClawStudio

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Visit Us")
                .font(.title3.bold())

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 190), spacing: 12)], spacing: 12) {
                ContactFact(
                    title: "Location",
                    value: displayValue(studio.restaurant.formattedAddress, fallback: "Location not provided"),
                    isProvided: !studio.restaurant.formattedAddress.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                    systemImage: "mappin.and.ellipse"
                )
                ContactFact(
                    title: "Hours",
                    value: displayValue(studio.restaurant.hours, fallback: "Hours not provided"),
                    isProvided: !studio.restaurant.hours.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                    systemImage: "clock"
                )
                ContactFact(
                    title: "Phone",
                    value: displayValue(studio.restaurant.phone, fallback: "Phone not provided"),
                    isProvided: !studio.restaurant.phone.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                    systemImage: "phone"
                )
            }
        }
        .font(.subheadline)
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .foregroundStyle(SiteClawTheme.ink)
        .background(Color(red: 0.99, green: 0.96, blue: 0.88))
    }

    private func displayValue(_ value: String, fallback: String) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? fallback : trimmed
    }
}

private struct ContactFact: View {
    let title: String
    let value: String
    let isProvided: Bool
    let systemImage: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: systemImage)
                    .foregroundStyle(isProvided ? SiteClawTheme.mint : SiteClawTheme.gold)
                Spacer()
                Text(isProvided ? "Ready" : "Needed")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(isProvided ? SiteClawTheme.mint : SiteClawTheme.gold)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(SiteClawTheme.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 116, alignment: .topLeading)
        .background(.white.opacity(0.72))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(.black.opacity(0.06), lineWidth: 1)
        }
    }
}

private struct DraftReadinessCard: View {
    let studio: SiteClawStudio

    var body: some View {
        ClawCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Draft Readiness")
                            .font(.title2.bold())
                        Text(statusText)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Label("\(providedCount)/\(checks.count)", systemImage: "checklist")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(SiteClawTheme.mint)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(SiteClawTheme.mint.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 210), spacing: 10)], spacing: 10) {
                    ForEach(checks) { check in
                        DraftReadinessItem(check: check)
                    }
                }
            }
        }
    }

    private var checks: [DraftReadinessCheck] {
        [
            DraftReadinessCheck(
                title: "Restaurant Name",
                detail: displayStatus(studio.restaurant.name, fallback: "Needed before publishing"),
                isReady: !studio.restaurant.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                systemImage: "storefront"
            ),
            DraftReadinessCheck(
                title: "Menu Prices",
                detail: missingPriceCount == 0 && !studio.restaurant.menuItems.isEmpty
                    ? "All captured menu items include prices"
                    : "\(missingPriceCount) item\(missingPriceCount == 1 ? "" : "s") need prices",
                isReady: missingPriceCount == 0 && !studio.restaurant.menuItems.isEmpty,
                systemImage: "tag"
            ),
            DraftReadinessCheck(
                title: "Dish Descriptions",
                detail: missingDescriptionCount == 0 && !studio.restaurant.menuItems.isEmpty
                    ? "Menu descriptions are ready"
                    : "\(missingDescriptionCount) item\(missingDescriptionCount == 1 ? "" : "s") need descriptions",
                isReady: missingDescriptionCount == 0 && !studio.restaurant.menuItems.isEmpty,
                systemImage: "text.bubble"
            ),
            DraftReadinessCheck(
                title: "Street Address",
                detail: displayStatus(studio.restaurant.formattedAddress, fallback: "Optional, but useful for directions"),
                isReady: !studio.restaurant.streetAddress.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                systemImage: "mappin.and.ellipse"
            ),
            DraftReadinessCheck(
                title: "Phone",
                detail: displayStatus(studio.restaurant.phone, fallback: "Optional, but useful for customers"),
                isReady: !studio.restaurant.phone.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                systemImage: "phone"
            )
        ]
    }

    private var providedCount: Int {
        checks.filter(\.isReady).count
    }

    private var statusText: String {
        providedCount == checks.count
            ? "This draft has the basics needed for a more complete publish preview."
            : "SiteClaw can demo the site now, while clearly flagging details still missing from the owner."
    }

    private var missingPriceCount: Int {
        studio.restaurant.menuItems.filter { ($0.price ?? 0) <= 0 }.count
    }

    private var missingDescriptionCount: Int {
        studio.restaurant.menuItems.filter {
            $0.description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        .count
    }

    private func displayStatus(_ value: String, fallback: String) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? fallback : trimmed
    }
}

private struct DraftReadinessItem: View {
    let check: DraftReadinessCheck

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: check.systemImage)
                .foregroundStyle(check.isReady ? SiteClawTheme.mint : SiteClawTheme.gold)
                .frame(width: 24, height: 24)

            VStack(alignment: .leading, spacing: 3) {
                Text(check.title)
                    .font(.headline)
                Text(check.detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 86, alignment: .topLeading)
        .background((check.isReady ? SiteClawTheme.mint : SiteClawTheme.gold).opacity(0.09))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct DraftReadinessCheck: Identifiable {
    let id = UUID()
    var title: String
    var detail: String
    var isReady: Bool
    var systemImage: String
}

private struct SEOSection: View {
    let draft: WebsiteDraft

    var body: some View {
        VStack(spacing: 12) {
            SectionHeader(title: "AI Output", subtitle: "Generated pages and search phrases for local discovery.")

            ClawCard {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Pages")
                        .font(.headline)
                    TagWrap(tags: draft.pages, color: SiteClawTheme.sky)

                    Divider()

                    Text("Local SEO")
                        .font(.headline)
                    TagWrap(tags: draft.seoKeywords, color: SiteClawTheme.mint)
                }
            }
        }
    }
}

private struct TagWrap: View {
    let tags: [String]
    let color: Color

    var body: some View {
        FlowLayout(spacing: 8) {
            ForEach(tags, id: \.self) { tag in
                Text(tag)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(color)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(color.opacity(0.12))
                    .clipShape(Capsule())
            }
        }
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 320
        let rows = rows(for: subviews, maxWidth: width)
        let height = rows.reduce(CGFloat.zero) { total, row in
            total + row.height
        } + CGFloat(max(rows.count - 1, 0)) * spacing

        return CGSize(width: width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var origin = bounds.origin

        for row in rows(for: subviews, maxWidth: bounds.width) {
            origin.x = bounds.minX

            for item in row.items {
                item.subview.place(
                    at: CGPoint(x: origin.x, y: origin.y),
                    proposal: ProposedViewSize(item.size)
                )
                origin.x += item.size.width + spacing
            }

            origin.y += row.height + spacing
        }
    }

    private func rows(for subviews: Subviews, maxWidth: CGFloat) -> [FlowRow] {
        var rows: [FlowRow] = []
        var currentItems: [FlowItem] = []
        var currentWidth: CGFloat = 0
        var currentHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            let nextWidth = currentItems.isEmpty ? size.width : currentWidth + spacing + size.width

            if nextWidth > maxWidth && !currentItems.isEmpty {
                rows.append(FlowRow(items: currentItems, height: currentHeight))
                currentItems = [FlowItem(subview: subview, size: size)]
                currentWidth = size.width
                currentHeight = size.height
            } else {
                currentItems.append(FlowItem(subview: subview, size: size))
                currentWidth = nextWidth
                currentHeight = max(currentHeight, size.height)
            }
        }

        if !currentItems.isEmpty {
            rows.append(FlowRow(items: currentItems, height: currentHeight))
        }

        return rows
    }

    private struct FlowItem {
        let subview: LayoutSubview
        let size: CGSize
    }

    private struct FlowRow {
        let items: [FlowItem]
        let height: CGFloat
    }
}

#Preview {
    SitePreviewView(studio: SiteClawStudio.preview)
}

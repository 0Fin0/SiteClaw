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
            VStack(spacing: 0) {
                WebsiteMenuSection(menuItems: studio.restaurant.menuItems)
                Divider()
                WebsiteInfoSection(studio: studio)
            }
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
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label(studio.restaurant.name.isEmpty ? "Restaurant" : studio.restaurant.name, systemImage: "fork.knife")
                    .font(.headline)
                Spacer()
                Text("Menu")
                    .font(.subheadline.weight(.semibold))
            }

            VStack(alignment: .leading, spacing: 10) {
                Text(studio.draft.headline)
                    .font(.title.bold())
                    .foregroundStyle(.white)
                Text(studio.draft.subheadline)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.86))
            }

            Button {} label: {
                Text(studio.draft.callToAction)
                    .font(.headline)
                    .foregroundStyle(SiteClawTheme.navy)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(SiteClawTheme.gold)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [SiteClawTheme.navy, SiteClawTheme.coral],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .foregroundStyle(.white)
    }
}

private struct WebsiteMenuSection: View {
    let menuItems: [MenuItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Featured Menu")
                .font(.title3.bold())

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
                ForEach(menuItems) { item in
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.name)
                                .font(.headline)
                            Text(item.description)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Text(priceLabel(for: item))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle((item.price ?? 0) > 0 ? SiteClawTheme.coral : .secondary)
                    }
                    .padding(.vertical, 4)

                    if item.id != menuItems.last?.id {
                        Divider()
                    }
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .foregroundStyle(SiteClawTheme.ink)
        .background(.white)
    }

    private func priceLabel(for item: MenuItem) -> String {
        guard let price = item.price, price > 0 else {
            return "Price TBD"
        }

        return price.formatted(.currency(code: "USD"))
    }
}

private struct WebsiteInfoSection: View {
    let studio: SiteClawStudio

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Visit Us")
                .font(.title3.bold())

            ContactFact(
                title: "Location",
                value: displayValue(studio.restaurant.neighborhood, fallback: "Location not provided"),
                systemImage: "mappin.and.ellipse"
            )
            ContactFact(
                title: "Hours",
                value: displayValue(studio.restaurant.hours, fallback: "Hours not provided"),
                systemImage: "clock"
            )
            ContactFact(
                title: "Phone",
                value: displayValue(studio.restaurant.phone, fallback: "Phone not provided"),
                systemImage: "phone"
            )
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
    let systemImage: String

    var body: some View {
        Label {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(SiteClawTheme.ink)
            }
        } icon: {
            Image(systemName: systemImage)
                .foregroundStyle(SiteClawTheme.mint)
        }
        .labelStyle(.titleAndIcon)
    }
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

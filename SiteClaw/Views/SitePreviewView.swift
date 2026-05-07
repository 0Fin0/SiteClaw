//
//  SitePreviewView.swift
//  SiteClaw
//

import SwiftUI

struct SitePreviewView: View {
    let studio: SiteClawStudio

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    SectionHeader(
                        title: "Live Site Preview",
                        subtitle: "This is the restaurant website SiteClaw generated from the conversation."
                    )

                    RestaurantWebsiteMock(studio: studio)

                    SEOSection(draft: studio.draft)
                }
                .padding(16)
            }
            .background(SiteClawTheme.background.ignoresSafeArea())
            .navigationTitle("Preview")
        }
    }
}

private struct RestaurantWebsiteMock: View {
    let studio: SiteClawStudio

    var body: some View {
        VStack(spacing: 0) {
            WebsiteHero(studio: studio)
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

                    Text(item.price, format: .currency(code: "USD"))
                        .font(.subheadline.weight(.semibold))
                }
                .padding(.vertical, 4)

                if item.id != menuItems.last?.id {
                    Divider()
                }
            }
        }
        .padding(20)
    }
}

private struct WebsiteInfoSection: View {
    let studio: SiteClawStudio

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Visit Us")
                .font(.title3.bold())

            Label(studio.restaurant.neighborhood, systemImage: "mappin.and.ellipse")
            Label(studio.restaurant.hours, systemImage: "clock")
            Label(studio.restaurant.phone, systemImage: "phone")
        }
        .font(.subheadline)
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(red: 0.98, green: 0.95, blue: 0.88))
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

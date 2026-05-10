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
                    PreviewSummaryHeader(studio: studio)

                    MobileSitePreview(studio: studio)

                    ReviewExportEntryCard(studio: studio)
                }
                .padding(16)
                .padding(.bottom, SiteClawTheme.tabBarClearance)
            }
            .background(SiteClawTheme.background.ignoresSafeArea())
            .navigationTitle("Site Preview")
        }
    }
}

private struct ReviewExportEntryCard: View {
    let studio: SiteClawStudio

    var body: some View {
        NavigationLink {
            PreviewReviewExportView(studio: studio)
        } label: {
            ClawCard {
                HStack(alignment: .center, spacing: 12) {
                    Image(systemName: "shippingbox.fill")
                        .font(.title3.weight(.semibold))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(SiteClawTheme.sky)
                        .frame(width: 38, height: 38)
                        .background(SiteClawTheme.sky.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Review & Export")
                            .font(.headline)
                            .foregroundStyle(SiteClawTheme.ink)
                        Text("Owner checklist, HTML export, launch dashboard, and JSON proof.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 8)

                    Label("\(providedCoreCount)/3", systemImage: "checklist")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(SiteClawTheme.mint)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(SiteClawTheme.mint.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.secondary)
                }
                .contentShape(Rectangle())
            }
        }
        .buttonStyle(.plain)
    }

    private var providedCoreCount: Int {
        [hasRestaurantName, hasMenuPrices, hasDishDescriptions].filter { $0 }.count
    }

    private var hasRestaurantName: Bool {
        !studio.restaurant.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var hasMenuPrices: Bool {
        !studio.restaurant.menuItems.isEmpty && studio.restaurant.menuItems.allSatisfy { ($0.price ?? 0) > 0 }
    }

    private var hasDishDescriptions: Bool {
        !studio.restaurant.menuItems.isEmpty && studio.restaurant.menuItems.allSatisfy {
            !$0.description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }
}

private struct PreviewReviewExportView: View {
    @Bindable var studio: SiteClawStudio

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                DraftReadinessCard(studio: studio)

                StaticSiteExportCard(studio: studio)

                PreviewProofToolsCard(studio: studio)

                SEOSection(draft: studio.draft)
            }
            .padding(16)
            .padding(.bottom, SiteClawTheme.tabBarClearance)
        }
        .background(SiteClawTheme.background.ignoresSafeArea())
        .navigationTitle("Review & Export")
    }
}

private struct PreviewSummaryHeader: View {
    let studio: SiteClawStudio

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Generated Preview", systemImage: "iphone")
                .font(.caption.weight(.bold))
                .foregroundStyle(SiteClawTheme.coral)

            Text(studio.restaurant.name.isEmpty ? "Restaurant site preview" : studio.restaurant.name)
                .font(.title2.weight(.semibold))
                .foregroundStyle(SiteClawTheme.ink)
                .fixedSize(horizontal: false, vertical: true)

            Text("A mobile-first customer view built from the owner conversation.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct MobileSitePreview: View {
    let studio: SiteClawStudio

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "lock.fill")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(previewURL)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .background(SiteClawTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            RestaurantWebsiteMock(studio: studio)
        }
        .padding(10)
        .frame(maxWidth: 460)
        .background(SiteClawTheme.elevatedSurface)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(SiteClawTheme.separator, lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.10), radius: 24, y: 12)
        .frame(maxWidth: .infinity)
    }

    private var previewURL: String {
        studio.draft.url
            .replacingOccurrences(of: "https://", with: "")
            .replacingOccurrences(of: "http://", with: "")
    }
}

private struct StaticSiteExportCard: View {
    @Bindable var studio: SiteClawStudio
    @State private var exportDocument = SiteExportDocument()
    @State private var isExportingHTML = false
    @State private var didCopyHTML = false
    @State private var isPublishingLocalSite = false
    @State private var exportMessage: String?

    var body: some View {
        ClawCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Share Site")
                            .font(.title2.bold())
                        Text(exportDetail)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer()

                    Image(systemName: "shippingbox.fill")
                        .font(.title2)
                        .foregroundStyle(SiteClawTheme.coral)
                }

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    Button {
                        studio.prepareSiteExport()
                        exportMessage = "Site export is ready."
                    } label: {
                        Label("Refresh", systemImage: "arrow.clockwise")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)

                    Button {
                        publishLocalSite()
                    } label: {
                        Label(isPublishingLocalSite ? "Publishing" : "Open Site", systemImage: "safari")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(SiteClawTheme.mint)
                    .disabled(isPublishingLocalSite)

                    Button {
                        copyHTML()
                    } label: {
                        Label(didCopyHTML ? "Copied" : "Copy HTML", systemImage: didCopyHTML ? "checkmark" : "doc.on.doc")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)

                    Button {
                        saveHTML()
                    } label: {
                        Label("Save HTML", systemImage: "square.and.arrow.down")
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

    private var exportDetail: String {
        if studio.lastSiteExportedAt == nil {
            return "Save or copy the generated page when the owner-approved preview is ready."
        }

        return studio.siteExportDetail
    }

    private func saveHTML() {
        studio.prepareSiteExport()
        let export = studio.siteExport
        exportDocument = SiteExportDocument(text: export.html)
        isExportingHTML = true
    }

    private func copyHTML() {
        studio.prepareSiteExport()
        let html = studio.siteExport.html

        #if os(iOS)
        UIPasteboard.general.string = html
        #elseif os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(html, forType: .string)
        #endif

        didCopyHTML = true
        exportMessage = "HTML copied."
    }

    private func publishLocalSite() {
        isPublishingLocalSite = true

        Task { @MainActor in
            defer { isPublishingLocalSite = false }

            studio.prepareSiteExport()
            let export = studio.siteExport
            let request = LocalSitePublishRequest(
                slug: export.slug,
                html: export.html,
                restaurantJSON: studio.restaurantJSON
            )

            do {
                let response = try await LocalSitePublishService().publish(request: request)
                exportMessage = "Local site published at \(response.url)"

                if let url = URL(string: response.url) {
                    openExternalURL(url)
                }
            } catch {
                exportMessage = error.localizedDescription
            }
        }
    }

    private func openExternalURL(_ url: URL) {
        #if os(iOS)
        UIApplication.shared.open(url)
        #elseif os(macOS)
        NSWorkspace.shared.open(url)
        #endif
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

                    Text(displayName)
                        .font(.largeTitle.bold())
                        .foregroundStyle(.white)
                        .frame(maxWidth: 780, alignment: .leading)
                    Text(studio.draft.headline)
                        .font(.headline)
                        .foregroundStyle(.white.opacity(0.92))
                        .frame(maxWidth: 680, alignment: .leading)
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

    private var displayName: String {
        studio.restaurant.name.isEmpty ? "Restaurant" : studio.restaurant.name
    }
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
                Text(menuItems.isEmpty ? "Coming soon" : "\(menuItems.count) favorite\(menuItems.count == 1 ? "" : "s")")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(SiteClawTheme.mint)
            }

            if menuItems.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Menu not provided yet")
                        .font(.headline)
                    Text("Featured dishes will appear here after the owner approves the menu.")
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
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
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

    private var priceLabel: String {
        guard let price = item.price, price > 0 else {
            return "Price TBD"
        }

        return price.formatted(.currency(code: "USD"))
    }

    private var descriptionText: String {
        let description = item.description.trimmingCharacters(in: .whitespacesAndNewlines)
        return description.isEmpty ? "More details coming soon." : description
    }
}

private struct WebsiteInfoSection: View {
    let studio: SiteClawStudio

    var body: some View {
        if hasVisitDetails {
            VStack(alignment: .leading, spacing: 16) {
                Text("Visit Us")
                    .font(.title3.bold())

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 190), spacing: 12)], spacing: 12) {
                    if !locationText.isEmpty {
                        ContactFact(
                            title: "Location",
                            value: locationText,
                            systemImage: "mappin.and.ellipse"
                        )
                    }

                    if !hoursText.isEmpty {
                        ContactFact(
                            title: "Hours",
                            value: hoursText,
                            systemImage: "clock"
                        )
                    }

                    if !phoneText.isEmpty {
                        ContactFact(
                            title: "Phone",
                            value: phoneText,
                            systemImage: "phone"
                        )
                    }
                }
            }
            .font(.subheadline)
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .foregroundStyle(SiteClawTheme.ink)
            .background(Color(red: 0.99, green: 0.96, blue: 0.88))
        }
    }

    private var hasVisitDetails: Bool {
        !locationText.isEmpty || !hoursText.isEmpty || !phoneText.isEmpty
    }

    private var locationText: String {
        studio.restaurant.formattedAddress.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var hoursText: String {
        studio.restaurant.hours.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var phoneText: String {
        studio.restaurant.phone.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

private struct ContactFact: View {
    let title: String
    let value: String
    let systemImage: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: systemImage)
                    .foregroundStyle(SiteClawTheme.mint)
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 3) {
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
                        Text("Owner Review")
                            .font(.title2.bold())
                        Text(statusText)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Label("\(providedCount)/\(requiredCount)", systemImage: "checklist")
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
                detail: displayStatus(studio.restaurant.name, fallback: "Needed before final review"),
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
                detail: streetAddressStatus,
                isReady: !studio.restaurant.streetAddress.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                systemImage: "mappin.and.ellipse",
                isOptional: true
            ),
            DraftReadinessCheck(
                title: "Phone",
                detail: displayStatus(studio.restaurant.phone, fallback: "Optional, but useful for customers"),
                isReady: !studio.restaurant.phone.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                systemImage: "phone",
                isOptional: true
            )
        ]
    }

    private var providedCount: Int {
        checks.filter { !$0.isOptional && $0.isReady }.count
    }

    private var requiredCount: Int {
        checks.filter { !$0.isOptional }.count
    }

    private var statusText: String {
        providedCount == requiredCount
            ? "This preview has the core details customers expect."
            : "The preview is usable now, with a few details still worth confirming."
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

    private var streetAddressStatus: String {
        let streetAddress = studio.restaurant.streetAddress.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !streetAddress.isEmpty else {
            return "Optional, but useful for directions"
        }

        return studio.restaurant.formattedAddress
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
                if check.isOptional {
                    Text(check.isReady ? "Optional detail captured" : "Optional detail")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(SiteClawTheme.gold)
                }
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
    var isOptional = false
}

private struct PreviewProofToolsCard: View {
    let studio: SiteClawStudio

    var body: some View {
        VStack(spacing: 12) {
            SectionHeader(
                title: "Proof Tools",
                subtitle: "Launch signals and generated data kept one level below the demo path."
            )

            ClawCard {
                VStack(spacing: 0) {
                    NavigationLink {
                        DashboardContentView(studio: studio)
                    } label: {
                        ProofToolRow(
                            title: "Launch Dashboard",
                            detail: "\(studio.completionPercent)% complete - \(studio.publishStatus)",
                            systemImage: "chart.bar.xaxis",
                            color: SiteClawTheme.sky
                        )
                    }
                    .buttonStyle(.plain)

                    Divider()
                        .padding(.leading, 44)

                    NavigationLink {
                        RestaurantJSONContentView(studio: studio)
                    } label: {
                        ProofToolRow(
                            title: "Structured JSON",
                            detail: "\(studio.restaurant.menuItems.count) menu item\(studio.restaurant.menuItems.count == 1 ? "" : "s") - \(studio.draft.seoKeywords.count) SEO terms",
                            systemImage: "curlybraces",
                            color: SiteClawTheme.coral
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

private struct ProofToolRow: View {
    let title: String
    let detail: String
    let systemImage: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.headline)
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(color)
                .frame(width: 32, height: 32)
                .background(color.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(SiteClawTheme.ink)
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 10)
        .contentShape(Rectangle())
    }
}

private struct SEOSection: View {
    let draft: WebsiteDraft

    var body: some View {
        VStack(spacing: 12) {
            SectionHeader(title: "Search Preview", subtitle: "Pages and local phrases included with the generated site.")

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

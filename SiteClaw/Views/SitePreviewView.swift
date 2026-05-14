//
//  SitePreviewView.swift
//  SiteClaw
//

import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins
import UniformTypeIdentifiers

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif
#if canImport(WebKit)
import WebKit
#endif

struct SitePreviewView: View {
    @Bindable var studio: SiteClawStudio
    var scrollResetToken = 0
    @State private var isShowingFullscreenPreview = false
    @State private var selectedPreviewMode: PreviewDeviceMode = .phone

    private static let topAnchorID = "preview-top-anchor"

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 16) {
                        Color.clear
                            .frame(height: SiteClawTheme.topScrollResetClearance)
                            .id(Self.topAnchorID)
                        PreviewSummaryHeader(studio: studio)

                        OwnerApprovalCard(studio: studio)

                        PreviewFullscreenActionButton {
                            isShowingFullscreenPreview = true
                        }

                        PreviewModePicker(selectedMode: $selectedPreviewMode)

                        ReviewExportEntryCard(studio: studio)

                        MobileSitePreview(
                            studio: studio,
                            mode: selectedPreviewMode,
                            viewMenuAction: {
                                withAnimation(.snappy(duration: 0.35)) {
                                    proxy.scrollTo(PreviewScrollTarget.menu, anchor: .center)
                                }
                            }
                        )
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, SiteClawTheme.navigationContentTopInset)
                    .padding(.bottom, SiteClawTheme.tabBarClearance)
                }
                .background(SiteClawTheme.background.ignoresSafeArea())
                .onChange(of: scrollResetToken) { _, _ in
                    withAnimation(.snappy(duration: 0.35)) {
                        proxy.scrollTo(Self.topAnchorID, anchor: .top)
                    }
                }
            }
            .navigationTitle("Site Preview")
            .siteClawNavigationChrome()
            .accountSettingsToolbar(studio: studio)
        }
        #if os(iOS)
        .fullScreenCover(isPresented: $isShowingFullscreenPreview) {
            FullscreenGeneratedSitePreview(html: studio.siteExport.html)
        }
        #else
        .sheet(isPresented: $isShowingFullscreenPreview) {
            FullscreenGeneratedSitePreview(html: studio.siteExport.html)
        }
        #endif
    }
}

private enum PreviewScrollTarget {
    static let menu = "preview-menu-section"
}

private struct ReviewExportEntryCard: View {
    let studio: SiteClawStudio

    var body: some View {
        NavigationLink {
            PreviewReviewExportView(studio: studio)
        } label: {
            ClawCard {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(alignment: .center, spacing: 12) {
                        IconBadge(systemImage: "shippingbox.fill", color: SiteClawTheme.sky)

                        Text("Review & Publish")
                            .font(.headline)
                            .foregroundStyle(SiteClawTheme.ink)
                            .fixedSize(horizontal: false, vertical: true)

                        Spacer(minLength: 8)

                        StatusPill(title: "\(providedCoreCount)/3", systemImage: "checklist", color: SiteClawTheme.mint)

                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.secondary)
                            .accessibilityHidden(true)
                    }

                    Text("Owner approval, publish tools, launch dashboard, and JSON proof.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
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

                AIDesignStrategyReviewCard(studio: studio)

                WhatHappensNextCard()

                SiteQualityAuditCard(studio: studio)

                SEOSummaryCard(studio: studio)

                StaticSiteExportCard(studio: studio)

                DemoDataReassuranceCard()

                PreviewQAReportCard(studio: studio)

                PreviewSettingsCard(studio: studio)

                PublishHistoryCard(studio: studio)

                PreviewProofToolsCard(studio: studio)

                SEOSection(draft: studio.draft)
            }
            .padding(16)
            .padding(.bottom, SiteClawTheme.tabBarClearance)
        }
        .background(SiteClawTheme.background.ignoresSafeArea())
        .navigationTitle("Review & Publish")
        .siteClawNavigationChrome()
    }
}

private struct PreviewSettingsCard: View {
    let studio: SiteClawStudio

    var body: some View {
        VStack(spacing: 12) {
            SectionHeader(
                title: "Owner Settings",
                subtitle: "Account, restaurant, site, and billing controls kept below the main demo path."
            )

            ClawCard {
                NavigationLink {
                    AccountSettingsView(studio: studio)
                } label: {
                    ProofToolRow(
                        title: "Account & Settings",
                        detail: "\(studio.accountSettings.email) - \(studio.accountSettings.billingPlan)",
                        systemImage: "gearshape.fill",
                        color: SiteClawTheme.mint
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
}

private struct WhatHappensNextCard: View {
    private let steps = [
        "Review your site",
        "Add menu/contact details",
        "Publish or copy the preview link"
    ]

    var body: some View {
        ClawCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 12) {
                    IconBadge(systemImage: "list.number", color: SiteClawTheme.sky)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("What happens next")
                            .font(.headline)
                        Text("A simple owner approval path before anything goes live.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                VStack(spacing: 8) {
                    ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                        HStack(spacing: 10) {
                            Text("\(index + 1)")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.white)
                                .frame(width: 24, height: 24)
                                .background(SiteClawTheme.coral)
                                .clipShape(Circle())

                            Text(step)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(SiteClawTheme.ink)

                            Spacer(minLength: 0)
                        }
                    }
                }
            }
        }
    }
}

private struct DemoDataReassuranceCard: View {
    var body: some View {
        ClawCard {
            HStack(alignment: .top, spacing: 12) {
                IconBadge(systemImage: "lock.shield.fill", color: SiteClawTheme.mint)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Workspace privacy")
                        .font(.headline)
                    Text("Your uploaded menu and restaurant details stay in this workspace for the demo.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }
        }
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

private struct OwnerApprovalCard: View {
    let studio: SiteClawStudio

    var body: some View {
        ClawCard {
            HStack(alignment: .top, spacing: 12) {
                IconBadge(
                    systemImage: studio.isPublished ? "checkmark.seal.fill" : "eye.fill",
                    color: studio.isPublished ? SiteClawTheme.mint : SiteClawTheme.sky
                )

                VStack(alignment: .leading, spacing: 5) {
                    HStack(alignment: .center, spacing: 8) {
                        Text(studio.isPublished ? "Published" : "Preview only")
                            .font(.headline)
                            .foregroundStyle(SiteClawTheme.ink)

                        StatusPill(
                            title: studio.isPublished ? "Published" : "Not published yet",
                            systemImage: studio.isPublished ? "checkmark.circle.fill" : "lock.fill",
                            color: studio.isPublished ? SiteClawTheme.mint : SiteClawTheme.gold
                        )
                    }

                    Text(statusDetail)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }
        }
    }

    private var statusDetail: String {
        studio.isPublished
            ? "Your site is published. Refresh the preview before republishing any changes."
            : "Nothing goes live until you approve it. Review the phone preview, then publish when ready."
    }
}

private struct PreviewFullscreenActionButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label("Fullscreen Preview", systemImage: "arrow.up.left.and.arrow.down.right")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 7)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .tint(SiteClawTheme.sky)
        .accessibilityLabel("Fullscreen preview")
    }
}

private struct PreviewModePicker: View {
    @Binding var selectedMode: PreviewDeviceMode

    var body: some View {
        ClawCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Label("Preview QA", systemImage: "rectangle.on.rectangle")
                        .font(.headline)
                    Spacer()
                    StatusPill(title: selectedMode.title, systemImage: selectedMode.systemImage, color: SiteClawTheme.sky)
                }

                Picker("Preview size", selection: $selectedMode) {
                    ForEach(PreviewDeviceMode.allCases) { mode in
                        Label(mode.title, systemImage: mode.systemImage).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .accessibilityLabel("Preview size")
            }
        }
    }
}

private struct MobileSitePreview: View {
    let studio: SiteClawStudio
    let mode: PreviewDeviceMode
    let viewMenuAction: () -> Void

    var body: some View {
        content
    }

    private var content: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "lock.fill")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
                Text(previewURL)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Spacer(minLength: 8)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .background(SiteClawTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: SiteClawTheme.Radius.card, style: .continuous))

            SiteHTMLWebView(html: studio.siteExport.html)
                .frame(height: mode.previewHeight)
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: SiteClawTheme.Radius.card, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: SiteClawTheme.Radius.card, style: .continuous)
                        .stroke(.black.opacity(0.08), lineWidth: 1)
                }
                .accessibilityLabel("Generated website preview")
        }
        .padding(8)
        .frame(maxWidth: mode.previewWidth)
        .background(SiteClawTheme.elevatedSurface)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(SiteClawTheme.separator, lineWidth: 1)
        }
        .shadow(color: SiteClawTheme.Shadow.cardColor, radius: 18, y: 8)
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
    @State private var didCopySiteURL = false
    @State private var isPublishingLocalSite = false
    @State private var exportMessage: String?
    @State private var exportMessageIsError = false
    @State private var publishedSite: LocalSitePublishResponse?
    @State private var isShowingFullscreenPreview = false

    var body: some View {
        ClawCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Publish or Share")
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

                OwnerSafetyInlineStatus(isPublished: studio.isPublished)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    Button {
                        isShowingFullscreenPreview = true
                    } label: {
                        Label("Fullscreen Preview", systemImage: "arrow.up.left.and.arrow.down.right")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(SiteClawTheme.sky)
                    .accessibilityLabel("Fullscreen preview")

                    Button {
                        publishLocalSite()
                    } label: {
                        Label(isPublishingLocalSite ? "Publishing" : "Open Site", systemImage: "safari")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(SiteClawTheme.mint)
                    .disabled(isPublishingLocalSite || !studio.canPublishSite)

                    Button {
                        studio.prepareSiteExport()
                        publishedSite = nil
                        didCopySiteURL = false
                        exportMessage = "Site export refreshed. Open Site to publish the latest version."
                        exportMessageIsError = false
                    } label: {
                        Label("Refresh", systemImage: "arrow.clockwise")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)

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

                if let publishedSite {
                    PublishedSiteSuccessCard(
                        response: publishedSite,
                        didCopySiteURL: didCopySiteURL,
                        copyAction: copyPublishedSiteURL,
                        openAction: {
                            if let url = URL(string: publishedSite.url) {
                                openExternalURL(url)
                            }
                        }
                    )
                }

                if let exportMessage {
                    Text(exportMessage)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(exportMessageIsError ? SiteClawTheme.coral : SiteClawTheme.mint)
                        .fixedSize(horizontal: false, vertical: true)
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
                exportMessageIsError = false
            case .failure(let error):
                exportMessage = error.localizedDescription
                exportMessageIsError = true
            }
        }
        #if os(iOS)
        .fullScreenCover(isPresented: $isShowingFullscreenPreview) {
            FullscreenGeneratedSitePreview(html: studio.siteExport.html)
        }
        #else
        .sheet(isPresented: $isShowingFullscreenPreview) {
            FullscreenGeneratedSitePreview(html: studio.siteExport.html)
        }
        #endif
    }

    private var exportDetail: String {
        if studio.lastSiteExportedAt == nil {
            return "Review the preview first, then publish or copy the generated page when ready."
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
        exportMessageIsError = false
    }

    private func publishLocalSite() {
        guard studio.canPublishSite else {
            exportMessage = "Fix \(studio.blockingQualityIssues.count) publish blocker\(studio.blockingQualityIssues.count == 1 ? "" : "s") before opening the site."
            exportMessageIsError = true
            return
        }

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
                publishedSite = response
                studio.recordLocalPublish(response)
                didCopySiteURL = false
                exportMessage = "Published site is ready."
                exportMessageIsError = false

                if let url = URL(string: response.url) {
                    openExternalURL(url)
                }
            } catch {
                exportMessage = error.localizedDescription
                exportMessageIsError = true
            }
        }
    }

    private func copyPublishedSiteURL() {
        guard let publishedSite else { return }

        copyToPasteboard(publishedSite.url)
        didCopySiteURL = true
        exportMessage = "Site link copied."
        exportMessageIsError = false
    }

    private func copyToPasteboard(_ text: String) {
        #if os(iOS)
        UIPasteboard.general.string = text
        #elseif os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        #endif
    }

    private func openExternalURL(_ url: URL) {
        #if os(iOS)
        UIApplication.shared.open(url)
        #elseif os(macOS)
        NSWorkspace.shared.open(url)
        #endif
    }
}

private struct OwnerSafetyInlineStatus: View {
    let isPublished: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: isPublished ? "checkmark.seal.fill" : "lock.fill")
                .foregroundStyle(isPublished ? SiteClawTheme.mint : SiteClawTheme.gold)
                .frame(width: 24, height: 24)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                Text(isPublished ? "Published" : "Not published yet")
                    .font(.headline)
                    .foregroundStyle(SiteClawTheme.ink)
                Text(isPublished ? "Your site is live from the local publish flow." : "Nothing goes live until you approve it.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background((isPublished ? SiteClawTheme.mint : SiteClawTheme.gold).opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct PublishedSiteSuccessCard: View {
    let response: LocalSitePublishResponse
    let didCopySiteURL: Bool
    let copyAction: () -> Void
    let openAction: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.title2)
                    .foregroundStyle(SiteClawTheme.mint)
                    .frame(width: 40, height: 40)
                    .background(SiteClawTheme.mint.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text("Published Site")
                        .font(.headline)
                    Text("Ready to open, copy, or scan during the demo.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 8)
            }

            Text(response.url)
                .font(.caption.monospaced())
                .foregroundStyle(SiteClawTheme.sky)
                .lineLimit(2)
                .textSelection(.enabled)
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(SiteClawTheme.sky.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            HStack(alignment: .center, spacing: 14) {
                SiteQRCodeView(text: response.url)
                    .frame(width: 104, height: 104)
                    .padding(10)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(SiteClawTheme.separator, lineWidth: 1)
                    }

                VStack(spacing: 10) {
                    Button(action: copyAction) {
                        Label(didCopySiteURL ? "Link Copied" : "Copy Site Link", systemImage: didCopySiteURL ? "checkmark" : "link")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(SiteClawTheme.sky)

                    Button(action: openAction) {
                        Label("Open Again", systemImage: "safari")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
        .padding(14)
        .background(SiteClawTheme.mint.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(SiteClawTheme.mint.opacity(0.22), lineWidth: 1)
        }
    }
}

private struct SiteQRCodeView: View {
    let text: String

    private static let context = CIContext()

    var body: some View {
        if let cgImage = makeQRCodeImage() {
            Image(decorative: cgImage, scale: 1, orientation: .up)
                .interpolation(.none)
                .resizable()
                .scaledToFit()
                .accessibilityLabel("QR code for published site")
        } else {
            Image(systemName: "qrcode")
                .font(.system(size: 72, weight: .regular))
                .foregroundStyle(.secondary)
        }
    }

    private func makeQRCodeImage() -> CGImage? {
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(text.utf8)
        filter.correctionLevel = "M"

        guard let outputImage = filter.outputImage else {
            return nil
        }

        let scaledImage = outputImage.transformed(by: CGAffineTransform(scaleX: 12, y: 12))
        return Self.context.createCGImage(scaledImage, from: scaledImage.extent)
    }
}

private struct RestaurantWebsiteMock: View {
    let studio: SiteClawStudio
    let viewMenuAction: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            WebsiteHero(studio: studio, viewMenuAction: viewMenuAction)
            ForEach(spec.sectionOrder, id: \.self) { section in
                sectionView(section)
            }
            WebsiteGrowthToolsSection(studio: studio)
        }
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(.black.opacity(0.08), lineWidth: 1)
        }
    }

    private var spec: RestaurantArchetypePreviewSpec {
        RestaurantArchetypePreviewSpec.spec(for: studio.draft.designBrief.resolvedArchetype)
    }

    @ViewBuilder
    private func sectionView(_ section: RestaurantPreviewSection) -> some View {
        switch section {
        case .story:
            WebsiteStorySection(studio: studio, spec: spec)
        case .menu:
            WebsiteMenuSection(
                menuItems: studio.restaurant.menuItems,
                uploadedMenu: studio.restaurant.uploadedMenu,
                spec: spec
            )
            .id(PreviewScrollTarget.menu)
        case .visit:
            WebsiteInfoSection(studio: studio)
        }
    }
}

private struct WebsiteHero: View {
    let studio: SiteClawStudio
    let viewMenuAction: () -> Void

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            AsyncImage(url: backgroundImageURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                default:
                    LinearGradient(
                        colors: heroGradientColors,
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
                    Button(action: viewMenuAction) {
                        Text("Menu")
                            .font(.subheadline.weight(.semibold))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Jump to menu")
                }

                VStack(alignment: .leading, spacing: 10) {
                    HeroPill(title: spec.heroKicker)

                    FlowLayout(spacing: 8) {
                        if !studio.restaurant.cuisine.isEmpty {
                            HeroPill(title: studio.restaurant.cuisine)
                        }
                        if !locationLabel.isEmpty {
                            HeroPill(title: locationLabel)
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

                FlowLayout(spacing: 8) {
                    primaryCTAView

                    if let phoneURL {
                        Link(destination: phoneURL) {
                            HeroActionLabel(title: "Call", isPrimary: false)
                        }
                    }

                    if let directionsURL {
                        Link(destination: directionsURL) {
                            HeroActionLabel(title: "Get Directions", isPrimary: false)
                        }
                    }
                }
            }
            .padding(22)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .foregroundStyle(.white)
    }

    @ViewBuilder
    private var primaryCTAView: some View {
        if let primaryURL {
            Link(destination: primaryURL) {
                HeroActionLabel(title: primaryCTALabel, isPrimary: true, tint: heroAccentColor)
            }
        } else {
            Button(action: viewMenuAction) {
                HeroActionLabel(title: primaryCTALabel, isPrimary: true, tint: heroAccentColor)
            }
            .buttonStyle(.plain)
        }
    }

    private var spec: RestaurantArchetypePreviewSpec {
        RestaurantArchetypePreviewSpec.spec(for: studio.draft.designBrief.resolvedArchetype)
    }

    private var primaryCTALabel: String {
        let draftCTA = studio.draft.callToAction.trimmingCharacters(in: .whitespacesAndNewlines)
        return draftCTA.isEmpty ? spec.primaryCTA : draftCTA
    }

    private var primaryURL: URL? {
        let features = studio.restaurant.features
        switch studio.draft.designBrief.resolvedArchetype {
        case .fastCasualOrderFirst:
            return safeURL(features.onlineOrderingURL)
        case .fineDiningReservationFirst:
            return safeURL(features.reservationURL)
        case .culturalHeritage:
            return safeURL(features.onlineOrderingURL)
        case .neighborhoodUtility:
            return nil
        }
    }

    private var backgroundImageURL: URL? {
        let urlString: String
        switch studio.draft.designBrief.resolvedArchetype {
        case .neighborhoodUtility:
            urlString = "https://images.unsplash.com/photo-1552566626-52f8b828add9?auto=format&fit=crop&w=1600&q=80"
        case .fastCasualOrderFirst:
            urlString = "https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?auto=format&fit=crop&w=1600&q=80"
        case .fineDiningReservationFirst:
            urlString = "https://images.unsplash.com/photo-1414235077428-338989a2e8c0?auto=format&fit=crop&w=1600&q=80"
        case .culturalHeritage:
            urlString = "https://images.unsplash.com/photo-1551218808-94e220e084d2?auto=format&fit=crop&w=1600&q=80"
        }
        return URL(string: urlString)
    }

    private var heroGradientColors: [Color] {
        switch studio.draft.designBrief.resolvedArchetype {
        case .neighborhoodUtility:
            [SiteClawTheme.navy, SiteClawTheme.coral]
        case .fastCasualOrderFirst:
            [SiteClawTheme.coral, SiteClawTheme.gold]
        case .fineDiningReservationFirst:
            [Color.black, SiteClawTheme.navy]
        case .culturalHeritage:
            [Color(red: 0.34, green: 0.18, blue: 0.12), SiteClawTheme.gold]
        }
    }

    private var heroAccentColor: Color {
        switch studio.draft.designBrief.resolvedArchetype {
        case .neighborhoodUtility:
            SiteClawTheme.gold
        case .fastCasualOrderFirst:
            .white
        case .fineDiningReservationFirst:
            SiteClawTheme.gold
        case .culturalHeritage:
            SiteClawTheme.gold
        }
    }

    private var displayName: String {
        studio.restaurant.name.isEmpty ? "Restaurant" : studio.restaurant.name
    }

    private var locationLabel: String {
        if studio.restaurant.hasFullAddress {
            return studio.restaurant.formattedAddress
        }

        return studio.restaurant.neighborhood
    }

    private var phoneURL: URL? {
        let phone = studio.restaurant.phone.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !phone.isEmpty else { return nil }
        let allowed = CharacterSet(charactersIn: "+0123456789")
        let cleaned = phone.unicodeScalars.filter { allowed.contains($0) }.map(String.init).joined()
        return URL(string: "tel:\(cleaned.isEmpty ? phone : cleaned)")
    }

    private var directionsURL: URL? {
        guard studio.restaurant.hasFullAddress else { return nil }
        let address = studio.restaurant.formattedAddress
        let encoded = address.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? address
        return URL(string: "https://www.google.com/maps/search/?api=1&query=\(encoded)")
    }

    private func safeURL(_ value: String) -> URL? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: trimmed),
              let scheme = url.scheme?.lowercased(),
              ["http", "https"].contains(scheme),
              url.host?.isEmpty == false else {
            return nil
        }

        return url
    }
}

private struct HeroActionLabel: View {
    let title: String
    let isPrimary: Bool
    var tint: Color = SiteClawTheme.gold

    var body: some View {
        Text(title)
            .font(.headline)
            .foregroundStyle(isPrimary ? SiteClawTheme.navy : .white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(isPrimary ? tint : .white.opacity(0.16))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay {
                if !isPrimary {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(.white.opacity(0.28), lineWidth: 1)
                }
            }
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
    let spec: RestaurantArchetypePreviewSpec

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(spec.storyHeading)
                .font(.title3.bold())
            Text(storyText)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            FlowLayout(spacing: 8) {
                if !studio.restaurant.cuisine.isEmpty {
                    LabelPill(title: studio.restaurant.cuisine, systemImage: "fork.knife", color: SiteClawTheme.mint)
                }
                if !locationLabel.isEmpty {
                    LabelPill(title: locationLabel, systemImage: "mappin.and.ellipse", color: SiteClawTheme.sky)
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

    private var locationLabel: String {
        if studio.restaurant.hasFullAddress {
            return studio.restaurant.formattedAddress
        }

        return studio.restaurant.neighborhood
    }
}

private struct WebsiteMenuSection: View {
    let menuItems: [MenuItem]
    let uploadedMenu: UploadedMenuAsset?
    let spec: RestaurantArchetypePreviewSpec

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .firstTextBaseline) {
                Text(spec.menuHeading)
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
                        WebsiteMenuItemCard(item: item, archetype: spec.archetype)
                    }
                }
            }

            if let uploadedMenu {
                UploadedMenuPreviewCard(uploadedMenu: uploadedMenu)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .foregroundStyle(SiteClawTheme.ink)
        .background(.white)
    }
}

private struct UploadedMenuPreviewCard: View {
    let uploadedMenu: UploadedMenuAsset
    @State private var isShowingFullMenu = false

    var body: some View {
        content
            #if os(iOS)
            .fullScreenCover(isPresented: $isShowingFullMenu) {
                FullscreenUploadedMenuView(uploadedMenu: uploadedMenu)
            }
            #else
            .sheet(isPresented: $isShowingFullMenu) {
                FullscreenUploadedMenuView(uploadedMenu: uploadedMenu)
            }
            #endif
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: uploadedMenu.kind == .pdf ? "doc.richtext.fill" : "photo.fill")
                    .foregroundStyle(SiteClawTheme.sky)
                    .frame(width: 28, height: 28)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 3) {
                    Text("Full Menu")
                        .font(.headline)
                    Text("\(uploadedMenu.filename) - \(uploadedMenu.sizeLabel)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Spacer(minLength: 8)

                Button {
                    isShowingFullMenu = true
                } label: {
                    Label("View Full Menu", systemImage: "arrow.up.left.and.arrow.down.right")
                        .font(.caption.weight(.bold))
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .accessibilityLabel("View full menu")
            }

            if uploadedMenu.kind == .image, let image = platformImage(from: uploadedMenu) {
                image
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            } else if uploadedMenu.kind == .image,
                      uploadedMenu.mediaType.localizedCaseInsensitiveContains("svg") {
                svgImagePreview
            } else {
                fallbackPreview
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(SiteClawTheme.sky.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(SiteClawTheme.sky.opacity(0.22), lineWidth: 1)
        }
    }

    @ViewBuilder
    private var svgImagePreview: some View {
        #if canImport(WebKit)
        MenuAssetWebPreview(dataURL: uploadedMenu.dataURL)
            .frame(maxWidth: .infinity)
            .aspectRatio(Self.menuAspectRatio, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(SiteClawTheme.separator, lineWidth: 1)
            }
        #else
        fallbackPreview
        #endif
    }

    private var fallbackPreview: some View {
        Text(uploadedMenu.kind == .pdf ? "PDF menu will be embedded on the published site." : "Uploaded menu image is ready for the published site.")
            .font(.caption)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(SiteClawTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func platformImage(from uploadedMenu: UploadedMenuAsset) -> Image? {
        guard let base64 = uploadedMenu.dataURL.components(separatedBy: "base64,").last,
              let data = Data(base64Encoded: base64) else {
            return nil
        }

        #if os(iOS)
        guard let image = UIImage(data: data) else { return nil }
        return Image(uiImage: image)
        #elseif os(macOS)
        guard let image = NSImage(data: data) else { return nil }
        return Image(nsImage: image)
        #else
        return nil
        #endif
    }

    private static let menuAspectRatio: CGFloat = 11.0 / 16.0
}

#if os(iOS) && canImport(WebKit)
private struct MenuAssetWebPreview: UIViewRepresentable {
    let dataURL: String

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.isScrollEnabled = false
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        webView.loadHTMLString(html, baseURL: nil)
    }

    private var html: String {
        """
        <html>
          <head>
            <meta name="viewport" content="width=device-width, initial-scale=1">
            <style>html,body{margin:0;background:transparent;}img{display:block;width:100%;height:auto;}</style>
          </head>
          <body><img src="\(dataURL)" alt="Uploaded menu"></body>
        </html>
        """
    }
}
#elseif os(macOS) && canImport(WebKit)
private struct MenuAssetWebPreview: NSViewRepresentable {
    let dataURL: String

    func makeNSView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.setValue(false, forKey: "drawsBackground")
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        webView.loadHTMLString(html, baseURL: nil)
    }

    private var html: String {
        """
        <html>
          <head>
            <meta name="viewport" content="width=device-width, initial-scale=1">
            <style>html,body{margin:0;background:transparent;overflow:hidden;}img{display:block;width:100%;height:auto;}</style>
          </head>
          <body><img src="\(dataURL)" alt="Uploaded menu"></body>
        </html>
        """
    }
}
#endif

private struct FullscreenGeneratedSitePreview: View {
    let html: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            SiteHTMLWebView(html: html)
                .background(.white)
                .navigationTitle("Website Preview")
                #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
                #endif
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Done") {
                            dismiss()
                        }
                    }
                }
        }
    }
}

private struct FullscreenUploadedMenuView: View {
    let uploadedMenu: UploadedMenuAsset
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            SiteHTMLWebView(html: menuHTML)
                .background(.white)
                .navigationTitle("Full Menu")
                #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
                #endif
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Done") {
                            dismiss()
                        }
                    }
                }
        }
    }

    private var menuHTML: String {
        let dataURL = htmlAttribute(uploadedMenu.dataURL)
        let mediaType = htmlAttribute(uploadedMenu.mediaType)
        let filename = htmlAttribute(uploadedMenu.filename)

        if uploadedMenu.kind == .pdf {
            return """
            <html>
              <head>
                <meta name="viewport" content="width=device-width, initial-scale=1">
                <style>
                  html, body { margin: 0; min-height: 100%; background: #f7f7f4; font-family: -apple-system, BlinkMacSystemFont, sans-serif; }
                  body { padding-bottom: env(safe-area-inset-bottom); overflow-y: auto; }
                  object, iframe { width: 100%; min-height: calc(100vh - env(safe-area-inset-bottom)); border: 0; display: block; background: white; }
                  .fallback { padding: 24px; }
                </style>
              </head>
              <body>
                <object data="\(dataURL)" type="\(mediaType)">
                  <div class="fallback"><a href="\(dataURL)">Open \(filename)</a></div>
                </object>
              </body>
            </html>
            """
        }

        return """
        <html>
          <head>
            <meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
            <style>
              html {
                -webkit-text-size-adjust: 100%;
                background: #f7f2e9;
              }
              html, body {
                margin: 0;
                min-height: 100%;
                width: 100%;
                overflow-x: hidden;
              }
              body {
                padding: 12px 12px calc(28px + env(safe-area-inset-bottom));
                box-sizing: border-box;
                overflow-y: auto;
                -webkit-overflow-scrolling: touch;
                background: #f7f2e9;
              }
              .menu-sheet {
                width: 100%;
                max-width: min(1100px, 100%);
                margin: 0 auto;
                box-sizing: border-box;
              }
              img {
                display: block;
                width: 100%;
                max-width: 100%;
                height: auto;
                max-height: none;
                object-fit: contain;
                box-sizing: border-box;
                border-radius: 10px;
                box-shadow: 0 18px 42px rgba(0,0,0,.18);
                background: white;
              }
              @media (max-width: 480px) {
                body {
                  padding: 12px 12px calc(24px + env(safe-area-inset-bottom));
                }
                img {
                  border-radius: 8px;
                  box-shadow: 0 10px 24px rgba(0,0,0,.16);
                }
              }
            </style>
          </head>
          <body>
            <div class="menu-sheet">
              <img src="\(dataURL)" alt="\(filename)">
            </div>
          </body>
        </html>
        """
    }

    private func htmlAttribute(_ value: String) -> String {
        value
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&#39;")
    }
}

#if os(iOS) && canImport(WebKit)
private struct SiteHTMLWebView: UIViewRepresentable {
    let html: String

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.allowsBackForwardNavigationGestures = true
        webView.scrollView.alwaysBounceVertical = true
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        guard context.coordinator.loadedHTML != html else { return }
        context.coordinator.loadedHTML = html
        webView.loadHTMLString(html, baseURL: URL(string: "https://preview.siteclaw.local"))
    }

    final class Coordinator {
        var loadedHTML = ""
    }
}
#elseif os(macOS) && canImport(WebKit)
private struct SiteHTMLWebView: NSViewRepresentable {
    let html: String

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.allowsBackForwardNavigationGestures = true
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        guard context.coordinator.loadedHTML != html else { return }
        context.coordinator.loadedHTML = html
        webView.loadHTMLString(html, baseURL: URL(string: "https://preview.siteclaw.local"))
    }

    final class Coordinator {
        var loadedHTML = ""
    }
}
#else
private struct SiteHTMLWebView: View {
    let html: String

    var body: some View {
        ScrollView {
            Text(html)
                .font(.caption.monospaced())
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
#endif

private struct WebsiteMenuItemCard: View {
    let item: MenuItem
    let archetype: RestaurantSiteArchetype

    init(item: MenuItem, archetype: RestaurantSiteArchetype = .neighborhoodUtility) {
        self.item = item
        self.archetype = archetype
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let image = platformImage {
                image
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .aspectRatio(4.0 / 3.0, contentMode: .fill)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .clipped()
                    .accessibilityHidden(true)
            }

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
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(cardBorder, lineWidth: archetype == .fineDiningReservationFirst ? 1.2 : 1)
        }
    }

    private var cardBackground: Color {
        switch archetype {
        case .fineDiningReservationFirst:
            Color(red: 0.98, green: 0.97, blue: 0.94)
        case .fastCasualOrderFirst:
            SiteClawTheme.coral.opacity(0.08)
        case .culturalHeritage:
            SiteClawTheme.gold.opacity(0.10)
        case .neighborhoodUtility:
            Color(red: 0.99, green: 0.99, blue: 0.97)
        }
    }

    private var cardBorder: Color {
        switch archetype {
        case .fineDiningReservationFirst:
            SiteClawTheme.navy.opacity(0.20)
        case .fastCasualOrderFirst:
            SiteClawTheme.coral.opacity(0.22)
        case .culturalHeritage:
            SiteClawTheme.gold.opacity(0.32)
        case .neighborhoodUtility:
            .black.opacity(0.07)
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

        if price.rounded() == price {
            return "$\(Int(price))"
        }

        return price.formatted(.currency(code: "USD"))
    }

    private var descriptionText: String {
        let description = item.description.trimmingCharacters(in: .whitespacesAndNewlines)
        return description.isEmpty ? "More details coming soon." : description
    }

    private var platformImage: Image? {
        guard let image = item.image,
              let base64 = image.dataURL.components(separatedBy: "base64,").last,
              let data = Data(base64Encoded: base64) else {
            return nil
        }

        #if os(iOS)
        guard let uiImage = UIImage(data: data) else { return nil }
        return Image(uiImage: uiImage)
        #elseif os(macOS)
        guard let nsImage = NSImage(data: data) else { return nil }
        return Image(nsImage: nsImage)
        #else
        return nil
        #endif
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

                    if let cateringEmailURL {
                        ContactFact(
                            title: "Catering Contact",
                            value: cateringEmailText,
                            systemImage: "envelope",
                            destination: cateringEmailURL
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
        !locationText.isEmpty || !hoursText.isEmpty || !phoneText.isEmpty || cateringEmailURL != nil
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

    private var cateringEmailText: String {
        studio.restaurant.cateringEmail.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var cateringEmailURL: URL? {
        guard cateringEmailText.range(
            of: #"^[A-Z0-9._%+\-]+@[A-Z0-9.\-]+\.[A-Z]{2,}$"#,
            options: [.regularExpression, .caseInsensitive]
        ) != nil else {
            return nil
        }

        return URL(string: "mailto:\(cateringEmailText)")
    }
}

private struct WebsiteGrowthToolsSection: View {
    let studio: SiteClawStudio

    var body: some View {
        if !studio.restaurant.growthTools.enabledLabels.isEmpty {
            VStack(alignment: .leading, spacing: 14) {
                Text("Restaurant Tools")
                    .font(.title3.bold())
                Text("Optional growth modules SiteClaw can surface after launch.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 160), spacing: 10)], spacing: 10) {
                    ForEach(studio.restaurant.growthTools.enabledLabels, id: \.self) { label in
                        Label(label, systemImage: systemImage(for: label))
                            .font(.caption.weight(.bold))
                            .foregroundStyle(SiteClawTheme.ink)
                            .padding(12)
                            .frame(maxWidth: .infinity, minHeight: 54, alignment: .leading)
                            .background(SiteClawTheme.mint.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .foregroundStyle(SiteClawTheme.ink)
            .background(.white)
        }
    }

    private func systemImage(for label: String) -> String {
        let normalized = label.lowercased()
        if normalized.contains("gift") { return "giftcard.fill" }
        if normalized.contains("catering") { return "tray.full.fill" }
        if normalized.contains("review") { return "star.bubble.fill" }
        if normalized.contains("qr") { return "qrcode" }
        if normalized.contains("analytics") { return "chart.bar.fill" }
        if normalized.contains("event") { return "calendar" }
        return "sparkles"
    }
}

private struct ContactFact: View {
    let title: String
    let value: String
    let systemImage: String
    var destination: URL? = nil

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
                if let destination {
                    Link(value, destination: destination)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(SiteClawTheme.sky)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    Text(value)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(SiteClawTheme.ink)
                        .fixedSize(horizontal: false, vertical: true)
                }
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

private struct SiteQualityAuditCard: View {
    let studio: SiteClawStudio

    var body: some View {
        VStack(spacing: 12) {
            SectionHeader(
                title: "Website Quality",
                subtitle: "Pre-publish checks for trust, links, SEO, and customer usefulness."
            )

            ClawCard {
                VStack(alignment: .leading, spacing: 14) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(studio.canPublishSite ? "Ready to share" : "Publish blockers found")
                                .font(.title3.bold())
                            Text("\(studio.siteQualityScore)% quality score. \(blockerSummary)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        Spacer()

                        StatusPill(
                            title: "\(studio.siteQualityScore)%",
                            systemImage: studio.canPublishSite ? "checkmark.seal.fill" : "exclamationmark.triangle.fill",
                            color: studio.canPublishSite ? SiteClawTheme.mint : SiteClawTheme.coral
                        )
                    }

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 230), spacing: 10)], spacing: 10) {
                        ForEach(studio.siteQualityAuditItems) { item in
                            SiteQualityAuditRow(item: item)
                        }
                    }
                }
            }
        }
    }

    private var blockerSummary: String {
        let blockers = studio.blockingQualityIssues.count
        if blockers == 0 {
            return "No dead external links or required content gaps detected."
        }
        return "\(blockers) blocker\(blockers == 1 ? "" : "s") must be fixed before publishing."
    }
}

private struct SiteQualityAuditRow: View {
    let item: SiteQualityAuditItem

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: item.systemImage)
                .foregroundStyle(color)
                .frame(width: 24, height: 24)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(item.title)
                        .font(.caption.weight(.bold))
                    Text(item.severity.title)
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(color)
                }
                Text(item.detail)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, minHeight: 82, alignment: .topLeading)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(color.opacity(0.20), lineWidth: 1)
        }
    }

    private var color: Color {
        switch item.severity {
        case .passed: SiteClawTheme.mint
        case .warning: SiteClawTheme.gold
        case .blocker: SiteClawTheme.coral
        }
    }
}

private struct PreviewQAReportCard: View {
    let studio: SiteClawStudio

    var body: some View {
        VStack(spacing: 12) {
            SectionHeader(
                title: "Preview QA",
                subtitle: "Quick proof that the public website behaves like a production preview."
            )

            ClawCard {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 220), spacing: 10)], spacing: 10) {
                    QAStatusTile(title: "Responsive Modes", detail: "Phone, tablet, and desktop preview modes are available.", isReady: true, systemImage: "rectangle.3.group")
                    QAStatusTile(title: "Link Safety", detail: linkSafetyDetail, isReady: studio.blockingQualityIssues.isEmpty, systemImage: "link")
                    QAStatusTile(title: "Accessibility Basics", detail: "Primary controls include labels and readable text hierarchy.", isReady: true, systemImage: "accessibility")
                    QAStatusTile(title: "Generated HTML", detail: "\(studio.siteExport.sizeLabel) static page generated from restaurant.json.", isReady: !studio.siteExport.html.isEmpty, systemImage: "curlybraces")
                }
            }
        }
    }

    private var linkSafetyDetail: String {
        studio.blockingQualityIssues.isEmpty
            ? "No invalid customer links in the current audit."
            : "Fix blockers before publishing."
    }
}

private struct AIDesignStrategyReviewCard: View {
    let studio: SiteClawStudio

    var body: some View {
        VStack(spacing: 12) {
            SectionHeader(
                title: "AI Design Strategy",
                subtitle: "How the voice coach shaped the generated restaurant website."
            )

            ClawCard {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Label(studio.draft.designBrief.resolvedArchetype.displayName, systemImage: "wand.and.stars")
                            .font(.headline)
                            .foregroundStyle(SiteClawTheme.coral)
                        Spacer()
                        Text("\(studio.voiceCoachTurns.count) coach turn\(studio.voiceCoachTurns.count == 1 ? "" : "s")")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.secondary)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(studio.aiDesignDecisionSummary, id: \.self) { decision in
                            Label(decision, systemImage: "checkmark.seal.fill")
                                .font(.caption)
                                .foregroundStyle(SiteClawTheme.ink)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    if let latest = studio.latestVoiceCoachTurn {
                        Divider()
                        Text(latest.statusMessage)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
    }
}

private struct QAStatusTile: View {
    let title: String
    let detail: String
    let isReady: Bool
    let systemImage: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: isReady ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .foregroundStyle(isReady ? SiteClawTheme.mint : SiteClawTheme.gold)
                .frame(width: 24, height: 24)
            VStack(alignment: .leading, spacing: 3) {
                Label(title, systemImage: systemImage)
                    .font(.caption.weight(.bold))
                Text(detail)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, minHeight: 82, alignment: .topLeading)
        .background((isReady ? SiteClawTheme.mint : SiteClawTheme.gold).opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct PublishHistoryCard: View {
    let studio: SiteClawStudio

    var body: some View {
        VStack(spacing: 12) {
            SectionHeader(
                title: "Publish History",
                subtitle: "Preview, publish, and republish states for the local prototype."
            )

            ClawCard {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Label(studio.publishStage.title, systemImage: studio.publishStage.systemImage)
                            .font(.headline)
                            .foregroundStyle(statusColor)
                        Spacer()
                        Text(studio.workspaceSummary)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }

                    if studio.publishHistory.isEmpty {
                        Text("No publish events yet. Refresh or open the site to create the first local history entry.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    } else {
                        VStack(spacing: 8) {
                            ForEach(studio.publishHistory.prefix(5)) { item in
                                PublishHistoryRow(item: item)
                            }
                        }
                    }
                }
            }
        }
    }

    private var statusColor: Color {
        switch studio.publishStage {
        case .published: SiteClawTheme.mint
        case .needsRepublish: SiteClawTheme.coral
        case .preview: SiteClawTheme.sky
        case .draft: SiteClawTheme.gold
        }
    }
}

private struct PublishHistoryRow: View {
    let item: SitePublishHistoryItem

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: item.stage.systemImage)
                .foregroundStyle(item.stage == .published ? SiteClawTheme.mint : SiteClawTheme.sky)
                .frame(width: 24, height: 24)

            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(item.title)
                        .font(.caption.weight(.bold))
                    Spacer()
                    Text(item.timeLabel)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Text(item.detail)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                if !item.url.isEmpty {
                    Text(item.url)
                        .font(.caption2.monospaced())
                        .foregroundStyle(SiteClawTheme.sky)
                        .lineLimit(1)
                }
            }
        }
        .padding(10)
        .background(SiteClawTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct SEOSummaryCard: View {
    let studio: SiteClawStudio

    var body: some View {
        VStack(spacing: 12) {
            SectionHeader(
                title: "Get Found on Google",
                subtitle: "Owner-facing search and visibility checks before sharing the site."
            )

            ClawCard {
                VStack(alignment: .leading, spacing: 16) {
                    SummaryRow(title: "Search Title", value: studio.restaurantJSON.seo.title)
                    SummaryRow(title: "Description", value: studio.restaurantJSON.seo.description)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Local Keywords")
                            .font(.headline)
                        TagWrap(tags: studio.restaurantJSON.seo.keywords, color: SiteClawTheme.mint)
                    }

                    Divider()

                    HStack {
                        Text("Visibility Checklist")
                            .font(.headline)
                        Spacer()
                        Text(progressLabel)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(SiteClawTheme.mint)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                            .background(SiteClawTheme.mint.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 220), spacing: 10)], spacing: 10) {
                        ForEach(studio.restaurant.visibilityChecklistItems) { item in
                            SEOChecklistRow(item: item)
                        }
                    }

                    if !studio.restaurant.externalProfileLinks.isEmpty {
                        Divider()
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Find Us Online")
                                .font(.headline)
                            ExternalProfileLinksView(links: studio.restaurant.externalProfileLinks)
                        }
                    }
                }
            }
        }
    }

    private var progressLabel: String {
        let progress = studio.restaurant.visibilityChecklistProgress
        return "\(progress.completed)/\(progress.total)"
    }
}

private struct ExternalProfileLinksView: View {
    let links: [RestaurantExternalProfileLink]

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 8, alignment: .top)], spacing: 8) {
            ForEach(validLinks) { link in
                Link(destination: link.destination) {
                    Label(link.title, systemImage: systemImage(for: link.title))
                        .font(.caption.weight(.bold))
                        .foregroundStyle(SiteClawTheme.sky)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(SiteClawTheme.sky.opacity(0.12))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(link.title) link")
            }
        }
    }

    private var validLinks: [ExternalProfileLinkDestination] {
        links.compactMap { link in
            guard let destination = safeURL(link.url) else { return nil }
            return ExternalProfileLinkDestination(title: link.title, destination: destination)
        }
    }

    private func safeURL(_ value: String) -> URL? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let destination = URL(string: trimmed),
              let scheme = destination.scheme?.lowercased(),
              ["http", "https"].contains(scheme),
              destination.host?.isEmpty == false else {
            return nil
        }

        return destination
    }

    private func systemImage(for title: String) -> String {
        let normalized = title.lowercased()
        if normalized.contains("google") {
            return "magnifyingglass"
        }
        if normalized.contains("yelp") {
            return "quote.bubble"
        }
        if normalized.contains("instagram") {
            return "camera"
        }
        if normalized.contains("facebook") {
            return "person.2"
        }
        return "link"
    }
}

private struct ExternalProfileLinkDestination: Identifiable {
    var id: URL { destination }
    let title: String
    let destination: URL
}

private struct SummaryRow: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)
            Text(value.isEmpty ? "Not generated yet" : value)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(SiteClawTheme.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct SEOChecklistRow: View {
    let item: VisibilityChecklistItem

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: item.isComplete ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(item.isComplete ? SiteClawTheme.mint : .secondary)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                Text(item.title)
                    .font(.caption.weight(.bold))
                Text(item.detail)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, minHeight: 72, alignment: .topLeading)
        .background(item.isComplete ? SiteClawTheme.mint.opacity(0.08) : SiteClawTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(item.isComplete ? SiteClawTheme.mint.opacity(0.20) : SiteClawTheme.separator, lineWidth: 1)
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

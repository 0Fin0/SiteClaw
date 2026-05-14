//
//  BuilderView.swift
//  SiteClaw
//

import SwiftUI
import UniformTypeIdentifiers
#if os(iOS)
import PhotosUI
import UIKit
#elseif os(macOS)
import AppKit
#endif

struct BuilderView: View {
    @Bindable var studio: SiteClawStudio
    var continueToPreview: (() -> Void)?
    var scrollResetToken = 0
    @State private var ownerNote = ""
    @State private var isRestaurantBasicsExpanded = false
    @State private var isWebsiteDirectionExpanded = false
    @State private var isFeaturedDishesExpanded = false
    @State private var isUploadedMenuExpanded = false
    @State private var isContactVisibilityExpanded = false
    @State private var isGrowthToolkitExpanded = false

    private static let topAnchorID = "builder-top-anchor"

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 18) {
                        Color.clear
                            .frame(height: SiteClawTheme.topScrollResetClearance)
                            .id(Self.topAnchorID)
                        HeroBuilderCard(studio: studio)
                        BuildCollapsibleSection(
                            title: "Restaurant Basics",
                            subtitle: restaurantBasicsSummary,
                            summary: restaurantBasicsSummary,
                            status: restaurantBasicsStatus,
                            systemImage: "storefront.fill",
                            tint: SiteClawTheme.sky,
                            isExpanded: $isRestaurantBasicsExpanded
                        ) {
                            RestaurantIntakeView(studio: studio)
                        }
                        BuildCollapsibleSection(
                            title: "Use Your Existing Menu",
                            subtitle: uploadedMenuSummary,
                            summary: uploadedMenuSummary,
                            status: uploadedMenuStatus,
                            systemImage: "doc.badge.plus",
                            tint: SiteClawTheme.gold,
                            isExpanded: $isUploadedMenuExpanded
                        ) {
                            MenuUploadView(studio: studio)
                        }
                        BuildCollapsibleSection(
                            title: "Featured Dishes",
                            subtitle: featuredDishesSummary,
                            summary: featuredDishesSummary,
                            status: featuredDishesStatus,
                            systemImage: "fork.knife",
                            tint: SiteClawTheme.mint,
                            isExpanded: $isFeaturedDishesExpanded
                        ) {
                            MenuCorrectionsView(studio: studio)
                        }
                        BuildCollapsibleSection(
                            title: "Choose Website Style",
                            subtitle: websiteDirectionSummary,
                            summary: websiteDirectionSummary,
                            status: websiteDirectionStatus,
                            systemImage: "slider.horizontal.3",
                            tint: SiteClawTheme.coral,
                            isExpanded: $isWebsiteDirectionExpanded
                        ) {
                            SiteCustomizationView(studio: studio)
                        }
                        BuildCollapsibleSection(
                            title: "Contact & Visibility",
                            subtitle: contactVisibilitySummary,
                            summary: contactVisibilitySummary,
                            status: contactVisibilityStatus,
                            systemImage: "mappin.and.ellipse",
                            tint: SiteClawTheme.sky,
                            isExpanded: $isContactVisibilityExpanded
                        ) {
                            ContactVisibilityView(studio: studio)
                        }
                        BuildCollapsibleSection(
                            title: "Growth Toolkit (Beta)",
                            subtitle: growthToolkitSummary,
                            summary: growthToolkitSummary,
                            status: growthToolkitStatus,
                            systemImage: "chart.line.uptrend.xyaxis",
                            tint: SiteClawTheme.mint,
                            isExpanded: $isGrowthToolkitExpanded
                        ) {
                            GrowthToolkitView(studio: studio)
                        }
                        ConversationView(studio: studio, ownerNote: $ownerNote)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, SiteClawTheme.navigationContentTopInset)
                    .padding(.bottom, SiteClawTheme.tabBarClearance + SiteClawTheme.primaryActionClearance)
                }
                .background(SiteClawTheme.background.ignoresSafeArea())
                .safeAreaInset(edge: .bottom) {
                    BuildPrimaryActionBar(studio: studio, continueToPreview: continueToPreview)
                }
                .onChange(of: scrollResetToken) { _, _ in
                    withAnimation(.snappy(duration: 0.35)) {
                        proxy.scrollTo(Self.topAnchorID, anchor: .top)
                    }
                }
            }
            .navigationTitle("Website Details")
            .siteClawNavigationChrome()
            .accountSettingsToolbar(studio: studio)
        }
    }

    private var previewNextStepDetail: String {
        studio.isDraftGenerated
            ? "The generated site is ready for owner review."
            : "Generate the restaurant website, then open the customer preview."
    }

    private var restaurantBasicsSummary: String {
        let name = studio.restaurant.name.trimmingCharacters(in: .whitespacesAndNewlines)
        let location = studio.restaurant.neighborhood.trimmingCharacters(in: .whitespacesAndNewlines)

        if name.isEmpty && location.isEmpty {
            return "Needs restaurant details"
        }

        if name.isEmpty {
            return location
        }

        if location.isEmpty {
            return name
        }

        return "\(name) - \(location)"
    }

    private var restaurantBasicsStatus: BuildSectionStatus {
        hasRestaurantBasics ? .ready : .needsInfo
    }

    private var websiteDirectionSummary: String {
        let archetype = studio.draft.designBrief.resolvedArchetype.displayName
        return "\(archetype) style"
    }

    private var websiteDirectionStatus: BuildSectionStatus {
        .ready
    }

    private var featuredDishesSummary: String {
        let count = studio.restaurant.menuItems.count
        guard count > 0 else { return "No dishes yet" }

        let photoCount = studio.restaurant.menuItems.compactMap(\.image).count
        if photoCount == 0 {
            return "\(count) dish\(count == 1 ? "" : "es")"
        }

        return "\(count) dish\(count == 1 ? "" : "es") - \(photoCount) photo\(photoCount == 1 ? "" : "s")"
    }

    private var featuredDishesStatus: BuildSectionStatus {
        studio.restaurant.menuItems.isEmpty ? .needsInfo : .ready
    }

    private var uploadedMenuSummary: String {
        guard let uploadedMenu = studio.restaurant.uploadedMenu else {
            return "Upload menu photo or PDF"
        }

        return "\(uploadedMenu.kind == .pdf ? "PDF" : "Image") - \(uploadedMenu.sizeLabel)"
    }

    private var uploadedMenuStatus: BuildSectionStatus {
        studio.restaurant.uploadedMenu == nil ? .optional : .ready
    }

    private var contactVisibilitySummary: String {
        let hasAddress = !studio.restaurant.formattedAddress.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let hasPhone = !studio.restaurant.phone.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let hasCateringEmail = !studio.restaurant.cateringEmail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let visibilityLinkCount = studio.restaurant.externalProfileLinks.count
        var parts: [String] = []

        if hasAddress {
            parts.append(hasPhone ? "Address + phone" : "Address added")
        } else if hasPhone {
            parts.append("Phone added")
        }

        if hasCateringEmail {
            parts.append("Catering email")
        }

        if visibilityLinkCount > 0 {
            parts.append("\(visibilityLinkCount) visibility link\(visibilityLinkCount == 1 ? "" : "s")")
        }

        return parts.isEmpty ? "Contact details needed" : parts.joined(separator: " - ")
    }

    private var contactVisibilityStatus: BuildSectionStatus {
        let hasAddress = !studio.restaurant.formattedAddress.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let hasPhone = !studio.restaurant.phone.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        return hasAddress && hasPhone ? .ready : .needsInfo
    }

    private var hasRestaurantBasics: Bool {
        [
            studio.restaurant.name,
            studio.restaurant.cuisine,
            studio.restaurant.neighborhood,
            studio.restaurant.hours
        ]
            .allSatisfy { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }

    private var growthToolkitSummary: String {
        guard studio.hasGrowthToolkitAccess else {
            return "Growth or Pro plan required"
        }

        let enabled = studio.restaurant.growthTools.enabledLabels
        guard !enabled.isEmpty else { return "No growth modules enabled" }
        return "\(enabled.count) module\(enabled.count == 1 ? "" : "s") enabled"
    }

    private var growthToolkitStatus: BuildSectionStatus {
        guard studio.hasGrowthToolkitAccess else { return .locked }
        return studio.restaurant.growthTools.enabledLabels.isEmpty ? .optional : .ready
    }
}

private enum BuildSectionStatus {
    case needsInfo
    case ready
    case optional
    case needsRefresh
    case locked

    var title: String {
        switch self {
        case .needsInfo: "Needs info"
        case .ready: "Ready"
        case .optional: "Optional"
        case .needsRefresh: "Needs refresh"
        case .locked: "Upgrade"
        }
    }

    var systemImage: String {
        switch self {
        case .needsInfo: "exclamationmark.circle.fill"
        case .ready: "checkmark.circle.fill"
        case .optional: "circle.dotted"
        case .needsRefresh: "arrow.clockwise.circle.fill"
        case .locked: "lock.fill"
        }
    }

    var color: Color {
        switch self {
        case .needsInfo: SiteClawTheme.gold
        case .ready: SiteClawTheme.mint
        case .optional: SiteClawTheme.sky
        case .needsRefresh: SiteClawTheme.coral
        case .locked: SiteClawTheme.gold
        }
    }
}

private struct BuildCollapsibleSection<Content: View>: View {
    let title: String
    let subtitle: String
    let summary: String
    let status: BuildSectionStatus
    let systemImage: String
    let tint: Color
    @Binding var isExpanded: Bool
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(spacing: 10) {
            Button {
                withAnimation(.snappy(duration: 0.24)) {
                    isExpanded.toggle()
                }
            } label: {
                SectionDisclosureRow(
                    title: title,
                    subtitle: subtitle,
                    statusTitle: status.title,
                    statusImage: status.systemImage,
                    statusColor: status.color,
                    systemImage: systemImage,
                    tint: tint,
                    isExpanded: isExpanded
                )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(title), \(status.title), \(summary)")
            .accessibilityHint(isExpanded ? "Collapse section" : "Expand section")

            if isExpanded {
                content()
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}

private struct HeroBuilderCard: View {
    let studio: SiteClawStudio

    var body: some View {
        ClawCard {
            VStack(alignment: .leading, spacing: SiteClawTheme.Spacing.medium) {
                HStack(alignment: .top, spacing: SiteClawTheme.Spacing.medium) {
                    IconBadge(systemImage: "checklist.checked", color: SiteClawTheme.coral, size: 42)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Site readiness")
                            .font(.headline)
                        Text("Review owner details, then open the generated preview.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer()

                    StatusPill(
                        title: status.title,
                        systemImage: status.systemImage,
                        color: status.color
                    )
                }

                VStack(alignment: .leading, spacing: SiteClawTheme.Spacing.xSmall) {
                    ProgressView(value: Double(studio.completionPercent), total: 100)
                        .tint(SiteClawTheme.mint)
                        .accessibilityLabel("Site completion")

                    HStack {
                        Label("\(studio.completionPercent)% complete", systemImage: "gauge.with.dots.needle.67percent")
                        Spacer()
                        Label(menuSummary, systemImage: "fork.knife")
                    }
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var menuSummary: String {
        studio.restaurant.menuItems.isEmpty
            ? "Dishes needed"
            : "\(studio.restaurant.menuItems.count) dish\(studio.restaurant.menuItems.count == 1 ? "" : "es")"
    }

    private var status: BuildSectionStatus {
        if !studio.isDraftGenerated {
            return .needsInfo
        }

        if studio.isSiteExportStale {
            return .needsRefresh
        }

        return .ready
    }
}

private struct RestaurantIntakeView: View {
    @Bindable var studio: SiteClawStudio

    var body: some View {
        ClawCard {
            VStack(spacing: 12) {
                LabeledTextField(label: "Restaurant Name", placeholder: "Enter restaurant name", text: restaurantBasicBinding(\.name))
                LabeledTextField(label: "Cuisine", placeholder: "Enter cuisine or restaurant type", text: restaurantBasicBinding(\.cuisine))
                LabeledTextField(label: "Location", placeholder: "Enter city or full location", text: restaurantBasicBinding(\.neighborhood))
                LabeledTextField(label: "Hours", placeholder: "Enter operating hours", text: restaurantBasicBinding(\.hours))
                LabeledTextField(label: "Owner Story", placeholder: "Add what makes the restaurant special", text: restaurantBasicBinding(\.story), axis: .vertical)
                    .lineLimit(2...4)
            }
        }
    }

    private func restaurantBasicBinding(_ keyPath: WritableKeyPath<RestaurantProfile, String>) -> Binding<String> {
        Binding(
            get: { studio.restaurant[keyPath: keyPath] },
            set: { studio.updateRestaurantBasic(keyPath, to: $0) }
        )
    }
}

private struct SiteCustomizationView: View {
    @Bindable var studio: SiteClawStudio

    var body: some View {
        ClawCard {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Choose Website Style")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 210), spacing: 10, alignment: .top)], spacing: 10) {
                        ForEach(RestaurantSiteArchetype.allCases) { archetype in
                            DirectionCard(
                                archetype: archetype,
                                isSelected: studio.draft.designBrief.resolvedArchetype == archetype
                            ) {
                                siteDirectionBinding.wrappedValue = archetype
                            }
                        }
                    }

                    Text(studio.draft.designBrief.resolvedArchetype.detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                AIDesignDecisionsCard(studio: studio)
            }
        }
    }

    private var siteDirectionBinding: Binding<RestaurantSiteArchetype> {
        Binding {
            studio.draft.designBrief.resolvedArchetype
        } set: { archetype in
            let current = studio.draft.designBrief
            studio.draft.designBrief = RestaurantDesignBrief(
                archetype: archetype,
                designDecisions: current.designDecisions,
                storyOpportunities: current.storyOpportunities,
                recommendedModules: current.recommendedModules
            )
            studio.draft.callToAction = archetype.defaultPrimaryCTA
            markStyleChanged()
        }
    }

    private func markStyleChanged() {
        studio.siteExportStatus = "Website style changed. Refresh the site export when ready."
        studio.lastSiteExportedAt = nil
    }
}

private struct DirectionCard: View {
    let archetype: RestaurantSiteArchetype
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: icon)
                        .font(.headline)
                        .foregroundStyle(tint)
                        .frame(width: 30, height: 30)
                        .background(tint.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(archetype.displayName)
                            .font(.subheadline.weight(.bold))
                        Text(spec.heroKicker)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(tint)
                    }

                    Spacer(minLength: 0)

                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(tint)
                            .accessibilityHidden(true)
                    }
                }

                Text(archetype.detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)

                VStack(alignment: .leading, spacing: 4) {
                    Text("CTA: \(spec.primaryCTA)")
                    Text("Layout: \(layoutLabel)")
                }
                .font(.caption2.weight(.semibold))
                .foregroundStyle(SiteClawTheme.ink.opacity(0.72))
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .background(isSelected ? tint.opacity(0.11) : SiteClawTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(isSelected ? tint : SiteClawTheme.separator, lineWidth: isSelected ? 1.5 : 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(archetype.displayName), \(isSelected ? "selected" : "not selected")")
    }

    private var spec: RestaurantArchetypePreviewSpec {
        RestaurantArchetypePreviewSpec.spec(for: archetype)
    }

    private var layoutLabel: String {
        spec.sectionOrder.map(Self.sectionDisplayName).joined(separator: " > ")
    }

    nonisolated private static func sectionDisplayName(_ section: RestaurantPreviewSection) -> String {
        switch section {
        case .story:
            return "Story"
        case .menu:
            return "Menu"
        case .visit:
            return "Visit"
        }
    }

    private var tint: Color {
        switch archetype {
        case .neighborhoodUtility:
            SiteClawTheme.sky
        case .fastCasualOrderFirst:
            SiteClawTheme.coral
        case .fineDiningReservationFirst:
            SiteClawTheme.navy
        case .culturalHeritage:
            SiteClawTheme.gold
        }
    }

    private var icon: String {
        switch archetype {
        case .neighborhoodUtility:
            "mappin.and.ellipse"
        case .fastCasualOrderFirst:
            "takeoutbag.and.cup.and.straw"
        case .fineDiningReservationFirst:
            "wineglass"
        case .culturalHeritage:
            "flame"
        }
    }
}

private struct AIDesignDecisionsCard: View {
    @Bindable var studio: SiteClawStudio

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "wand.and.stars")
                    .font(.headline)
                    .foregroundStyle(SiteClawTheme.coral)
                    .frame(width: 30, height: 30)
                    .background(SiteClawTheme.coral.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                VStack(alignment: .leading, spacing: 3) {
                    Text("AI Design Decisions")
                        .font(.subheadline.weight(.bold))
                    Text("Grounded strategy from the voice coach and owner-provided details.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                LabelPill(
                    title: "\(studio.aiDesignDecisionSummary.count)",
                    systemImage: "sparkles",
                    color: SiteClawTheme.coral
                )
            }

            VStack(alignment: .leading, spacing: 7) {
                ForEach(studio.aiDesignDecisionSummary, id: \.self) { decision in
                    Label(decision, systemImage: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(SiteClawTheme.ink)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(SiteClawTheme.coral.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct MenuCorrectionsView: View {
    @Bindable var studio: SiteClawStudio

    var body: some View {
        VStack(spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Featured Dishes")
                        .font(.headline)
                    Text("Edit item names, prices, short descriptions, and photos.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)

                Button {
                    studio.restaurant.menuItems.append(MenuItem(name: "", description: "", price: nil))
                } label: {
                    Image(systemName: "plus")
                }
                .buttonStyle(.borderedProminent)
                .tint(SiteClawTheme.mint)
                .accessibilityLabel("Add dish")
            }

            ClawCard {
                if studio.restaurant.menuItems.isEmpty {
                    EmptyMenuPrompt {
                        studio.restaurant.menuItems.append(MenuItem(name: "", description: "", price: nil))
                    }
                } else {
                    VStack(spacing: 14) {
                        ForEach(studio.restaurant.menuItems.indices, id: \.self) { index in
                            MenuCorrectionRow(
                                index: index,
                                item: $studio.restaurant.menuItems[index],
                                priceText: priceBinding(for: index),
                                deleteAction: {
                                    deleteMenuItem(at: index)
                                }
                            )

                            if index != studio.restaurant.menuItems.indices.last {
                                Divider()
                            }
                        }
                    }
                }
            }
        }
    }

    private func deleteMenuItem(at index: Int) {
        guard studio.restaurant.menuItems.indices.contains(index) else { return }
        studio.restaurant.menuItems.remove(at: index)
    }

    private func priceBinding(for index: Int) -> Binding<String> {
        Binding(
            get: {
                guard studio.restaurant.menuItems.indices.contains(index),
                      let price = studio.restaurant.menuItems[index].price else {
                    return ""
                }

                return Self.priceFormatter.string(from: NSNumber(value: price)) ?? String(format: "%.2f", price)
            },
            set: { value in
                guard studio.restaurant.menuItems.indices.contains(index) else { return }
                let cleaned = value
                    .replacingOccurrences(of: "$", with: "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                studio.restaurant.menuItems[index].price = cleaned.isEmpty ? nil : Double(cleaned)
            }
        )
    }

    private static let priceFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        formatter.numberStyle = .decimal
        return formatter
    }()
}

private struct MenuCorrectionRow: View {
    let index: Int
    @Binding var item: MenuItem
    @Binding var priceText: String
    let deleteAction: () -> Void
    @State private var isImportingDishImage = false
    @State private var imageMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Text("Dish \(index + 1)")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(SiteClawTheme.ink)

                Spacer()

                Button(role: .destructive, action: deleteAction) {
                    Image(systemName: "trash")
                }
                .buttonStyle(.borderless)
                .accessibilityLabel("Delete dish")
            }

            LazyVGrid(columns: Self.fieldColumns, spacing: 10) {
                LabeledTextField(label: "Name", placeholder: "Dish name", text: $item.name)
                LabeledTextField(label: "Price", placeholder: "12.99", text: $priceText)
                    #if os(iOS)
                    .keyboardType(.decimalPad)
                    #endif
            }

            LabeledTextField(label: "Description", placeholder: "Add a short dish description", text: $item.description, axis: .vertical)
                .lineLimit(2...3)

            DishImageEditor(item: $item, isImportingDishImage: $isImportingDishImage, imageMessage: $imageMessage)
        }
        .fileImporter(
            isPresented: $isImportingDishImage,
            allowedContentTypes: [.image],
            allowsMultipleSelection: false
        ) { result in
            importDishImageFile(from: result)
        }
    }

    private static let fieldColumns = [
        GridItem(.adaptive(minimum: 180), spacing: 10, alignment: .top)
    ]

    private func importDishImageFile(from result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            do {
                let isScoped = url.startAccessingSecurityScopedResource()
                defer {
                    if isScoped {
                        url.stopAccessingSecurityScopedResource()
                    }
                }

                let data = try Data(contentsOf: url)
                let contentType = UTType(filenameExtension: url.pathExtension)
                let mediaType = contentType?.preferredMIMEType ?? "image/jpeg"
                item.image = MenuItemImageAsset.make(
                    filename: url.lastPathComponent,
                    mediaType: mediaType,
                    data: data
                )
                imageMessage = "Dish photo added."
            } catch {
                imageMessage = error.localizedDescription
            }
        case .failure(let error):
            imageMessage = error.localizedDescription
        }
    }

}

private struct DishImageEditor: View {
    @Binding var item: MenuItem
    @Binding var isImportingDishImage: Bool
    @Binding var imageMessage: String?
    #if os(iOS)
    @State private var selectedDishPhoto: PhotosPickerItem?
    #endif

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Dish Photo")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            HStack(alignment: .top, spacing: 12) {
                DishImagePreview(asset: item.image)

                VStack(alignment: .leading, spacing: 8) {
                    Text(imageDetail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: 8) {
                        #if os(iOS)
                        PhotosPicker(selection: $selectedDishPhoto, matching: .images) {
                            Label(photoButtonTitle, systemImage: "photo.badge.plus")
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        #else
                        Button {
                            isImportingDishImage = true
                        } label: {
                            Label(photoButtonTitle, systemImage: "photo.badge.plus")
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        #endif

                        if hasDishImage {
                            Button(role: .destructive) {
                                item.image = nil
                                imageMessage = "Dish photo removed."
                            } label: {
                                Label("Remove", systemImage: "trash")
                            }
                            .buttonStyle(.borderless)
                            .controlSize(.small)
                        }
                    }

                    if let imageMessage {
                        Text(imageMessage)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(SiteClawTheme.mint)
                    }
                }
            }
        }
        .padding(10)
        .background(SiteClawTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        #if os(iOS)
        .onChange(of: selectedDishPhoto) { _, newItem in
            guard let newItem else { return }
            Task {
                await importDishPhoto(from: newItem)
                selectedDishPhoto = nil
            }
        }
        #endif
    }

    private var imageDetail: String {
        guard let image = item.image else {
            return "Optional. Dish photos will appear on the generated website cards."
        }

        return "\(image.filename) - \(image.sizeLabel)"
    }

    private var photoButtonTitle: String {
        hasDishImage ? "Replace Photo" : "Add Photo"
    }

    private var hasDishImage: Bool {
        if case .some = item.image {
            return true
        }

        return false
    }

    #if os(iOS)
    @MainActor
    private func importDishPhoto(from photoItem: PhotosPickerItem) async {
        do {
            guard let data = try await photoItem.loadTransferable(type: Data.self) else {
                imageMessage = "SiteClaw could not read that photo."
                return
            }

            let contentType = photoItem.supportedContentTypes.first { $0.conforms(to: .image) }
            let mediaType = contentType?.preferredMIMEType ?? "image/jpeg"
            let extensionHint = contentType?.preferredFilenameExtension ?? "jpg"
            item.image = MenuItemImageAsset.make(
                filename: "dish-photo.\(extensionHint)",
                mediaType: mediaType,
                data: data
            )
            imageMessage = "Dish photo added."
        } catch {
            imageMessage = error.localizedDescription
        }
    }
    #endif
}

private struct DishImagePreview: View {
    let asset: MenuItemImageAsset?

    var body: some View {
        Group {
            if let image = platformImage {
                image
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "photo")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(width: 72, height: 72)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(SiteClawTheme.separator, lineWidth: 1)
        }
        .clipped()
        .accessibilityHidden(true)
    }

    private var platformImage: Image? {
        guard let asset,
              let base64 = asset.dataURL.components(separatedBy: "base64,").last,
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
}

private struct EmptyMenuPrompt: View {
    let addAction: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("No dishes captured yet.")
                .font(.headline)
            Text("Add dishes manually or return to Talk and capture the menu answer again.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button(action: addAction) {
                Label("Add First Dish", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
            .tint(SiteClawTheme.mint)
        }
    }
}

private struct MenuUploadView: View {
    @Bindable var studio: SiteClawStudio
    @State private var isImportingMenuFile = false
    @State private var uploadMessage: String?
    @State private var uploadMessageIsError = false
    #if os(iOS)
    @State private var selectedPhotoItem: PhotosPickerItem?
    #endif

    var body: some View {
        ClawCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: uploadedMenuIcon)
                        .font(.title2)
                        .foregroundStyle(SiteClawTheme.sky)
                        .frame(width: 40, height: 40)
                        .background(SiteClawTheme.sky.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                    VStack(alignment: .leading, spacing: 4) {
                        Text(uploadedMenuTitle)
                            .font(.headline)
                        Text(uploadedMenuDetail)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 8)
                }

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 160), spacing: 10)], spacing: 10) {
                    Button {
                        isImportingMenuFile = true
                    } label: {
                        Label(studio.restaurant.uploadedMenu == nil ? "Upload File" : "Replace File", systemImage: "doc.badge.plus")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(SiteClawTheme.sky)

                    #if os(iOS)
                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                        Label("Use Photo", systemImage: "camera.viewfinder")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(SiteClawTheme.mint)
                    #endif

                    Button {
                        let asset = UploadedMenuAsset.sunsetGrillDemo
                        let extraction = studio.applyUploadedMenuAsset(asset)
                        uploadMessage = extraction.statusMessage
                        uploadMessageIsError = false
                    } label: {
                        Label("Demo Menu", systemImage: "sparkles")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .tint(SiteClawTheme.gold)

                    if studio.restaurant.uploadedMenu != nil {
                        Button(role: .destructive) {
                            studio.removeUploadedMenuAsset()
                            uploadMessage = "Uploaded menu removed."
                            uploadMessageIsError = false
                        } label: {
                            Label("Remove", systemImage: "trash")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                    }
                }

                if let uploadMessage {
                    Label(uploadMessage, systemImage: uploadMessageIsError ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(uploadMessageIsError ? SiteClawTheme.coral : SiteClawTheme.mint)
                }
            }
        }
        .fileImporter(
            isPresented: $isImportingMenuFile,
            allowedContentTypes: [.pdf, .image],
            allowsMultipleSelection: false
        ) { result in
            importMenuFile(from: result)
        }
        #if os(iOS)
        .onChange(of: selectedPhotoItem) { _, newItem in
            guard let newItem else { return }
            Task {
                await importMenuPhoto(from: newItem)
                selectedPhotoItem = nil
            }
        }
        #endif
    }

    private var uploadedMenuTitle: String {
        studio.restaurant.uploadedMenu?.filename ?? "No uploaded menu yet"
    }

    private var uploadedMenuDetail: String {
        guard let uploadedMenu = studio.restaurant.uploadedMenu else {
            return "Upload a menu photo or PDF. You can edit featured dishes after."
        }

        let kind = uploadedMenu.kind == .pdf ? "PDF" : "image"
        return "\(kind) - \(uploadedMenu.sizeLabel). This will appear on the generated website."
    }

    private var uploadedMenuIcon: String {
        guard let uploadedMenu = studio.restaurant.uploadedMenu else {
            return "doc.badge.plus"
        }

        return uploadedMenu.kind == .pdf ? "doc.richtext.fill" : "photo.fill"
    }

    private func importMenuFile(from result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            do {
                let isScoped = url.startAccessingSecurityScopedResource()
                defer {
                    if isScoped {
                        url.stopAccessingSecurityScopedResource()
                    }
                }

                let data = try Data(contentsOf: url)
                let contentType = UTType(filenameExtension: url.pathExtension)
                let isPDF = contentType?.conforms(to: .pdf) == true
                let mediaType = contentType?.preferredMIMEType ?? (isPDF ? "application/pdf" : "image/jpeg")
                let asset = UploadedMenuAsset.make(
                    filename: url.lastPathComponent,
                    mediaType: mediaType,
                    kind: isPDF ? .pdf : .image,
                    data: data
                )
                let extraction = studio.applyUploadedMenuAsset(asset)
                uploadMessage = extraction.statusMessage
                uploadMessageIsError = false
            } catch {
                uploadMessage = error.localizedDescription
                uploadMessageIsError = true
            }
        case .failure(let error):
            uploadMessage = error.localizedDescription
            uploadMessageIsError = true
        }
    }

    #if os(iOS)
    @MainActor
    private func importMenuPhoto(from item: PhotosPickerItem) async {
        do {
            guard let data = try await item.loadTransferable(type: Data.self) else {
                uploadMessage = "SiteClaw could not read that photo."
                uploadMessageIsError = true
                return
            }

            let contentType = item.supportedContentTypes.first { $0.conforms(to: .image) }
            let mediaType = contentType?.preferredMIMEType ?? "image/jpeg"
            let extensionHint = contentType?.preferredFilenameExtension ?? "jpg"
            let asset = UploadedMenuAsset.make(
                filename: "uploaded-menu-photo.\(extensionHint)",
                mediaType: mediaType,
                kind: .image,
                data: data
            )
            let extraction = studio.applyUploadedMenuAsset(asset)
            uploadMessage = extraction.statusMessage
            uploadMessageIsError = false
        } catch {
            uploadMessage = error.localizedDescription
            uploadMessageIsError = true
        }
    }
    #endif
}

private struct ContactCorrectionsView: View {
    @Bindable var studio: SiteClawStudio
    @State private var demoVisitMessage: String?

    var body: some View {
        ClawCard {
            VStack(spacing: 12) {
                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Customer Contact")
                            .font(.headline)
                            .foregroundStyle(SiteClawTheme.ink)
                        Text("Use the full address for maps, directions, and local SEO.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 8)

                    Button {
                        studio.fillDemoVisitDetails()
                        demoVisitMessage = "Demo address, phone, and catering email added."
                    } label: {
                        Label("Fill Demo Visit Details", systemImage: "sparkles")
                            .labelStyle(.titleAndIcon)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(SiteClawTheme.gold)
                    .controlSize(.small)
                }

                LabeledTextField(label: "Street Address", placeholder: "Enter street address", text: $studio.restaurant.streetAddress)

                LazyVGrid(columns: Self.fieldColumns, spacing: 10) {
                    LabeledTextField(label: "City", placeholder: "Enter city", text: $studio.restaurant.neighborhood)
                    LabeledTextField(label: "State", placeholder: "State", text: $studio.restaurant.state)
                    LabeledTextField(label: "ZIP", placeholder: "ZIP code", text: $studio.restaurant.postalCode)
                }

                LabeledTextField(label: "Phone", placeholder: "Phone number", text: $studio.restaurant.phone)

                LabeledTextField(label: "Catering Contact Email", placeholder: "catering@example.com", text: $studio.restaurant.cateringEmail)
                    .onChange(of: studio.restaurant.cateringEmail) { _, _ in
                        studio.markSiteNeedsRefresh("Contact details changed. Refresh the site export when ready.")
                    }

                if let demoVisitMessage {
                    Label(demoVisitMessage, systemImage: "checkmark.circle.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(SiteClawTheme.mint)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    private static let fieldColumns = [
        GridItem(.adaptive(minimum: 180), spacing: 10, alignment: .top)
    ]
}

private struct VisibilityChecklistView: View {
    @Bindable var studio: SiteClawStudio
    @State private var demoVisibilityMessage: String?
    @State private var isApplyingDemoVisibility = false
    @State private var isProgressExpanded = false

    var body: some View {
        ClawCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Visibility Checklist")
                            .font(.headline)
                            .foregroundStyle(SiteClawTheme.ink)
                        Text("Set up the restaurant links customers and local search tools expect. Google, Yelp, Instagram, and Facebook links can be skipped for now.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 8)

                    Button {
                        isApplyingDemoVisibility = true
                        studio.fillDemoVisibilityDetails()
                        demoVisibilityMessage = "Demo visibility details added."
                    } label: {
                        Label("Fill Demo Visibility", systemImage: "sparkles")
                            .labelStyle(.titleAndIcon)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(SiteClawTheme.gold)
                    .controlSize(.small)
                }

                LazyVGrid(columns: Self.fieldColumns, spacing: 10) {
                    LabeledTextField(
                        label: "Google Business Profile URL",
                        placeholder: "Optional - skip for now",
                        text: $studio.restaurant.visibility.googleBusinessProfileURL
                    )
                    LabeledTextField(
                        label: "Google Review Link",
                        placeholder: "Optional - skip for now",
                        text: $studio.restaurant.visibility.googleReviewURL
                    )
                    LabeledTextField(
                        label: "Yelp Business Page URL",
                        placeholder: "Optional - skip for now",
                        text: $studio.restaurant.visibility.yelpBusinessURL
                    )
                    LabeledTextField(
                        label: "Instagram URL",
                        placeholder: "Optional - skip for now",
                        text: $studio.restaurant.visibility.instagramURL
                    )
                    LabeledTextField(
                        label: "Facebook URL",
                        placeholder: "Optional - skip for now",
                        text: $studio.restaurant.visibility.facebookURL
                    )
                }

                VStack(alignment: .leading, spacing: 8) {
                    PolicyNote(
                        title: "Google reviews",
                        text: "A Google review link is okay, but do not offer discounts, freebies, or incentives for reviews.",
                        systemImage: "star.bubble"
                    )
                    PolicyNote(
                        title: "Yelp",
                        text: "Use customer-facing copy like \"Find us on Yelp\". Avoid asking customers for Yelp reviews.",
                        systemImage: "quote.bubble"
                    )
                }

                if let demoVisibilityMessage {
                    Label(demoVisibilityMessage, systemImage: "checkmark.circle.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(SiteClawTheme.mint)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                VisibilityProgressDisclosure(
                    progressLabel: progressLabel,
                    items: studio.restaurant.visibilityChecklistItems,
                    isExpanded: $isProgressExpanded
                )
            }
        }
        .onChange(of: studio.restaurant.visibility) { _, _ in
            if isApplyingDemoVisibility {
                isApplyingDemoVisibility = false
                return
            }
            studio.markSiteNeedsRefresh("Visibility details changed. Refresh the site export when ready.")
        }
    }

    private var progressLabel: String {
        let progress = studio.restaurant.visibilityChecklistProgress
        return "\(progress.completed)/\(progress.total)"
    }

    private static let fieldColumns = [
        GridItem(.adaptive(minimum: 220), spacing: 10, alignment: .top)
    ]
}

private struct VisibilityProgressDisclosure: View {
    let progressLabel: String
    let items: [VisibilityChecklistItem]
    @Binding var isExpanded: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button {
                withAnimation(.snappy(duration: 0.24)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 10) {
                    Label("Progress", systemImage: "checklist")
                        .font(.headline)
                        .foregroundStyle(SiteClawTheme.ink)

                    Spacer(minLength: 8)

                    StatusPill(title: progressLabel, systemImage: "checkmark.circle.fill", color: SiteClawTheme.mint)

                    Image(systemName: "chevron.down")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                        .accessibilityHidden(true)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Visibility checklist progress, \(progressLabel)")
            .accessibilityHint(isExpanded ? "Collapse progress details" : "Expand progress details")

            if isExpanded {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 230), spacing: 10)], spacing: 10) {
                    ForEach(items) { item in
                        VisibilityChecklistRow(item: item)
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(12)
        .background(SiteClawTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(SiteClawTheme.separator, lineWidth: 1)
        }
    }
}

private struct GrowthToolkitView: View {
    @Bindable var studio: SiteClawStudio
    @State private var demoMessage: String?
    @State private var isApplyingDemo = false

    var body: some View {
        ClawCard {
            if studio.hasGrowthToolkitAccess {
                unlockedGrowthToolkit
            } else {
                lockedGrowthToolkit
            }
        }
        .onChange(of: studio.restaurant.growthTools) { _, _ in
            if isApplyingDemo {
                isApplyingDemo = false
                return
            }
            studio.markSiteNeedsRefresh("Growth tools changed. Refresh the site export when ready.")
        }
    }

    private var unlockedGrowthToolkit: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Restaurant Growth Toolkit (Beta)")
                        .font(.headline)
                        .foregroundStyle(SiteClawTheme.ink)
                    Text("Optional modules that make SiteClaw feel like a working restaurant growth assistant.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 8)

                Button {
                    isApplyingDemo = true
                    studio.fillDemoGrowthTools()
                    demoMessage = "Demo growth modules enabled."
                } label: {
                    Label("Fill Demo Growth", systemImage: "sparkles")
                        .labelStyle(.titleAndIcon)
                }
                .buttonStyle(.borderedProminent)
                .tint(SiteClawTheme.gold)
                .controlSize(.small)
            }

            if !studio.recommendedGrowthToolLabels.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Recommended for this site")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.secondary)
                    FlowLayout(spacing: 8) {
                        ForEach(studio.recommendedGrowthToolLabels, id: \.self) { label in
                            StatusPill(title: label, systemImage: "sparkles", color: SiteClawTheme.mint)
                        }
                    }
                }
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 230), spacing: 10)], spacing: 10) {
                GrowthToolToggle(
                    title: "Specials",
                    detail: "Promote seasonal or limited-time dishes.",
                    systemImage: "sparkles",
                    isOn: $studio.restaurant.growthTools.specialsEnabled
                )
                GrowthToolToggle(
                    title: "Events",
                    detail: "Show happy hour, music, pop-ups, or tastings.",
                    systemImage: "calendar",
                    isOn: $studio.restaurant.growthTools.eventsEnabled
                )
                GrowthToolToggle(
                    title: "Catering Leads",
                    detail: "Point catering inquiries to a clear contact path.",
                    systemImage: "tray.full.fill",
                    isOn: $studio.restaurant.growthTools.cateringLeadFormEnabled
                )
                GrowthToolToggle(
                    title: "Gift Cards",
                    detail: "Surface gift-card buying when a link exists.",
                    systemImage: "giftcard.fill",
                    isOn: $studio.restaurant.growthTools.giftCardsEnabled
                )
                GrowthToolToggle(
                    title: "Review Links",
                    detail: "Guide customers to approved profile links.",
                    systemImage: "star.bubble.fill",
                    isOn: $studio.restaurant.growthTools.reviewLinksEnabled
                )
                GrowthToolToggle(
                    title: "QR Menu",
                    detail: "Prepare the site for table tents and flyers.",
                    systemImage: "qrcode",
                    isOn: $studio.restaurant.growthTools.qrMenuEnabled
                )
                GrowthToolToggle(
                    title: "Newsletter",
                    detail: "Capture interest for future restaurant updates.",
                    systemImage: "envelope.badge.fill",
                    isOn: $studio.restaurant.growthTools.newsletterEnabled
                )
                GrowthToolToggle(
                    title: "Analytics",
                    detail: "Track lightweight launch and conversion signals later.",
                    systemImage: "chart.bar.fill",
                    isOn: $studio.restaurant.growthTools.analyticsEnabled
                )
            }

            if let demoMessage {
                Label(demoMessage, systemImage: "checkmark.circle.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(SiteClawTheme.mint)
            }
        }
    }

    private var lockedGrowthToolkit: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                IconBadge(systemImage: "lock.fill", color: SiteClawTheme.gold, size: 42)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Growth Toolkit (Beta)")
                        .font(.headline)
                        .foregroundStyle(SiteClawTheme.ink)
                    Text("Available on the Growth plan at $49/month and on Pro. Change plans from Account & Settings > Billing.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            GrowthPlanGateRow(
                title: "Current Plan",
                value: studio.accountSettings.billingPlan,
                systemImage: "creditcard.fill"
            )

            GrowthPlanGateRow(
                title: "Included With",
                value: "Growth - $49/mo and Pro - $99/mo",
                systemImage: "sparkles"
            )
        }
    }
}

private struct GrowthPlanGateRow: View {
    let title: String
    let value: String
    let systemImage: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: systemImage)
                .foregroundStyle(SiteClawTheme.gold)
                .frame(width: 24, height: 24)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(SiteClawTheme.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(SiteClawTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct GrowthToolToggle: View {
    let title: String
    let detail: String
    let systemImage: String
    @Binding var isOn: Bool

    var body: some View {
        Toggle(isOn: $isOn) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: systemImage)
                    .foregroundStyle(isOn ? SiteClawTheme.mint : .secondary)
                    .frame(width: 24, height: 24)

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.caption.weight(.bold))
                    Text(detail)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .toggleStyle(.switch)
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 92, alignment: .leading)
        .background(isOn ? SiteClawTheme.mint.opacity(0.08) : SiteClawTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(isOn ? SiteClawTheme.mint.opacity(0.22) : SiteClawTheme.separator, lineWidth: 1)
        }
    }
}

private struct ContactVisibilityView: View {
    @Bindable var studio: SiteClawStudio

    var body: some View {
        VStack(spacing: 10) {
            ContactCorrectionsView(studio: studio)
            VisibilityChecklistView(studio: studio)
        }
    }
}

private struct PolicyNote: View {
    let title: String
    let text: String
    let systemImage: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: systemImage)
                .foregroundStyle(SiteClawTheme.gold)
                .frame(width: 24, height: 24)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(SiteClawTheme.ink)
                Text(text)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(SiteClawTheme.gold.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct VisibilityChecklistRow: View {
    let item: VisibilityChecklistItem

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: item.isComplete ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(item.isComplete ? SiteClawTheme.mint : .secondary)
                .frame(width: 22, height: 22)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                Text(item.title)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(SiteClawTheme.ink)
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
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(item.title), \(item.isComplete ? "complete" : "incomplete")")
    }
}

private struct LabeledTextField: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    var axis: Axis = .horizontal

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            TextField(placeholder, text: $text, axis: axis)
                .textFieldStyle(.roundedBorder)
                .accessibilityLabel(label)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct ConversationView: View {
    @Bindable var studio: SiteClawStudio
    @Binding var ownerNote: String
    @State private var showsRecentNotes = false

    var body: some View {
        VStack(spacing: 12) {
            SectionHeader(
                title: "Optional Notes",
                subtitle: "Add one more owner instruction without leaving the correction screen."
            )

            ClawCard {
                VStack(spacing: 12) {
                    HStack(spacing: 10) {
                        TextField("Add an owner note...", text: $ownerNote, axis: .vertical)
                            .textFieldStyle(.roundedBorder)
                            .lineLimit(1...3)

                        Button {
                            studio.applyQuickUpdate(ownerNote)
                            ownerNote = ""
                        } label: {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.title2)
                        }
                        .disabled(ownerNote.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .accessibilityLabel("Apply owner note")
                    }

                    if !studio.messages.isEmpty {
                        DisclosureGroup("Recent Notes", isExpanded: $showsRecentNotes) {
                            VStack(spacing: 10) {
                                ForEach(studio.messages.suffix(5)) { message in
                                    MessageBubble(message: message)
                                }
                            }
                            .padding(.top, 8)
                        }
                        .font(.subheadline.weight(.semibold))
                    }
                }
            }
        }
    }
}

private struct MessageBubble: View {
    let message: BuilderMessage

    var isOwner: Bool {
        message.role == .owner
    }

    var body: some View {
        HStack {
            if isOwner { Spacer(minLength: 36) }

            Text(message.text)
                .font(.subheadline)
                .foregroundStyle(isOwner ? .white : SiteClawTheme.ink)
                .padding(12)
                .background(isOwner ? SiteClawTheme.coral : SiteClawTheme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(.black.opacity(isOwner ? 0 : 0.06), lineWidth: 1)
                }

            if !isOwner { Spacer(minLength: 36) }
        }
    }
}

private struct BuildPrimaryActionBar: View {
    @Bindable var studio: SiteClawStudio
    let continueToPreview: (() -> Void)?

    var body: some View {
        PrimaryBottomAction(
            title: actionTitle,
            detail: actionDetail,
            systemImage: actionIcon,
            color: actionColor,
            action: performAction
        )
    }

    private var shouldOpenPreview: Bool {
        studio.isDraftGenerated && continueToPreview != nil
    }

    private var actionTitle: String {
        if shouldRefreshAndOpen {
            return "Refresh & Open Preview"
        }

        return shouldOpenPreview ? "Open Preview" : "Generate Restaurant Website"
    }

    private var actionIcon: String {
        if shouldRefreshAndOpen {
            return "arrow.clockwise"
        }

        return shouldOpenPreview ? "iphone" : "sparkles"
    }

    private var actionDetail: String {
        if shouldRefreshAndOpen {
            return "Recent edits will be folded into the preview before it opens."
        }

        return studio.isPublished
            ? "Published. Refresh before republishing changes."
            : "Not published yet. Nothing goes live until you approve it."
    }

    private var actionColor: Color {
        shouldOpenPreview ? SiteClawTheme.coral : SiteClawTheme.mint
    }

    private func performAction() {
        if shouldOpenPreview {
            if shouldRefreshAndOpen {
                studio.generateDraft()
            }

            continueToPreview?()
        } else {
            studio.generateDraft()
        }
    }

    private var shouldRefreshAndOpen: Bool {
        shouldOpenPreview && studio.isSiteExportStale
    }
}

private struct GenerateSiteButton: View {
    @Bindable var studio: SiteClawStudio

    var body: some View {
        Button {
            studio.generateDraft()
        } label: {
            Label("Generate Restaurant Website", systemImage: "sparkles")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .tint(SiteClawTheme.coral)
    }
}

#Preview {
    BuilderView(studio: SiteClawStudio.preview)
}

//
//  AccountSettingsView.swift
//  SiteClaw
//

import SwiftUI

struct AccountSettingsView: View {
    @Bindable var studio: SiteClawStudio

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                AccountStatusCard(studio: studio)
                AppAppearanceSettingsCard(studio: studio)
                OwnerPlanSummaryCard(studio: studio)
                OwnerProfileSettingsCard(studio: studio)
                RestaurantProfileSettingsCard(studio: studio)
                SiteDomainSettingsCard(studio: studio)
                BillingSettingsCard(studio: studio)
                WorkspaceDataSettingsCard(studio: studio)
                BusinessGrowthSettingsCard(studio: studio)
            }
            .padding(16)
            .padding(.bottom, SiteClawTheme.tabBarClearance)
        }
        .background(SiteClawTheme.background.ignoresSafeArea())
        .navigationTitle("Account & Settings")
        .siteClawNavigationChrome()
    }
}

struct AccountSettingsToolbarModifier: ViewModifier {
    let studio: SiteClawStudio
    @State private var isShowingSettings = false

    func body(content: Content) -> some View {
        content
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        isShowingSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                            .font(.headline.weight(.semibold))
                            .frame(width: 36, height: 36)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.regular)
                    .accessibilityLabel("Open account settings")
                }
            }
            .sheet(isPresented: $isShowingSettings) {
                NavigationStack {
                    AccountSettingsView(studio: studio)
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Done") {
                                    isShowingSettings = false
                                }
                            }
                        }
                }
            }
    }
}

extension View {
    func accountSettingsToolbar(studio: SiteClawStudio) -> some View {
        modifier(AccountSettingsToolbarModifier(studio: studio))
    }
}

private struct AppAppearanceSettingsCard: View {
    @Bindable var studio: SiteClawStudio

    var body: some View {
        SettingsCard(
            title: "App Appearance",
            subtitle: "Choose how the SiteClaw workspace looks on this device.",
            systemImage: studio.accountSettings.appearancePreference.systemImage,
            color: SiteClawTheme.sky
        ) {
            Picker("App appearance", selection: $studio.accountSettings.appearancePreference) {
                ForEach(SiteClawAppearancePreference.allCases) { preference in
                    Text(preference.title).tag(preference)
                }
            }
            .pickerStyle(.segmented)

            SettingsFactRow(
                title: "Current look",
                value: studio.accountSettings.appearancePreference.detail,
                systemImage: studio.accountSettings.appearancePreference.systemImage
            )
        }
    }
}

private struct OwnerPlanSummaryCard: View {
    let studio: SiteClawStudio

    var body: some View {
        SettingsCard(
            title: "Plan summary",
            subtitle: "Simple owner account details for this demo workspace.",
            systemImage: "checkmark.seal.fill",
            color: SiteClawTheme.mint
        ) {
            SettingsFactRow(title: "Current plan", value: studio.accountSettings.billingPlan, systemImage: "sparkles")
            SettingsFactRow(title: "Monthly price", value: "$\(studio.monthlyPrice)/mo", systemImage: "dollarsign.circle")
            SettingsFactRow(title: "Custom domain", value: customDomainValue, systemImage: "globe")
            SettingsFactRow(
                title: "Demo privacy",
                value: "Your uploaded menu and restaurant details stay in this workspace for the demo.",
                systemImage: "lock.shield"
            )
        }
    }

    private var customDomainValue: String {
        let domain = studio.accountSettings.customDomain.trimmingCharacters(in: .whitespacesAndNewlines)
        return domain.isEmpty ? "Optional - skip for now" : domain
    }
}

private struct AccountStatusCard: View {
    @Bindable var studio: SiteClawStudio

    var body: some View {
        ClawCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: studio.accountSettings.isSignedIn ? "person.crop.circle.badge.checkmark" : "person.crop.circle.badge.exclamationmark")
                        .font(.title2)
                        .foregroundStyle(studio.accountSettings.isSignedIn ? SiteClawTheme.mint : SiteClawTheme.gold)
                        .frame(width: 40, height: 40)
                        .background((studio.accountSettings.isSignedIn ? SiteClawTheme.mint : SiteClawTheme.gold).opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                    VStack(alignment: .leading, spacing: 4) {
                        Text(studio.accountSettings.isSignedIn ? "Demo Account Active" : "Signed Out Locally")
                            .font(.title2.bold())
                        Text("Mock account controls for local review. No Supabase, OAuth, or Stripe calls happen here.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer()

                    LabelPill(
                        title: studio.accountSettings.isSignedIn ? "Local" : "Paused",
                        systemImage: studio.accountSettings.isSignedIn ? "checkmark.seal.fill" : "pause.circle.fill",
                        color: studio.accountSettings.isSignedIn ? SiteClawTheme.mint : SiteClawTheme.gold
                    )
                }

                Button {
                    studio.accountSettings.isSignedIn.toggle()
                } label: {
                    Label(
                        studio.accountSettings.isSignedIn ? "Sign Out Demo Account" : "Sign In Demo Account",
                        systemImage: studio.accountSettings.isSignedIn ? "rectangle.portrait.and.arrow.right" : "person.badge.key"
                    )
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
        }
    }
}

private struct OwnerProfileSettingsCard: View {
    @Bindable var studio: SiteClawStudio

    var body: some View {
        CollapsibleSettingsCard(
            title: "Owner Profile",
            subtitle: "Basic account details for the restaurant owner.",
            systemImage: "person.text.rectangle.fill",
            color: SiteClawTheme.sky
        ) {
            LabeledSettingsField(label: "Owner Name", placeholder: "Owner name", text: $studio.accountSettings.ownerName)
            LabeledSettingsField(label: "Email", placeholder: "owner@example.com", text: $studio.accountSettings.email)
        }
    }
}

private struct RestaurantProfileSettingsCard: View {
    @Bindable var studio: SiteClawStudio

    var body: some View {
        CollapsibleSettingsCard(
            title: "Restaurant Profile",
            subtitle: "Owner-approved details SiteClaw uses when generating the site.",
            systemImage: "storefront.fill",
            color: SiteClawTheme.coral
        ) {
            LabeledSettingsField(label: "Restaurant Name", placeholder: "Restaurant name", text: $studio.restaurant.name)
            LabeledSettingsField(label: "Cuisine", placeholder: "Cuisine or restaurant type", text: $studio.restaurant.cuisine)
            LabeledSettingsField(label: "City", placeholder: "City", text: $studio.restaurant.neighborhood)
            LabeledSettingsField(label: "Hours", placeholder: "Operating hours", text: $studio.restaurant.hours, axis: .vertical)
                .lineLimit(2...4)
        }
    }
}

private struct SiteDomainSettingsCard: View {
    @Bindable var studio: SiteClawStudio

    var body: some View {
        CollapsibleSettingsCard(
            title: "Publishing Details",
            subtitle: "Publishing details for the generated restaurant website.",
            systemImage: "globe",
            color: SiteClawTheme.mint
        ) {
            LabeledSettingsField(label: "Site Subdomain", placeholder: "restaurant-slug", text: $studio.accountSettings.siteSubdomain)
            LabeledSettingsField(label: "Custom Domain", placeholder: "Optional - skip for now", text: $studio.accountSettings.customDomain)

            SettingsFactRow(title: "Preview URL", value: studio.draft.url, systemImage: "link")
            SettingsFactRow(title: "Publish Status", value: studio.publishStatus, systemImage: studio.isPublished ? "checkmark.circle.fill" : "clock")
        }
    }
}

private struct BillingSettingsCard: View {
    @Bindable var studio: SiteClawStudio
    @State private var isShowingPlans = false

    var body: some View {
        CollapsibleSettingsCard(
            title: "Billing",
            subtitle: "Placeholder billing surface for the MVP. Stripe stays out of this local branch.",
            systemImage: "creditcard.fill",
            color: SiteClawTheme.gold
        ) {
            SettingsFactRow(title: "Current Plan", value: studio.accountSettings.billingPlan, systemImage: "sparkles")
            SettingsFactRow(title: "Monthly Price", value: "$\(studio.monthlyPrice)/mo", systemImage: "dollarsign.circle")
            SettingsFactRow(title: "Usage", value: "\(studio.restaurant.menuItems.count) menu items, \(studio.draft.pages.count) generated pages", systemImage: "chart.bar.fill")

            Button {
                isShowingPlans = true
            } label: {
                Label("Change Plan", systemImage: "arrow.triangle.2.circlepath")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(SiteClawTheme.gold)
        }
        .sheet(isPresented: $isShowingPlans) {
            NavigationStack {
                PlanSelectionSheet(studio: studio)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Done") {
                                isShowingPlans = false
                            }
                        }
                    }
            }
        }
    }
}

private struct WorkspaceDataSettingsCard: View {
    @Bindable var studio: SiteClawStudio
    @State private var message: String?

    var body: some View {
        CollapsibleSettingsCard(
            title: "Workspace & Privacy",
            subtitle: "Local project storage, portability, and owner data controls.",
            systemImage: "externaldrive.fill",
            color: SiteClawTheme.sky
        ) {
            SettingsFactRow(title: "Autosave", value: studio.workspaceSummary, systemImage: "checkmark.icloud")
            SettingsFactRow(title: "Data Retention", value: studio.accountSettings.dataRetentionNote, systemImage: "lock.shield")
            SettingsFactRow(title: "Portable Assets", value: portableAssetSummary, systemImage: "photo.stack")

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 170), spacing: 10)], spacing: 10) {
                Button {
                    _ = studio.autosaveWorkspace()
                    message = "Workspace saved locally."
                } label: {
                    Label("Save Now", systemImage: "square.and.arrow.down")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(SiteClawTheme.sky)

                Button {
                    _ = studio.duplicateWorkspace()
                    message = "Workspace duplicated."
                } label: {
                    Label("Duplicate", systemImage: "plus.square.on.square")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                Button(role: .destructive) {
                    studio.resetToDemoWorkspace()
                    message = "Demo workspace restored."
                } label: {
                    Label("Reset Demo", systemImage: "arrow.counterclockwise")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }

            if let message {
                Label(message, systemImage: "checkmark.circle.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(SiteClawTheme.mint)
            }
        }
    }

    private var portableAssetSummary: String {
        let dishPhotos = studio.restaurant.menuItems.compactMap(\.image).count
        let menuAsset = studio.restaurant.uploadedMenu == nil ? 0 : 1
        return "\(dishPhotos + menuAsset) asset\(dishPhotos + menuAsset == 1 ? "" : "s") embedded in workspace package"
    }
}

private struct BusinessGrowthSettingsCard: View {
    @Bindable var studio: SiteClawStudio

    var body: some View {
        CollapsibleSettingsCard(
            title: "Business Growth",
            subtitle: studio.hasGrowthToolkitAccess
                ? "Recommended modules for the restaurant's current site direction."
                : "Growth Toolkit beta access starts on Growth and Pro.",
            systemImage: "chart.line.uptrend.xyaxis",
            color: SiteClawTheme.mint
        ) {
            if !studio.hasGrowthToolkitAccess {
                SettingsFactRow(
                    title: "Current Plan",
                    value: studio.accountSettings.billingPlan,
                    systemImage: "creditcard.fill"
                )
                SettingsFactRow(
                    title: "Included With",
                    value: "Growth - $49/mo and Pro - $99/mo",
                    systemImage: "lock.fill"
                )
                Text("Upgrade from Billing to enable the beta growth modules in Build.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                SettingsFactRow(
                    title: "Enabled Modules",
                    value: enabledModules,
                    systemImage: "sparkles"
                )
                SettingsFactRow(
                    title: "Recommendations",
                    value: studio.recommendedGrowthToolLabels.joined(separator: ", "),
                    systemImage: "lightbulb.fill"
                )
                Button {
                    studio.fillDemoGrowthTools()
                } label: {
                    Label("Enable Full Demo Toolkit", systemImage: "sparkles")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(SiteClawTheme.mint)
            }
        }
    }

    private var enabledModules: String {
        let labels = studio.restaurant.growthTools.enabledLabels
        return labels.isEmpty ? "No optional modules enabled" : labels.joined(separator: ", ")
    }
}

private struct PlanSelectionSheet: View {
    @Bindable var studio: SiteClawStudio

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                ForEach(SiteClawBillingPlan.options) { plan in
                    PlanOptionCard(
                        plan: plan,
                        isSelected: studio.accountSettings.billingPlan == plan.displayName
                    ) {
                        studio.selectBillingPlan(plan)
                    }
                }
            }
            .padding(16)
            .padding(.bottom, SiteClawTheme.tabBarClearance)
        }
        .background(SiteClawTheme.background.ignoresSafeArea())
        .navigationTitle("Choose Plan")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}

private struct PlanOptionCard: View {
    let plan: SiteClawBillingPlan
    let isSelected: Bool
    let selectAction: () -> Void

    var body: some View {
        ClawCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Text(plan.name)
                                .font(.title3.bold())

                            if isSelected {
                                LabelPill(title: "Current", systemImage: "checkmark.seal.fill", color: SiteClawTheme.mint)
                            }
                        }

                        Text(plan.subtitle)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 0)

                    HStack(alignment: .firstTextBaseline, spacing: 0) {
                        Text("$\(plan.price)")
                            .font(.title.bold())
                        Text("/mo")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.secondary)
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    ForEach(plan.features, id: \.self) { feature in
                        Label(feature, systemImage: "checkmark.circle.fill")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(SiteClawTheme.ink)
                    }
                }

                Button(action: selectAction) {
                    Label(isSelected ? "Selected" : "Select \(plan.name)", systemImage: isSelected ? "checkmark" : "arrow.right")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(isSelected ? SiteClawTheme.mint : SiteClawTheme.gold)
                .disabled(isSelected)
            }
        }
    }
}

private struct SettingsCard<Content: View>: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let color: Color
    private let content: Content

    init(
        title: String,
        subtitle: String,
        systemImage: String,
        color: Color,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.systemImage = systemImage
        self.color = color
        self.content = content()
    }

    var body: some View {
        ClawCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: systemImage)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(color)
                        .frame(width: 38, height: 38)
                        .background(color.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.headline)
                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                VStack(spacing: 12) {
                    content
                }
            }
        }
    }
}

private struct CollapsibleSettingsCard<Content: View>: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let color: Color
    private let content: Content
    @State private var isExpanded: Bool

    init(
        title: String,
        subtitle: String,
        systemImage: String,
        color: Color,
        initiallyExpanded: Bool = false,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.systemImage = systemImage
        self.color = color
        self.content = content()
        _isExpanded = State(initialValue: initiallyExpanded)
    }

    var body: some View {
        ClawCard {
            VStack(alignment: .leading, spacing: 14) {
                Button {
                    withAnimation(.snappy(duration: 0.24)) {
                        isExpanded.toggle()
                    }
                } label: {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: systemImage)
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(color)
                            .frame(width: 38, height: 38)
                            .background(color.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                            .accessibilityHidden(true)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(title)
                                .font(.headline)
                                .foregroundStyle(SiteClawTheme.ink)
                            Text(subtitle)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        Spacer(minLength: 8)

                        Image(systemName: "chevron.down")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.secondary)
                            .rotationEffect(.degrees(isExpanded ? 180 : 0))
                            .padding(.top, 8)
                            .accessibilityHidden(true)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(title)
                .accessibilityHint(isExpanded ? "Collapse section" : "Expand section")

                if isExpanded {
                    VStack(spacing: 12) {
                        content
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
    }
}

private struct LabeledSettingsField: View {
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
                #if os(iOS)
                .textInputAutocapitalization(label == "Email" || label.contains("Domain") || label.contains("Subdomain") ? .never : .sentences)
                #endif
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct SettingsFactRow: View {
    let title: String
    let value: String
    let systemImage: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: systemImage)
                .foregroundStyle(SiteClawTheme.sky)
                .frame(width: 24, height: 24)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(value.isEmpty ? "Not set" : value)
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

#Preview {
    NavigationStack {
        AccountSettingsView(studio: SiteClawStudio.preview)
    }
}

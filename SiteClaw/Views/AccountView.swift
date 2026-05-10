//
//  AccountView.swift
//  SiteClaw
//

import SwiftUI

struct AccountView: View {
    @Bindable var studio: SiteClawStudio
    @State private var email = "carlo@siteclaw.app"
    @State private var restaurantName = "Pho Lotus Kitchen"
    @State private var otpCode = ""
    @State private var authMode: AuthMode = .demo

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    AuthModeCard(mode: $authMode)

                    if studio.account.isAuthenticated {
                        AccountSummaryCard(studio: studio)
                    } else {
                        SignInShellCard(
                            studio: studio,
                            email: $email,
                            restaurantName: $restaurantName,
                            otpCode: $otpCode,
                            authMode: authMode
                        )
                    }

                    WorkspaceSummaryCard(studio: studio)
                    AccountPlanSummaryCard(studio: studio)
                }
                .padding(16)
            }
            .background(SiteClawTheme.background.ignoresSafeArea())
            .navigationTitle("Account")
        }
    }
}

private struct AccountReadinessSignal: Identifiable {
    let id = UUID()
    var title: String
    var value: String
    var detail: String
    var systemImage: String
    var color: Color
}

private enum AuthMode: String, CaseIterable, Identifiable {
    case demo = "Demo"
    case live = "Live"

    var id: Self { self }

    var detail: String {
        switch self {
        case .demo: "Instant local sign-in for class demo reliability."
        case .live: "Starts and verifies a Supabase email OTP through the backend."
        }
    }

    var statusTitle: String {
        switch self {
        case .demo: "No Network Required"
        case .live: "Backend Required"
        }
    }
}

private struct AuthModeCard: View {
    @Binding var mode: AuthMode

    var body: some View {
        ClawCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: mode == .demo ? "checkmark.shield.fill" : "network")
                        .font(.title3)
                        .foregroundStyle(mode == .demo ? SiteClawTheme.mint : SiteClawTheme.sky)
                        .frame(width: 32, height: 32)

                    VStack(alignment: .leading, spacing: 5) {
                        Text("Sign-In Mode")
                            .font(.headline)
                        Text(mode.detail)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer()

                    LabelPill(
                        title: mode.statusTitle,
                        systemImage: mode == .demo ? "bolt.fill" : "server.rack",
                        color: mode == .demo ? SiteClawTheme.mint : SiteClawTheme.sky
                    )
                }

                Picker("Sign-in mode", selection: $mode) {
                    ForEach(AuthMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
            }
        }
    }
}

private struct SignInShellCard: View {
    @Bindable var studio: SiteClawStudio
    @Binding var email: String
    @Binding var restaurantName: String
    @Binding var otpCode: String
    let authMode: AuthMode
    @State private var isSigningIn = false
    @State private var isVerifyingOTP = false
    @State private var isAwaitingOTP = false

    private var trimmedEmail: String {
        email.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var trimmedRestaurantName: String {
        restaurantName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        ClawCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: authMode == .demo ? "person.crop.circle.badge.checkmark" : "envelope.badge.shield.half.filled")
                        .font(.title2)
                        .foregroundStyle(authMode == .demo ? SiteClawTheme.coral : SiteClawTheme.sky)
                        .frame(width: 36, height: 36)

                    VStack(alignment: .leading, spacing: 5) {
                        Text(authMode == .demo ? "Demo Sign In" : "Supabase Email Sign In")
                            .font(.title3.bold())
                        Text(authMode == .demo
                            ? "Use a local account for the live class walkthrough."
                            : "Send a one-time code, then verify it without putting Supabase secrets in the app.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer()
                }

                VStack(spacing: 10) {
                    TextField("Email", text: $email)
                        .textFieldStyle(.roundedBorder)
                        .disabled(isSigningIn || isVerifyingOTP)

                    TextField("Restaurant name", text: $restaurantName)
                        .textFieldStyle(.roundedBorder)
                        .disabled(isSigningIn || isVerifyingOTP)

                    if authMode == .live && isAwaitingOTP {
                        TextField("Email code", text: $otpCode)
                            .textFieldStyle(.roundedBorder)
                            .disabled(isVerifyingOTP)
                    }
                }

                VStack(spacing: 10) {
                    Button {
                        Task {
                            await beginSignIn()
                        }
                    } label: {
                        ProgressLabel(
                            title: signInTitle,
                            systemImage: authMode == .demo ? "arrow.right.circle.fill" : "envelope.fill",
                            isLoading: isSigningIn,
                            progressTint: .white
                        )
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(SiteClawTheme.coral)
                    .disabled(!canBeginSignIn || isSigningIn || isVerifyingOTP)

                    if authMode == .live && isAwaitingOTP {
                        Button {
                            Task {
                                await verifyOTP()
                            }
                        } label: {
                            ProgressLabel(
                                title: "Verify Code",
                                systemImage: "checkmark.seal.fill",
                                isLoading: isVerifyingOTP,
                                progressTint: SiteClawTheme.sky
                            )
                        }
                        .buttonStyle(.bordered)
                        .tint(SiteClawTheme.sky)
                        .disabled(otpCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSigningIn || isVerifyingOTP)
                    }
                }

                StatusMessage(
                    text: studio.accountStatus,
                    kind: studio.account.isAuthenticated ? .success : (authMode == .live && isAwaitingOTP ? .pending : .neutral)
                )
            }
        }
        .onChange(of: authMode) {
            otpCode = ""
            isAwaitingOTP = false
        }
    }

    private var signInTitle: String {
        if isSigningIn {
            return authMode == .demo ? "Signing In" : "Sending Code"
        }

        return authMode == .demo ? "Sign In" : (isAwaitingOTP ? "Send New Code" : "Send Email Code")
    }

    private var canBeginSignIn: Bool {
        !trimmedEmail.isEmpty && !trimmedRestaurantName.isEmpty
    }

    private func beginSignIn() async {
        isSigningIn = true
        defer { isSigningIn = false }

        switch authMode {
        case .demo:
            await studio.signInWithMockGateway(email: email, restaurantName: restaurantName)
        case .live:
            await studio.startProductionSignIn(email: email, restaurantName: restaurantName)
            if !studio.account.isAuthenticated {
                isAwaitingOTP = true
            }
        }
    }

    private func verifyOTP() async {
        isVerifyingOTP = true
        defer { isVerifyingOTP = false }

        await studio.completeProductionSignIn(
            email: email,
            token: otpCode,
            restaurantName: restaurantName
        )

        if studio.account.isAuthenticated {
            otpCode = ""
            isAwaitingOTP = false
        }
    }
}

private struct AccountSummaryCard: View {
    @Bindable var studio: SiteClawStudio

    var body: some View {
        ClawCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "person.crop.circle.fill.badge.checkmark")
                        .font(.system(size: 44))
                        .foregroundStyle(SiteClawTheme.navy)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(studio.accountDisplayName)
                            .font(.title2.bold())
                        Text(studio.account.email)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }

                    Spacer()

                    LabelPill(title: studio.account.role, systemImage: "checkmark.seal.fill", color: SiteClawTheme.mint)
                }

                Divider()

                VStack(spacing: 10) {
                    AccountField(
                        title: "Restaurant",
                        value: studio.restaurant.name,
                        helpText: "The active restaurant or business profile SiteClaw uses to generate this website."
                    )
                    AccountField(
                        title: "Workspace",
                        value: workspaceLabel,
                        helpText: "The editable project area for this restaurant's site, content, publishing state, and settings."
                    )
                    AccountField(
                        title: "Sign-in",
                        value: signInLabel,
                        helpText: "Shows whether this account is using local Demo auth, a pending Live flow, or verified production auth."
                    )
                    AccountField(
                        title: "Last active",
                        value: lastActiveLabel,
                        helpText: "The most recent known account, workspace, or publishing activity in this app session."
                    )
                }

                Button {
                    studio.signOut()
                } label: {
                    Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                        .frame(maxWidth: .infinity, minHeight: 36)
                }
                .buttonStyle(.bordered)

                StatusMessage(text: studio.accountStatus, kind: .success)
            }
        }
    }

    private var workspaceLabel: String {
        studio.account.restaurantSlug.isEmpty ? "Demo workspace" : studio.account.restaurantSlug
    }

    private var signInLabel: String {
        if studio.account.authProvider.localizedCaseInsensitiveContains("supabase") {
            return studio.account.isAuthenticated ? "Live - Supabase verified" : "Live - code pending"
        }

        return "Demo - local account"
    }

    private var lastActiveLabel: String {
        if let lastSiteExportedAt = studio.lastSiteExportedAt {
            return lastSiteExportedAt.formatted(date: .abbreviated, time: .shortened)
        }

        return studio.account.lastSignedInAt?.formatted(date: .abbreviated, time: .shortened) ?? "Not recorded"
    }
}

private struct WorkspaceSummaryCard: View {
    @Bindable var studio: SiteClawStudio

    var body: some View {
        ClawCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "storefront.fill")
                        .font(.title2)
                        .foregroundStyle(SiteClawTheme.coral)
                        .frame(width: 36, height: 36)

                    VStack(alignment: .leading, spacing: 5) {
                        Text("Restaurant Workspace")
                            .font(.headline)
                        Text(studio.restaurant.name)
                            .font(.title3.bold())
                        Text(studio.draft.url)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }

                    Spacer()

                    LabelPill(
                        title: studio.publishStatus,
                        systemImage: studio.isPublished ? "checkmark.seal.fill" : "doc.badge.clock.fill",
                        color: studio.isPublished ? SiteClawTheme.mint : SiteClawTheme.gold
                    )
                }

                Divider()

                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(readinessScore)%")
                            .font(.largeTitle.bold())
                            .foregroundStyle(readinessColor)
                        Text("Site readiness score")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text(siteStatus)
                            .font(.headline)
                            .foregroundStyle(SiteClawTheme.ink)
                        Text(lastBuildLabel)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Divider()

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 132), spacing: 12)], spacing: 12) {
                    ForEach(readinessSignals) { signal in
                        WorkspaceMetric(signal: signal)
                    }
                }

                if !needsAttention.isEmpty {
                    Divider()

                    VStack(alignment: .leading, spacing: 8) {
                        Label("Needs attention", systemImage: "exclamationmark.triangle.fill")
                            .font(.headline)
                            .foregroundStyle(SiteClawTheme.gold)

                        ForEach(needsAttention, id: \.self) { item in
                            Label(item, systemImage: "circle.fill")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }

    private var readinessScore: Int {
        var completed = 0
        let checks = [
            !studio.restaurant.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
            !studio.restaurant.hours.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
            !studio.restaurant.menuItems.isEmpty,
            menuDetailsComplete,
            studio.draft.pages.count >= 3,
            studio.draft.seoKeywords.count >= 3,
            !studio.restaurant.phone.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
            !studio.restaurant.streetAddress.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
            studio.isDraftGenerated,
        ]

        for check in checks where check {
            completed += 1
        }

        return Int((Double(completed) / Double(checks.count)) * 100)
    }

    private var readinessColor: Color {
        if readinessScore >= 85 { return SiteClawTheme.mint }
        if readinessScore >= 65 { return SiteClawTheme.gold }
        return SiteClawTheme.coral
    }

    private var siteStatus: String {
        if studio.isPublished { return "Published" }
        if studio.missingDetails.isEmpty && studio.isDraftGenerated { return "Ready to publish" }
        if studio.isDraftGenerated { return "Needs review" }
        return "Draft needed"
    }

    private var lastBuildLabel: String {
        if let lastSiteExportedAt = studio.lastSiteExportedAt {
            return "Last published \(lastSiteExportedAt.formatted(date: .abbreviated, time: .shortened))"
        }

        return studio.isDraftGenerated ? "Draft generated this session" : "No build yet"
    }

    private var menuDetailsComplete: Bool {
        !studio.restaurant.menuItems.isEmpty && studio.restaurant.menuItems.allSatisfy {
            !$0.description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && (($0.price ?? 0) > 0)
        }
    }

    private var readinessSignals: [AccountReadinessSignal] {
        [
            AccountReadinessSignal(
                title: "Pages generated",
                value: "\(studio.draft.pages.count)",
                detail: studio.draft.pages.joined(separator: ", "),
                systemImage: "doc.text.fill",
                color: SiteClawTheme.sky
            ),
            AccountReadinessSignal(
                title: "Menu coverage",
                value: "\(studio.restaurant.menuItems.count)",
                detail: menuDetailsComplete ? "Prices and descriptions ready" : "Review item details",
                systemImage: "fork.knife",
                color: menuDetailsComplete ? SiteClawTheme.mint : SiteClawTheme.gold
            ),
            AccountReadinessSignal(
                title: "Hours",
                value: hasHours ? "Detected" : "Missing",
                detail: hasHours ? studio.restaurant.hours : "Add operating hours",
                systemImage: "clock.fill",
                color: hasHours ? SiteClawTheme.mint : SiteClawTheme.gold
            ),
            AccountReadinessSignal(
                title: "Contact",
                value: hasContact ? "Detected" : "Missing",
                detail: hasContact ? studio.restaurant.phone : "Add phone number",
                systemImage: "phone.fill",
                color: hasContact ? SiteClawTheme.mint : SiteClawTheme.gold
            ),
            AccountReadinessSignal(
                title: "Location",
                value: hasLocation ? "Detected" : "Missing",
                detail: hasLocation ? studio.restaurant.formattedAddress : "Add street address",
                systemImage: "mappin.and.ellipse",
                color: hasLocation ? SiteClawTheme.mint : SiteClawTheme.gold
            ),
            AccountReadinessSignal(
                title: "SEO basics",
                value: studio.draft.seoKeywords.count >= 3 ? "Ready" : "Needs terms",
                detail: "\(studio.draft.seoKeywords.count) search phrases",
                systemImage: "magnifyingglass",
                color: studio.draft.seoKeywords.count >= 3 ? SiteClawTheme.mint : SiteClawTheme.gold
            ),
            AccountReadinessSignal(
                title: "Corrections",
                value: "\(studio.missingDetails.count)",
                detail: studio.missingDetails.isEmpty ? "No required fixes" : "Owner review needed",
                systemImage: "checklist",
                color: studio.missingDetails.isEmpty ? SiteClawTheme.mint : SiteClawTheme.gold
            ),
            AccountReadinessSignal(
                title: "JSON schema",
                value: studio.restaurantJSONString.isEmpty ? "Check" : "Valid",
                detail: "restaurant.json export available",
                systemImage: "curlybraces",
                color: studio.restaurantJSONString.isEmpty ? SiteClawTheme.gold : SiteClawTheme.mint
            ),
        ]
    }

    private var needsAttention: [String] {
        var items = studio.missingDetails.map(\.title)

        if !hasContact {
            items.append("Contact info not detected")
        }

        if !hasLocation {
            items.append("Location/address not detected")
        }

        items.append("Photos/media not added yet")

        return Array(Set(items)).sorted()
    }

    private var hasHours: Bool {
        !studio.restaurant.hours.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var hasContact: Bool {
        !studio.restaurant.phone.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var hasLocation: Bool {
        !studio.restaurant.streetAddress.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

private struct AccountPlanSummaryCard: View {
    @Bindable var studio: SiteClawStudio

    var body: some View {
        ClawCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "creditcard.fill")
                        .font(.title2)
                        .foregroundStyle(SiteClawTheme.sky)
                        .frame(width: 36, height: 36)

                    VStack(alignment: .leading, spacing: 5) {
                        Text("Plan & Usage")
                            .font(.headline)
                        Text("\(studio.subscription.plan.title) - $\(studio.subscription.plan.monthlyPrice)/mo")
                            .font(.title3.bold())
                        Text(studio.subscription.plan.summary)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer()
                }

                Divider()

                AccountField(title: "Status", value: studio.subscription.status.title)
                AccountField(title: "Edit usage", value: studio.subscription.usageLabel)
                AccountField(title: "Renews", value: studio.billingRenewalLabel)
            }
        }
    }
}

private struct WorkspaceMetric: View {
    let signal: AccountReadinessSignal

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: signal.systemImage)
                .font(.headline)
                .foregroundStyle(signal.color)
            Text(signal.value)
                .font(.headline)
                .foregroundStyle(SiteClawTheme.ink)
            Text(signal.title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(signal.detail)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct ProgressLabel: View {
    let title: String
    let systemImage: String
    let isLoading: Bool
    let progressTint: Color

    var body: some View {
        HStack(spacing: 8) {
            if isLoading {
                ProgressView()
                    .controlSize(.small)
                    .tint(progressTint)
            } else {
                Image(systemName: systemImage)
            }

            Text(title)
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity, minHeight: 36)
    }
}

private enum StatusKind {
    case neutral
    case pending
    case success

    var color: Color {
        switch self {
        case .neutral: SiteClawTheme.sky
        case .pending: SiteClawTheme.gold
        case .success: SiteClawTheme.mint
        }
    }

    var icon: String {
        switch self {
        case .neutral: "info.circle.fill"
        case .pending: "clock.badge.checkmark.fill"
        case .success: "checkmark.circle.fill"
        }
    }
}

private struct StatusMessage: View {
    let text: String
    let kind: StatusKind

    var body: some View {
        Label {
            Text(text)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        } icon: {
            Image(systemName: kind.icon)
                .foregroundStyle(kind.color)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(kind.color.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct AccountField: View {
    let title: String
    let value: String
    var helpText: String? = nil

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            HStack(spacing: 5) {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                if let helpText {
                    AccountInfoButton(title: title, message: helpText)
                }
            }

            Spacer(minLength: 16)

            Text(value.isEmpty ? "Not set" : value)
                .font(.subheadline.weight(.medium))
                .multilineTextAlignment(.trailing)
                .lineLimit(2)
        }
    }
}

private struct AccountInfoButton: View {
    let title: String
    let message: String
    @State private var isPresented = false

    var body: some View {
        Button {
            isPresented.toggle()
        } label: {
            Image(systemName: "info.circle")
                .font(.caption)
                .foregroundStyle(SiteClawTheme.sky)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(title) info")
        .popover(isPresented: $isPresented) {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.headline)
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(16)
            .frame(width: 260, alignment: .leading)
        }
    }
}

#Preview {
    AccountView(studio: SiteClawStudio.preview)
}

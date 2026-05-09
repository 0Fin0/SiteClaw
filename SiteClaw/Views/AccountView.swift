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

                    GatewayStatusList(endpoints: studio.gatewayEndpoints)
                    SecretBoundaryList(items: studio.secretBoundary)
                }
                .padding(16)
            }
            .background(SiteClawTheme.background.ignoresSafeArea())
            .navigationTitle("Account")
            .toolbar {
                if studio.account.isAuthenticated {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            studio.signOut()
                        } label: {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                        }
                        .accessibilityLabel("Sign out")
                    }
                }
            }
        }
    }
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
                    AccountField(title: "Restaurant ID", value: studio.account.restaurantID)
                    AccountField(title: "Slug", value: studio.account.restaurantSlug)
                    AccountField(title: "Provider", value: studio.account.authProvider)
                    AccountField(
                        title: "Last sign in",
                        value: studio.account.lastSignedInAt?.formatted(date: .abbreviated, time: .shortened) ?? "Not recorded"
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

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Spacer(minLength: 16)
            Text(value.isEmpty ? "Not set" : value)
                .font(.subheadline.weight(.medium))
                .multilineTextAlignment(.trailing)
                .lineLimit(2)
        }
    }
}

private struct GatewayStatusList: View {
    let endpoints: [SiteClawGatewayEndpoint]

    var body: some View {
        VStack(spacing: 12) {
            SectionHeader(
                title: "Gateway Layer",
                subtitle: "Mock and production edges for auth, storage, billing, and pipeline calls."
            )

            ForEach(endpoints) { endpoint in
                ClawCard {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: icon(for: endpoint.kind))
                            .font(.title3)
                            .foregroundStyle(endpoint.keepsSecretOnBackend ? SiteClawTheme.coral : SiteClawTheme.sky)
                            .frame(width: 30, height: 30)

                        VStack(alignment: .leading, spacing: 5) {
                            HStack {
                                Text(endpoint.kind.title)
                                    .font(.headline)
                                Spacer()
                                LabelPill(title: endpoint.mode.title, systemImage: "switch.2", color: SiteClawTheme.sky)
                            }

                            Text(endpoint.status)
                                .font(.subheadline.weight(.semibold))
                            Text(endpoint.detail)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }

    private func icon(for kind: SiteClawGatewayKind) -> String {
        switch kind {
        case .supabaseAuth: "person.badge.key.fill"
        case .supabaseStorage: "externaldrive.fill"
        case .stripe: "creditcard.fill"
        case .pipeline: "arrow.triangle.2.circlepath"
        }
    }
}

private struct SecretBoundaryList: View {
    let items: [SiteClawSecretBoundary]

    var body: some View {
        VStack(spacing: 12) {
            SectionHeader(
                title: "Secret Boundary",
                subtitle: "Backend-only responsibilities that stay out of the native app."
            )

            ForEach(items) { item in
                ClawCard {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(item.title)
                                .font(.headline)
                            Spacer()
                            LabelPill(title: item.owner, systemImage: "lock.shield.fill", color: SiteClawTheme.mint)
                        }

                        Text(item.detail)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
}

#Preview {
    AccountView(studio: SiteClawStudio.preview)
}

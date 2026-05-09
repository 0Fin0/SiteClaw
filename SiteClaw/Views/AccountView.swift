//
//  AccountView.swift
//  SiteClaw
//

import SwiftUI

struct AccountView: View {
    @Bindable var studio: SiteClawStudio
    @State private var email = "carlo@siteclaw.app"
    @State private var restaurantName = "Pho Lotus Kitchen"
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
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        if studio.account.isAuthenticated {
                            studio.signOut()
                        } else {
                            Task {
                                await signIn()
                            }
                        }
                    } label: {
                        Image(systemName: studio.account.isAuthenticated ? "rectangle.portrait.and.arrow.right" : "person.badge.key.fill")
                    }
                    .accessibilityLabel(studio.account.isAuthenticated ? "Sign out" : "Sign in")
                }
            }
        }
    }

    private func signIn() async {
        switch authMode {
        case .demo:
            await studio.signInWithMockGateway(email: email, restaurantName: restaurantName)
        case .live:
            await studio.startProductionSignIn(email: email, restaurantName: restaurantName)
        }
    }
}

private enum AuthMode: String, CaseIterable, Identifiable {
    case demo = "Demo"
    case live = "Live"

    var id: Self { self }

    var detail: String {
        switch self {
        case .demo: "Instant local sign-in for the class demo."
        case .live: "Calls the backend Supabase OTP route when env vars are configured."
        }
    }
}

private struct AuthModeCard: View {
    @Binding var mode: AuthMode

    var body: some View {
        ClawCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "person.badge.key.fill")
                        .font(.title3)
                        .foregroundStyle(SiteClawTheme.sky)
                        .frame(width: 30, height: 30)

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Auth Mode")
                            .font(.headline)
                        Text(mode.detail)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                Picker("Auth mode", selection: $mode) {
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
    let authMode: AuthMode

    var body: some View {
        ClawCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Label(authMode == .demo ? "Demo Sign In" : "Supabase Sign In", systemImage: "person.badge.key.fill")
                        .font(.headline)
                        .foregroundStyle(SiteClawTheme.coral)
                    Spacer()
                    LabelPill(title: authMode.rawValue, systemImage: "switch.2", color: SiteClawTheme.sky)
                }

                Text(authMode == .demo
                    ? "Use mock auth to exercise account, billing, and ownership flow without network risk."
                    : "Starts Supabase email OTP through the backend. Email completion is the next live-session step.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                TextField("Email", text: $email)
                    .textFieldStyle(.roundedBorder)

                TextField("Restaurant name", text: $restaurantName)
                    .textFieldStyle(.roundedBorder)

                Button {
                    Task {
                        switch authMode {
                        case .demo:
                            await studio.signInWithMockGateway(email: email, restaurantName: restaurantName)
                        case .live:
                            await studio.startProductionSignIn(email: email, restaurantName: restaurantName)
                        }
                    }
                } label: {
                    Label(authMode == .demo ? "Sign In" : "Send Email Link", systemImage: authMode == .demo ? "arrow.right.circle.fill" : "envelope.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(SiteClawTheme.coral)

                Text(studio.accountStatus)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

private struct AccountSummaryCard: View {
    @Bindable var studio: SiteClawStudio

    var body: some View {
        ClawCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 42))
                        .foregroundStyle(SiteClawTheme.navy)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(studio.accountDisplayName)
                            .font(.title2.bold())
                        Text(studio.account.email)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    LabelPill(title: studio.account.role, systemImage: "checkmark.seal.fill", color: SiteClawTheme.mint)
                }

                Divider()

                AccountField(title: "Restaurant ID", value: studio.account.restaurantID)
                AccountField(title: "Slug", value: studio.account.restaurantSlug)
                AccountField(title: "Provider", value: studio.account.authProvider)
                AccountField(
                    title: "Last sign in",
                    value: studio.account.lastSignedInAt?.formatted(date: .abbreviated, time: .shortened) ?? "Not recorded"
                )

                Button {
                    studio.signOut()
                } label: {
                    Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                Text(studio.accountStatus)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
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
            Spacer()
            Text(value.isEmpty ? "Not set" : value)
                .font(.subheadline.weight(.medium))
                .multilineTextAlignment(.trailing)
        }
    }
}

private struct GatewayStatusList: View {
    let endpoints: [SiteClawGatewayEndpoint]

    var body: some View {
        VStack(spacing: 12) {
            SectionHeader(
                title: "Gateway Layer",
                subtitle: "Mock service seams for auth, storage, billing, and pipeline calls."
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
                subtitle: "Backend-only responsibilities that should stay out of the native app."
            )

            ForEach(items) { item in
                ClawCard {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(item.title)
                                .font(.headline)
                            Spacer()
                            LabelPill(title: item.owner, systemImage: "person.fill", color: SiteClawTheme.mint)
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

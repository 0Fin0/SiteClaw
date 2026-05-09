//
//  AccountView.swift
//  SiteClaw
//

import SwiftUI

struct AccountView: View {
    @Bindable var studio: SiteClawStudio
    @State private var email = "carlo@siteclaw.app"
    @State private var restaurantName = "Pho Lotus Kitchen"

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if studio.account.isAuthenticated {
                        AccountSummaryCard(studio: studio)
                    } else {
                        SignInShellCard(studio: studio, email: $email, restaurantName: $restaurantName)
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
                                await studio.signInWithMockGateway(email: email, restaurantName: restaurantName)
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
}

private struct SignInShellCard: View {
    @Bindable var studio: SiteClawStudio
    @Binding var email: String
    @Binding var restaurantName: String

    var body: some View {
        ClawCard {
            VStack(alignment: .leading, spacing: 14) {
                Label("Auth Shell", systemImage: "person.badge.key.fill")
                    .font(.headline)
                    .foregroundStyle(SiteClawTheme.coral)

                Text("Use mock auth to exercise the account, billing, and restaurant ownership flow before Supabase is connected.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                TextField("Email", text: $email)
                    .textFieldStyle(.roundedBorder)

                TextField("Restaurant name", text: $restaurantName)
                    .textFieldStyle(.roundedBorder)

                Button {
                    Task {
                        await studio.signInWithMockGateway(email: email, restaurantName: restaurantName)
                    }
                } label: {
                    Label("Sign In", systemImage: "arrow.right.circle.fill")
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

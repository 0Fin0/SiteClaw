//
//  MockLoginView.swift
//  SiteClaw
//

import SwiftUI

struct MockLoginView: View {
    @Bindable var studio: SiteClawStudio
    let completeLogin: () -> Void

    @State private var mode = MockAuthMode.login
    @State private var demoEmail = "owner@siteclaw.test"
    @State private var demoPassword = "siteclaw-preview"
    @State private var demoOwnerName = "Demo Owner"
    @State private var demoRestaurantName = "Sunset Grill"

    var body: some View {
        AppSurface(gradient: authGradient) {
            ScrollView {
                VStack(spacing: 16) {
                    authHero
                    authModePicker

                    if mode == .login {
                        loginCard
                    } else {
                        signUpCard
                    }
                }
                .padding(18)
                .padding(.top, 16)
                .padding(.bottom, SiteClawTheme.tabBarClearance)
                .frame(maxWidth: 560)
                .frame(maxWidth: .infinity)
            }
        }
    }

    private var authGradient: [Color] {
        [
            SiteClawTheme.sky.opacity(0.14),
            SiteClawTheme.coral.opacity(0.10),
            SiteClawTheme.mint.opacity(0.10)
        ]
    }

    private var authHero: some View {
        VStack(spacing: 12) {
            Image("SiteClawLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 88, height: 88)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .shadow(color: SiteClawTheme.ink.opacity(0.12), radius: 12, y: 6)
                .accessibilityHidden(true)

            VStack(spacing: 6) {
                Text("SiteClaw")
                    .font(.title.bold())
                    .foregroundStyle(SiteClawTheme.ink)

                Text("Restaurant websites built from a quick owner walkthrough.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.top, 4)
    }

    private var authModePicker: some View {
        Picker("Account Mode", selection: $mode) {
            ForEach(MockAuthMode.allCases) { mode in
                Text(mode.title).tag(mode)
            }
        }
        .pickerStyle(.segmented)
        .accessibilityLabel("Choose login or sign up")
    }

    private var loginCard: some View {
        ClawCard {
            VStack(alignment: .leading, spacing: 14) {
                formHeader(
                    title: "Continue with Demo",
                    subtitle: "Open the prepared restaurant workspace and walk through the app.",
                    systemImage: "person.badge.key.fill",
                    color: SiteClawTheme.sky
                )

                Button {
                    acceptDemoLogin()
                } label: {
                    Label("Continue with Demo", systemImage: "arrow.right.circle.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .tint(SiteClawTheme.coral)

                Divider()

                Text("Account details")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)

                LabeledMockAuthField(label: "Username", placeholder: "demo@example.com", text: $demoEmail)
                    #if os(iOS)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                    #endif

                LabeledMockAuthField(label: "Password", placeholder: "demo password", text: $demoPassword)
                    #if os(iOS)
                    .textInputAutocapitalization(.never)
                    #endif
            }
        }
    }

    private var signUpCard: some View {
        ClawCard {
            VStack(alignment: .leading, spacing: 14) {
                formHeader(
                    title: "Create Account",
                    subtitle: "Start your restaurant workspace.",
                    systemImage: "person.crop.circle.badge.plus",
                    color: SiteClawTheme.mint
                )

                LabeledMockAuthField(label: "Owner Name", placeholder: "Owner name", text: $demoOwnerName)
                LabeledMockAuthField(label: "Email", placeholder: "owner@example.com", text: $demoEmail)
                    #if os(iOS)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                    #endif
                LabeledMockAuthField(label: "Restaurant", placeholder: "Restaurant name", text: $demoRestaurantName)

                Button {
                    acceptDemoSignUp()
                } label: {
                    Label("Create Account", systemImage: "arrow.right.circle.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(SiteClawTheme.mint)
            }
        }
    }

    private func formHeader(
        title: String,
        subtitle: String,
        systemImage: String,
        color: Color
    ) -> some View {
        HStack(alignment: .top, spacing: 12) {
            IconBadge(systemImage: systemImage, color: color)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func acceptDemoLogin() {
        studio.accountSettings.ownerName = demoOwnerName
        studio.accountSettings.email = demoEmail
        studio.restaurant.ownerName = demoOwnerName
        studio.accountSettings.isSignedIn = true
        completeLogin()
    }

    private func acceptDemoSignUp() {
        studio.accountSettings.ownerName = demoOwnerName
        studio.accountSettings.email = demoEmail
        studio.restaurant.ownerName = demoOwnerName
        if !demoRestaurantName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            studio.restaurant.name = demoRestaurantName
        }
        studio.accountSettings.isSignedIn = true
        completeLogin()
    }
}

private enum MockAuthMode: String, CaseIterable, Identifiable {
    case login
    case signUp

    var id: String { rawValue }

    var title: String {
        switch self {
        case .login: "Login"
        case .signUp: "Sign Up"
        }
    }
}

private struct LabeledMockAuthField: View {
    let label: String
    let placeholder: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            TextField(placeholder, text: $text)
                .textFieldStyle(.roundedBorder)
                .accessibilityLabel(label)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    MockLoginView(studio: SiteClawStudio.preview) {}
}

//
//  Mock.swift
//  SiteClaw
//

import Foundation

enum SiteClawMock {
    static let account = SiteClawAccount(
        ownerName: "Carlo Rivera",
        email: "carlo@siteclaw.app",
        restaurantID: "00000000-0000-0000-0000-000000000001",
        restaurantSlug: "pho-lotus-kitchen",
        authProvider: "Email",
        role: "Owner",
        lastSignedInAt: Date(timeIntervalSinceNow: -3600),
        isAuthenticated: true
    )

    static let signedOutAccount = SiteClawAccount(
        ownerName: "",
        email: "",
        restaurantID: "",
        restaurantSlug: "",
        authProvider: "",
        role: "Owner",
        lastSignedInAt: nil,
        isAuthenticated: false
    )

    static let subscription = SiteClawSubscription(
        plan: .starter,
        status: .active,
        editsThisPeriod: 2,
        currentPeriodEnd: Calendar.current.date(byAdding: .day, value: 21, to: Date()),
        stripeCustomerID: "cus_mock_siteclaw",
        stripeSubscriptionID: "sub_mock_siteclaw"
    )

    static let gatewayEndpoints: [SiteClawGatewayEndpoint] = [
        SiteClawGatewayEndpoint(
            kind: .supabaseAuth,
            mode: .mock,
            status: "Shell ready",
            detail: "Account state is local until Supabase Auth is wired.",
            keepsSecretOnBackend: false
        ),
        SiteClawGatewayEndpoint(
            kind: .supabaseStorage,
            mode: .mock,
            status: "Contract ready",
            detail: "restaurant.json is generated in-app and ready to move behind service-role storage writes.",
            keepsSecretOnBackend: true
        ),
        SiteClawGatewayEndpoint(
            kind: .stripe,
            mode: .mock,
            status: "Plans mocked",
            detail: "Starter and Pro selections update local subscription state only.",
            keepsSecretOnBackend: true
        ),
        SiteClawGatewayEndpoint(
            kind: .pipeline,
            mode: .mock,
            status: "Boundary defined",
            detail: "The native app calls a gateway surface instead of owning provider secrets.",
            keepsSecretOnBackend: true
        ),
    ]

    static let secretBoundary: [SiteClawSecretBoundary] = [
        SiteClawSecretBoundary(
            title: "Native app uses public credentials only",
            detail: "The app may hold Supabase anon configuration and short-lived client tokens, but never service role, Stripe secret, or OpenAI API keys.",
            owner: "Carlo"
        ),
        SiteClawSecretBoundary(
            title: "Backend owns privileged writes",
            detail: "Restaurant storage writes, Stripe checkout, customer portal, and provider API calls stay behind backend routes.",
            owner: "Carlo"
        ),
        SiteClawSecretBoundary(
            title: "Omar's Realtime token route stays isolated",
            detail: "The existing backend mints short-lived Realtime client secrets without exposing the OpenAI API key to SwiftUI.",
            owner: "Omar"
        ),
    ]
}

//
//  GatewayService.swift
//  SiteClaw
//

import Foundation

protocol SiteClawGatewaying: Sendable {
    func signIn(email: String, restaurantName: String) async throws -> SiteClawAccount
    func checkout(plan: SiteClawSubscriptionPlan, currentSubscription: SiteClawSubscription) async throws -> SiteClawSubscription
    func openCustomerPortal(for account: SiteClawAccount) async throws -> String
}

enum SiteClawGatewayError: LocalizedError {
    case missingEmail
    case missingRestaurantName
    case signedOut

    var errorDescription: String? {
        switch self {
        case .missingEmail: "Enter an email address before signing in."
        case .missingRestaurantName: "Enter a restaurant name before signing in."
        case .signedOut: "Sign in before managing billing."
        }
    }
}

struct MockSiteClawGateway: SiteClawGatewaying {
    func signIn(email: String, restaurantName: String) async throws -> SiteClawAccount {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedRestaurant = restaurantName.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedEmail.isEmpty else { throw SiteClawGatewayError.missingEmail }
        guard !trimmedRestaurant.isEmpty else { throw SiteClawGatewayError.missingRestaurantName }

        return SiteClawAccount(
            ownerName: trimmedEmail.components(separatedBy: "@").first.map(Self.titleCased) ?? "Restaurant Owner",
            email: trimmedEmail,
            restaurantID: "00000000-0000-0000-0000-000000000001",
            restaurantSlug: Self.slug(for: trimmedRestaurant),
            authProvider: "Email",
            role: "Owner",
            lastSignedInAt: Date(),
            isAuthenticated: true
        )
    }

    func checkout(
        plan: SiteClawSubscriptionPlan,
        currentSubscription: SiteClawSubscription
    ) async throws -> SiteClawSubscription {
        var subscription = currentSubscription
        subscription.plan = plan
        subscription.status = .active
        subscription.currentPeriodEnd = Calendar.current.date(byAdding: .month, value: 1, to: Date())
        subscription.stripeCustomerID = plan == .founding ? nil : "cus_mock_siteclaw"
        subscription.stripeSubscriptionID = plan == .founding ? nil : "sub_mock_siteclaw"
        return subscription
    }

    func openCustomerPortal(for account: SiteClawAccount) async throws -> String {
        guard account.isAuthenticated else { throw SiteClawGatewayError.signedOut }
        return "https://billing.stripe.com/mock/siteclaw"
    }

    private static func slug(for value: String) -> String {
        value
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: "-")
    }

    private static func titleCased(_ value: String) -> String {
        value
            .split(separator: ".")
            .flatMap { $0.split(separator: "-") }
            .map { part in
                part.prefix(1).uppercased() + part.dropFirst().lowercased()
            }
            .joined(separator: " ")
    }
}

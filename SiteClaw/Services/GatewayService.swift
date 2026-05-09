//
//  GatewayService.swift
//  SiteClaw
//

import Foundation

protocol SiteClawGatewaying: Sendable {
    func signIn(email: String, restaurantName: String) async throws -> SiteClawAccount
    func checkout(plan: SiteClawSubscriptionPlan, currentSubscription: SiteClawSubscription) async throws -> SiteClawCheckoutResult
    func openCustomerPortal(for account: SiteClawAccount) async throws -> String
}

enum SiteClawGatewayError: LocalizedError {
    case missingEmail
    case missingRestaurantName
    case signedOut
    case invalidBackendURL
    case invalidResponse
    case serverError(String)

    var errorDescription: String? {
        switch self {
        case .missingEmail: "Enter an email address before signing in."
        case .missingRestaurantName: "Enter a restaurant name before signing in."
        case .signedOut: "Sign in before managing billing."
        case .invalidBackendURL: "The SiteClaw backend URL is not valid."
        case .invalidResponse: "The SiteClaw backend returned an invalid response."
        case .serverError(let message): message
        }
    }
}

struct ProductionSiteClawGateway: SiteClawGatewaying {
    var baseURL = URL(string: "http://localhost:8787")!
    var successURL = URL(string: "https://siteclaw.app/billing/success")!
    var cancelURL = URL(string: "https://siteclaw.app/billing/cancel")!

    func signIn(email: String, restaurantName: String) async throws -> SiteClawAccount {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedRestaurant = restaurantName.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedEmail.isEmpty else { throw SiteClawGatewayError.missingEmail }
        guard !trimmedRestaurant.isEmpty else { throw SiteClawGatewayError.missingRestaurantName }

        let request = SignInRequest(email: trimmedEmail, restaurantName: trimmedRestaurant)
        let response: SignInResponse = try await post(request, path: "/api/auth/sign-in")
        return response.account
    }

    func checkout(
        plan: SiteClawSubscriptionPlan,
        currentSubscription: SiteClawSubscription
    ) async throws -> SiteClawCheckoutResult {
        let request = CheckoutRequest(
            plan: plan,
            restaurantID: nil,
            successURL: successURL.absoluteString,
            cancelURL: cancelURL.absoluteString
        )
        let response: CheckoutResponse = try await post(request, path: "/api/billing/checkout")
        return SiteClawCheckoutResult(
            subscription: response.subscription ?? updatedSubscription(plan: plan, from: currentSubscription),
            checkoutURL: response.url.flatMap(URL.init(string:))
        )
    }

    func openCustomerPortal(for account: SiteClawAccount) async throws -> String {
        guard account.isAuthenticated else { throw SiteClawGatewayError.signedOut }

        let request = PortalRequest(
            customerID: nil,
            email: account.email,
            returnURL: successURL.absoluteString
        )
        let response: PortalResponse = try await post(request, path: "/api/billing/portal")
        return response.url
    }

    private func post<RequestBody: Encodable, ResponseBody: Decodable>(
        _ body: RequestBody,
        path: String
    ) async throws -> ResponseBody {
        guard let url = URL(string: path, relativeTo: baseURL) else {
            throw SiteClawGatewayError.invalidBackendURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder.siteClaw.encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw SiteClawGatewayError.invalidResponse
        }

        if !(200..<300).contains(httpResponse.statusCode) {
            let error = try? JSONDecoder.siteClaw.decode(GatewayErrorResponse.self, from: data)
            throw SiteClawGatewayError.serverError(error?.error ?? "SiteClaw backend request failed.")
        }

        return try JSONDecoder.siteClaw.decode(ResponseBody.self, from: data)
    }

    private func updatedSubscription(
        plan: SiteClawSubscriptionPlan,
        from currentSubscription: SiteClawSubscription
    ) -> SiteClawSubscription {
        SiteClawSubscription(
            plan: plan,
            status: currentSubscription.status,
            editsThisPeriod: currentSubscription.editsThisPeriod,
            currentPeriodEnd: currentSubscription.currentPeriodEnd,
            stripeCustomerID: currentSubscription.stripeCustomerID,
            stripeSubscriptionID: currentSubscription.stripeSubscriptionID
        )
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
    ) async throws -> SiteClawCheckoutResult {
        var subscription = currentSubscription
        subscription.plan = plan
        subscription.status = .active
        subscription.currentPeriodEnd = Calendar.current.date(byAdding: .month, value: 1, to: Date())
        subscription.stripeCustomerID = plan == .founding ? nil : "cus_mock_siteclaw"
        subscription.stripeSubscriptionID = plan == .founding ? nil : "sub_mock_siteclaw"
        return SiteClawCheckoutResult(subscription: subscription, checkoutURL: nil)
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

private struct SignInRequest: Encodable {
    var email: String
    var restaurantName: String

    enum CodingKeys: String, CodingKey {
        case email
        case restaurantName = "restaurant_name"
    }
}

private struct SignInResponse: Decodable {
    var account: SiteClawAccount
}

private struct CheckoutRequest: Encodable {
    var plan: SiteClawSubscriptionPlan
    var restaurantID: String?
    var successURL: String
    var cancelURL: String

    enum CodingKeys: String, CodingKey {
        case plan
        case restaurantID = "restaurant_id"
        case successURL = "success_url"
        case cancelURL = "cancel_url"
    }
}

private struct CheckoutResponse: Decodable {
    var url: String?
    var subscription: SiteClawSubscription?
}

private struct PortalRequest: Encodable {
    var customerID: String?
    var email: String
    var returnURL: String

    enum CodingKeys: String, CodingKey {
        case customerID = "customer_id"
        case email
        case returnURL = "return_url"
    }
}

private struct PortalResponse: Decodable {
    var url: String
}

private struct GatewayErrorResponse: Decodable {
    var error: String
}

private extension JSONEncoder {
    static var siteClaw: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
}

private extension JSONDecoder {
    static var siteClaw: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}

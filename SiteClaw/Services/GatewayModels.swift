//
//  GatewayModels.swift
//  SiteClaw
//

import Foundation

struct SiteClawAccount: Hashable, Sendable {
    var ownerName: String
    var email: String
    var restaurantID: String
    var restaurantSlug: String
    var authProvider: String
    var role: String
    var lastSignedInAt: Date?
    var isAuthenticated: Bool
}

enum SiteClawSubscriptionPlan: String, CaseIterable, Hashable, Sendable {
    case founding
    case starter
    case pro

    var title: String {
        switch self {
        case .founding: "Founding"
        case .starter: "Starter"
        case .pro: "Pro"
        }
    }

    var monthlyPrice: Int {
        switch self {
        case .founding: 0
        case .starter: 19
        case .pro: 79
        }
    }

    var editLimit: Int {
        switch self {
        case .founding, .pro: -1
        case .starter: 5
        }
    }

    var summary: String {
        switch self {
        case .founding: "Free forever access for early SiteClaw partners."
        case .starter: "Small operator pricing with 5 edits per billing period."
        case .pro: "Unlimited edits plus custom domain readiness."
        }
    }
}

enum SiteClawSubscriptionStatus: String, Hashable, Sendable {
    case active
    case trialing
    case pastDue
    case cancelled

    var title: String {
        switch self {
        case .active: "Active"
        case .trialing: "Trialing"
        case .pastDue: "Past due"
        case .cancelled: "Cancelled"
        }
    }
}

struct SiteClawSubscription: Hashable, Sendable {
    var plan: SiteClawSubscriptionPlan
    var status: SiteClawSubscriptionStatus
    var editsThisPeriod: Int
    var currentPeriodEnd: Date?
    var stripeCustomerID: String?
    var stripeSubscriptionID: String?

    var editLimit: Int {
        plan.editLimit
    }

    var hasUnlimitedEdits: Bool {
        editLimit < 0
    }

    var usageLabel: String {
        hasUnlimitedEdits ? "\(editsThisPeriod) edits used" : "\(editsThisPeriod)/\(editLimit) edits used"
    }

    var usageProgress: Double {
        guard editLimit > 0 else { return 0 }
        return min(Double(editsThisPeriod) / Double(editLimit), 1)
    }
}

enum SiteClawGatewayKind: String, CaseIterable, Hashable, Sendable {
    case supabaseAuth
    case supabaseStorage
    case stripe
    case pipeline

    var title: String {
        switch self {
        case .supabaseAuth: "Supabase Auth"
        case .supabaseStorage: "Supabase Storage"
        case .stripe: "Stripe Billing"
        case .pipeline: "Pipeline API"
        }
    }
}

enum SiteClawGatewayMode: String, Hashable, Sendable {
    case mock
    case production

    var title: String {
        switch self {
        case .mock: "Mock"
        case .production: "Production"
        }
    }
}

struct SiteClawGatewayEndpoint: Identifiable, Hashable, Sendable {
    var id: SiteClawGatewayKind { kind }
    var kind: SiteClawGatewayKind
    var mode: SiteClawGatewayMode
    var status: String
    var detail: String
    var keepsSecretOnBackend: Bool
}

struct SiteClawSecretBoundary: Identifiable, Hashable, Sendable {
    let id = UUID()
    var title: String
    var detail: String
    var owner: String
}

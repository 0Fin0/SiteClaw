//
//  BillingView.swift
//  SiteClaw
//

import SwiftUI

struct BillingView: View {
    @Bindable var studio: SiteClawStudio
    @Environment(\.openURL) private var openURL
    @State private var billingMode: BillingMode = .demo

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    BillingModeCard(mode: $billingMode)
                    CurrentPlanCard(studio: studio, billingMode: billingMode) {
                        Task {
                            await openCustomerPortal()
                        }
                    }
                    UsageCard(subscription: studio.subscription)
                    PlanComparisonGrid(studio: studio, billingMode: billingMode) { plan in
                        Task {
                            await choosePlan(plan)
                        }
                    }
                }
                .padding(16)
            }
            .background(SiteClawTheme.background.ignoresSafeArea())
            .navigationTitle("Billing")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        Task {
                            await openCustomerPortal()
                        }
                    } label: {
                        Image(systemName: "arrow.up.forward.app.fill")
                    }
                    .disabled(!studio.account.isAuthenticated)
                    .accessibilityLabel("Open customer portal")
                }
            }
        }
    }

    private func choosePlan(_ plan: SiteClawSubscriptionPlan) async {
        switch billingMode {
        case .demo:
            await studio.chooseBillingPlan(plan)
        case .live:
            guard plan != .founding else {
                studio.billingStatus = "Founding partner plans are assigned manually, not through Stripe Checkout."
                return
            }

            guard let url = await studio.startProductionCheckout(plan) else {
                return
            }

            openURL(url)
        }
    }

    private func openCustomerPortal() async {
        switch billingMode {
        case .demo:
            await studio.openMockCustomerPortal()
        case .live:
            guard let url = await studio.startProductionCustomerPortal() else {
                return
            }

            openURL(url)
        }
    }
}

private enum BillingMode: String, CaseIterable, Identifiable {
    case demo = "Demo"
    case live = "Live"

    var id: Self { self }

    var detail: String {
        switch self {
        case .demo: "Instant local plan switching for the class demo."
        case .live: "Calls the backend and opens Stripe-hosted pages when env vars are configured."
        }
    }
}

private struct BillingModeCard: View {
    @Binding var mode: BillingMode

    var body: some View {
        ClawCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "switch.2")
                        .font(.title3)
                        .foregroundStyle(SiteClawTheme.sky)
                        .frame(width: 30, height: 30)

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Billing Mode")
                            .font(.headline)
                        Text(mode.detail)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                Picker("Billing mode", selection: $mode) {
                    ForEach(BillingMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
            }
        }
    }
}

private struct CurrentPlanCard: View {
    @Bindable var studio: SiteClawStudio
    let billingMode: BillingMode
    let manageAction: () -> Void

    var body: some View {
        ClawCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("\(studio.subscription.plan.title) Plan")
                            .font(.title2.bold())
                        Text(studio.subscription.plan.summary)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    LabelPill(
                        title: studio.subscription.status.title,
                        systemImage: "checkmark.circle.fill",
                        color: SiteClawTheme.mint
                    )
                }

                HStack(alignment: .firstTextBaseline) {
                    Text("$\(studio.subscription.plan.monthlyPrice)")
                        .font(.largeTitle.bold())
                    Text("/mo")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(studio.billingRenewalLabel)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                }

                Button {
                    manageAction()
                } label: {
                    Label(
                        manageTitle,
                        systemImage: billingMode == .live ? "safari.fill" : "creditcard.and.123"
                    )
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(studio.canUseCustomerPortal ? SiteClawTheme.navy : SiteClawTheme.sky)
                .disabled(!studio.account.isAuthenticated)

                Text(studio.billingStatus)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var manageTitle: String {
        switch billingMode {
        case .demo:
            studio.canUseCustomerPortal ? "Manage Subscription" : "Portal Pending"
        case .live:
            "Open Stripe Portal"
        }
    }
}

private struct UsageCard: View {
    let subscription: SiteClawSubscription

    var body: some View {
        ClawCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label("Edit Usage", systemImage: "slider.horizontal.3")
                        .font(.headline)
                    Spacer()
                    Text(subscription.usageLabel)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                }

                if subscription.hasUnlimitedEdits {
                    Label("Unlimited edits for this plan", systemImage: "infinity")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(SiteClawTheme.mint)
                } else {
                    ProgressView(value: subscription.usageProgress)
                        .tint(subscription.usageProgress >= 1 ? SiteClawTheme.coral : SiteClawTheme.mint)
                    Text("\(max(subscription.editLimit - subscription.editsThisPeriod, 0)) edits remaining this period")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

private struct PlanComparisonGrid: View {
    @Bindable var studio: SiteClawStudio
    let billingMode: BillingMode
    let action: (SiteClawSubscriptionPlan) -> Void

    var body: some View {
        VStack(spacing: 12) {
            SectionHeader(
                title: "Plans",
                subtitle: billingMode == .demo
                    ? "Demo mode updates local plan state instantly."
                    : "Live mode opens Stripe Checkout for paid plans."
            )

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 220), spacing: 12)], spacing: 12) {
                ForEach(SiteClawSubscriptionPlan.allCases, id: \.self) { plan in
                    PlanCard(
                        plan: plan,
                        isCurrent: plan == studio.subscription.plan,
                        billingMode: billingMode
                    ) {
                        action(plan)
                    }
                }
            }
        }
    }
}

private struct PlanCard: View {
    let plan: SiteClawSubscriptionPlan
    let isCurrent: Bool
    let billingMode: BillingMode
    let action: () -> Void

    var body: some View {
        ClawCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(plan.title)
                        .font(.headline)
                    Spacer()
                    if isCurrent {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(SiteClawTheme.mint)
                    }
                }

                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("$\(plan.monthlyPrice)")
                        .font(.title.bold())
                    Text("/mo")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Text(plan.summary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                Label(editLabel, systemImage: plan.editLimit < 0 ? "infinity" : "pencil.and.list.clipboard")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(SiteClawTheme.sky)

                Button {
                    action()
                } label: {
                    Label(buttonTitle, systemImage: buttonIcon)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(isCurrent ? SiteClawTheme.mint : SiteClawTheme.coral)
                .disabled(isCurrent || (billingMode == .live && plan == .founding))
            }
        }
    }

    private var editLabel: String {
        plan.editLimit < 0 ? "Unlimited edits" : "\(plan.editLimit) edits per period"
    }

    private var buttonTitle: String {
        if isCurrent {
            return "Current Plan"
        }

        if billingMode == .live {
            return plan == .founding ? "Manual Only" : "Open Checkout"
        }

        return "Select"
    }

    private var buttonIcon: String {
        if isCurrent {
            return "checkmark"
        }

        if billingMode == .live {
            return plan == .founding ? "person.badge.shield.checkmark.fill" : "safari.fill"
        }

        return "arrow.right"
    }
}

#Preview {
    BillingView(studio: SiteClawStudio.preview)
}

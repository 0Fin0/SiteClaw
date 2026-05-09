//
//  BillingView.swift
//  SiteClaw
//

import SwiftUI

struct BillingView: View {
    @Bindable var studio: SiteClawStudio

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    CurrentPlanCard(studio: studio)
                    UsageCard(subscription: studio.subscription)
                    PlanComparisonGrid(studio: studio)
                }
                .padding(16)
            }
            .background(SiteClawTheme.background.ignoresSafeArea())
            .navigationTitle("Billing")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        Task {
                            await studio.openMockCustomerPortal()
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
}

private struct CurrentPlanCard: View {
    @Bindable var studio: SiteClawStudio

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
                    Task {
                        await studio.openMockCustomerPortal()
                    }
                } label: {
                    Label(
                        studio.canUseCustomerPortal ? "Manage Subscription" : "Portal Pending",
                        systemImage: "creditcard.and.123"
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

    var body: some View {
        VStack(spacing: 12) {
            SectionHeader(
                title: "Plans",
                subtitle: "Stripe Checkout will replace these mock plan actions."
            )

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 220), spacing: 12)], spacing: 12) {
                ForEach(SiteClawSubscriptionPlan.allCases, id: \.self) { plan in
                    PlanCard(
                        plan: plan,
                        isCurrent: plan == studio.subscription.plan
                    ) {
                        Task {
                            await studio.chooseBillingPlan(plan)
                        }
                    }
                }
            }
        }
    }
}

private struct PlanCard: View {
    let plan: SiteClawSubscriptionPlan
    let isCurrent: Bool
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
                    Label(isCurrent ? "Current Plan" : "Select", systemImage: isCurrent ? "checkmark" : "arrow.right")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(isCurrent ? SiteClawTheme.mint : SiteClawTheme.coral)
                .disabled(isCurrent)
            }
        }
    }

    private var editLabel: String {
        plan.editLimit < 0 ? "Unlimited edits" : "\(plan.editLimit) edits per period"
    }
}

#Preview {
    BillingView(studio: SiteClawStudio.preview)
}

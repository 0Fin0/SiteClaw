//
//  DashboardView.swift
//  SiteClaw
//

import SwiftUI

struct DashboardView: View {
    @Bindable var studio: SiteClawStudio

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    StatusPanel(studio: studio)
                    MetricsGrid(metrics: studio.metrics)
                    ContentChecklist(studio: studio)
                    RecentUpdatesList(updates: studio.updates)
                }
                .padding(16)
            }
            .background(SiteClawTheme.background.ignoresSafeArea())
            .navigationTitle("Dashboard")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        studio.publishDraft()
                    } label: {
                        Image(systemName: studio.isPublished ? "checkmark.circle.fill" : "paperplane.fill")
                    }
                    .accessibilityLabel(studio.isPublished ? "Published" : "Publish site")
                }
            }
        }
    }
}

private struct StatusPanel: View {
    @Bindable var studio: SiteClawStudio

    var body: some View {
        ClawCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(studio.restaurant.name.isEmpty ? "New Restaurant Site" : studio.restaurant.name)
                            .font(.title2.bold())
                        Text(studio.draft.url)
                            .font(.subheadline)
                            .foregroundStyle(SiteClawTheme.sky)
                    }

                    Spacer()

                    LabelPill(
                        title: studio.publishStatus,
                        systemImage: studio.isPublished ? "checkmark.circle.fill" : "clock.fill",
                        color: studio.isPublished ? SiteClawTheme.mint : SiteClawTheme.coral
                    )
                }

                Text(studio.draft.lastGeneratedSummary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Button {
                    studio.publishDraft()
                } label: {
                    Label(studio.isPublished ? "Published" : "Publish Site", systemImage: "paperplane.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
                .tint(studio.isPublished ? SiteClawTheme.mint : SiteClawTheme.coral)
            }
        }
    }
}

private struct MetricsGrid: View {
    let metrics: [DashboardMetric]

    var body: some View {
        VStack(spacing: 12) {
            SectionHeader(title: "Launch Readiness", subtitle: "The core signals an owner needs before going live.")

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(metrics) { metric in
                    ClawCard {
                        VStack(alignment: .leading, spacing: 10) {
                            Image(systemName: metric.systemImage)
                                .font(.title2)
                                .foregroundStyle(SiteClawTheme.coral)
                            Text(metric.value)
                                .font(.title.bold())
                            Text(metric.label)
                                .font(.headline)
                            Text(metric.trend)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }
                    }
                }
            }
        }
    }
}

private struct ContentChecklist: View {
    let studio: SiteClawStudio

    var checks: [(String, Bool)] {
        [
            ("Business name", !studio.restaurant.name.isEmpty),
            ("Cuisine and location", !studio.restaurant.cuisine.isEmpty && !studio.restaurant.neighborhood.isEmpty),
            ("Hours", !studio.restaurant.hours.isEmpty),
            ("Menu items", !studio.restaurant.menuItems.isEmpty),
            ("AI site draft", studio.isDraftGenerated)
        ]
    }

    var body: some View {
        VStack(spacing: 12) {
            SectionHeader(title: "MVP Checklist", subtitle: "Pulled directly from the SiteClaw concept deck.")

            ClawCard {
                VStack(spacing: 12) {
                    ForEach(checks, id: \.0) { item in
                        HStack {
                            Image(systemName: item.1 ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(item.1 ? SiteClawTheme.mint : .secondary)
                            Text(item.0)
                                .font(.subheadline.weight(.medium))
                            Spacer()
                        }
                    }
                }
            }
        }
    }
}

struct RecentUpdatesList: View {
    let updates: [SiteUpdate]

    var body: some View {
        VStack(spacing: 12) {
            SectionHeader(title: "Recent Activity", subtitle: "A running log of AI-prepared changes.")

            VStack(spacing: 10) {
                ForEach(updates.prefix(4)) { update in
                    ClawCard {
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: icon(for: update.type))
                                .font(.headline)
                                .foregroundStyle(color(for: update.type))
                                .frame(width: 30, height: 30)

                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(update.title)
                                        .font(.headline)
                                    Spacer()
                                    Text(update.timeLabel)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Text(update.detail)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
    }

    private func icon(for type: SiteUpdate.UpdateType) -> String {
        switch type {
        case .hours: "clock.fill"
        case .menu: "fork.knife"
        case .announcement: "megaphone.fill"
        case .photo: "photo.fill"
        case .publish: "paperplane.fill"
        }
    }

    private func color(for type: SiteUpdate.UpdateType) -> Color {
        switch type {
        case .hours: SiteClawTheme.sky
        case .menu: SiteClawTheme.coral
        case .announcement: SiteClawTheme.gold
        case .photo: SiteClawTheme.mint
        case .publish: SiteClawTheme.navy
        }
    }
}

#Preview {
    DashboardView(studio: SiteClawStudio.preview)
}

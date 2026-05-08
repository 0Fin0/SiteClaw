//
//  RestaurantJSONView.swift
//  SiteClaw
//

import SwiftUI

struct RestaurantJSONView: View {
    let studio: SiteClawStudio
    @State private var didCopy = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    JSONSummaryCard(studio: studio)
                    JSONPreviewCard(jsonString: studio.restaurantJSONString)
                }
                .padding(16)
            }
            .background(SiteClawTheme.background.ignoresSafeArea())
            .navigationTitle("restaurant.json")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        copyJSON()
                    } label: {
                        Image(systemName: didCopy ? "checkmark" : "doc.on.doc")
                    }
                    .accessibilityLabel("Copy restaurant JSON")
                }
            }
        }
    }

    private func copyJSON() {
        #if os(iOS)
        UIPasteboard.general.string = studio.restaurantJSONString
        #elseif os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(studio.restaurantJSONString, forType: .string)
        #endif

        didCopy = true
    }
}

private struct JSONSummaryCard: View {
    let studio: SiteClawStudio

    var body: some View {
        ClawCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Restaurant Data")
                            .font(.title2.bold())
                        Text("Captured from the owner conversation and ready for preview, storage, and publishing.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Image(systemName: "curlybraces")
                        .font(.title2)
                        .foregroundStyle(SiteClawTheme.coral)
                }

                Divider()

                HStack {
                    ContractMetric(title: "Schema", value: studio.restaurantJSON.schemaVersion)
                    ContractMetric(title: "Menu Items", value: "\(studio.restaurant.menuItems.count)")
                    ContractMetric(title: "SEO Terms", value: "\(studio.draft.seoKeywords.count)")
                }
            }
        }
    }
}

private struct ContractMetric: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.title3.bold())
                .foregroundStyle(SiteClawTheme.ink)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct JSONPreviewCard: View {
    let jsonString: String

    var body: some View {
        VStack(spacing: 12) {
            SectionHeader(
                title: "Generated JSON",
                subtitle: "A structured snapshot of the restaurant profile, menu, hours, SEO, and branding."
            )

            ScrollView(.horizontal) {
                Text(jsonString)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(SiteClawTheme.ink)
                    .textSelection(.enabled)
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(SiteClawTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(.black.opacity(0.06), lineWidth: 1)
            }
        }
    }
}

#Preview {
    RestaurantJSONView(studio: SiteClawStudio.preview)
}

//
//  RestaurantJSONView.swift
//  SiteClaw
//

import SwiftUI
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

struct RestaurantJSONView: View {
    let studio: SiteClawStudio

    var body: some View {
        NavigationStack {
            RestaurantJSONContentView(studio: studio)
        }
    }
}

struct RestaurantJSONContentView: View {
    let studio: SiteClawStudio
    @State private var didCopy = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                JSONSummaryCard(studio: studio)
                JSONPreviewCard(jsonString: studio.restaurantJSONString, didCopy: $didCopy)
            }
            .padding(16)
            .padding(.bottom, SiteClawTheme.tabBarClearance)
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

    private func copyJSON() {
        SiteClawClipboard.copy(studio.restaurantJSONString)
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
    @Binding var didCopy: Bool

    var body: some View {
        VStack(spacing: 12) {
            HStack(alignment: .bottom, spacing: 12) {
                SectionHeader(
                    title: "Generated JSON",
                    subtitle: "A structured snapshot of the restaurant profile, menu, hours, SEO, and branding."
                )

                Button {
                    copyJSON()
                } label: {
                    Label(didCopy ? "Copied" : "Copy JSON", systemImage: didCopy ? "checkmark" : "doc.on.doc")
                }
                .buttonStyle(.borderedProminent)
                .tint(didCopy ? SiteClawTheme.mint : SiteClawTheme.coral)
                .accessibilityLabel("Copy generated JSON")
            }

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

    private func copyJSON() {
        SiteClawClipboard.copy(jsonString)
        didCopy = true

        Task { @MainActor in
            try? await Task.sleep(for: .seconds(1.5))
            didCopy = false
        }
    }
}

private enum SiteClawClipboard {
    static func copy(_ value: String) {
        #if os(iOS)
        UIPasteboard.general.string = value
        #elseif os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(value, forType: .string)
        #endif
    }
}

#Preview {
    RestaurantJSONView(studio: SiteClawStudio.preview)
}

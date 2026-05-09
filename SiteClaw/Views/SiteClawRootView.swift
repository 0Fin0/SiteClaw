//
//  SiteClawRootView.swift
//  SiteClaw
//

import SwiftUI

struct SiteClawRootView: View {
    @State private var studio = SiteClawStudio.preview

    var body: some View {
        TabView {
            TalkToSiteClawView(studio: studio)
                .tabItem {
                    Label("Talk", systemImage: "waveform.circle.fill")
                }

            BuilderView(studio: studio)
                .tabItem {
                    Label("Build", systemImage: "wand.and.stars")
                }

            DashboardView(studio: studio)
                .tabItem {
                    Label("Dashboard", systemImage: "square.grid.2x2.fill")
                }

            AccountView(studio: studio)
                .tabItem {
                    Label("Account", systemImage: "person.crop.circle.fill")
                }

            BillingView(studio: studio)
                .tabItem {
                    Label("Billing", systemImage: "creditcard.fill")
                }

            SitePreviewView(studio: studio)
                .tabItem {
                    Label("Preview", systemImage: "iphone")
                }

            RestaurantJSONView(studio: studio)
                .tabItem {
                    Label("JSON", systemImage: "curlybraces")
                }

            QuickUpdatesView(studio: studio)
                .tabItem {
                    Label("Updates", systemImage: "mic.fill")
                }
        }
        .tint(SiteClawTheme.coral)
    }
}

#Preview {
    SiteClawRootView()
}

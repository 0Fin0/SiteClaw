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

            SitePreviewView(studio: studio)
                .tabItem {
                    Label("Preview", systemImage: "iphone")
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

//
//  SiteClawRootView.swift
//  SiteClaw
//

import SwiftUI

struct SiteClawRootView: View {
    @State private var studio = SiteClawStudio.preview
    @State private var selectedTab = DemoTab.talk

    var body: some View {
        TabView(selection: $selectedTab) {
            TalkToSiteClawView(
                studio: studio,
                continueToBuild: {
                    withAnimation(.snappy(duration: 0.3)) {
                        selectedTab = .build
                    }
                }
            )
                .tabItem {
                    Label("Talk", systemImage: "waveform.circle.fill")
                }
                .tag(DemoTab.talk)

            BuilderView(
                studio: studio,
                continueToPreview: {
                    withAnimation(.snappy(duration: 0.3)) {
                        selectedTab = .preview
                    }
                }
            )
                .tabItem {
                    Label("Build", systemImage: "slider.horizontal.3")
                }
                .tag(DemoTab.build)

            SitePreviewView(studio: studio)
                .tabItem {
                    Label("Preview", systemImage: "iphone")
                }
                .tag(DemoTab.preview)
        }
        .tint(.accentColor)
    }
}

private enum DemoTab: Hashable {
    case talk
    case build
    case preview
}

#Preview {
    SiteClawRootView()
}

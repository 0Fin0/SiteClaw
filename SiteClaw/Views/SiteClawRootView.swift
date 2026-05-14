//
//  SiteClawRootView.swift
//  SiteClaw
//

import SwiftUI

struct SiteClawRootView: View {
    @State private var studio = SiteClawStudio.preview
    @State private var selectedTab = DemoTab.talk
    @State private var isAuthenticated = false
    @State private var talkScrollResetToken = 0
    @State private var buildScrollResetToken = 0
    @State private var previewScrollResetToken = 0
    @State private var autosaveTask: Task<Void, Never>?

    var body: some View {
        Group {
            if isAuthenticated {
                appShell
            } else {
                MockLoginView(studio: studio) {
                    withAnimation(.snappy(duration: 0.32)) {
                        studio.accountSettings.isSignedIn = true
                        isAuthenticated = true
                    }
                }
            }
        }
        .preferredColorScheme(studio.accountSettings.appearancePreference.colorScheme)
        .onChange(of: studio.accountSettings.isSignedIn) { _, isSignedIn in
            guard !isSignedIn else { return }
            withAnimation(.snappy(duration: 0.32)) {
                selectedTab = .talk
                isAuthenticated = false
            }
        }
        .onChange(of: studio.workspaceAutosaveState) { _, _ in
            scheduleWorkspaceAutosave()
        }
        .task {
            if studio.loadSavedWorkspaceIfAvailable(),
               studio.accountSettings.isSignedIn {
                isAuthenticated = true
            }
        }
    }

    private var appShell: some View {
        TabView(selection: $selectedTab) {
            TalkToSiteClawView(
                studio: studio,
                scrollResetToken: talkScrollResetToken,
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
                },
                scrollResetToken: buildScrollResetToken
            )
                .tabItem {
                    Label("Build", systemImage: "slider.horizontal.3")
                }
                .tag(DemoTab.build)

            SitePreviewView(studio: studio, scrollResetToken: previewScrollResetToken)
                .tabItem {
                    Label("Preview", systemImage: "iphone")
                }
                .tag(DemoTab.preview)
        }
        .tint(SiteClawTheme.coral)
        .siteClawTabBarChrome()
        .onChange(of: selectedTab) { _, tab in
            switch tab {
            case .talk:
                talkScrollResetToken += 1
            case .build:
                buildScrollResetToken += 1
            case .preview:
                previewScrollResetToken += 1
            }
        }
    }

    private func scheduleWorkspaceAutosave() {
        autosaveTask?.cancel()
        autosaveTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 900_000_000)
            guard !Task.isCancelled, studio.accountSettings.isSignedIn else { return }
            _ = studio.autosaveWorkspace()
        }
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

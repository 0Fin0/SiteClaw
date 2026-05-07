//
//  QuickUpdatesView.swift
//  SiteClaw
//

import SwiftUI

struct QuickUpdatesView: View {
    @Bindable var studio: SiteClawStudio
    @State private var updateText = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    VoiceUpdatePanel(studio: studio, updateText: $updateText)
                    TemplateGrid(updateText: $updateText)
                    RecentUpdatesList(updates: studio.updates)
                }
                .padding(16)
            }
            .background(SiteClawTheme.background.ignoresSafeArea())
            .navigationTitle("Updates")
        }
    }
}

private struct VoiceUpdatePanel: View {
    @Bindable var studio: SiteClawStudio
    @Binding var updateText: String

    var body: some View {
        VStack(spacing: 12) {
            SectionHeader(
                title: "One-Tap Updates",
                subtitle: "Restaurant owners can say or type a change and publish it in seconds."
            )

            ClawCard {
                VStack(spacing: 14) {
                    HStack(spacing: 12) {
                        Image(systemName: "mic.circle.fill")
                            .font(.system(size: 42))
                            .foregroundStyle(SiteClawTheme.coral)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Voice input prototype")
                                .font(.headline)
                            Text("Whisper integration would turn speech into this update text.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()
                    }

                    TextField("Example: Add birria tacos as today's special...", text: $updateText, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(3...5)

                    Button {
                        studio.applyQuickUpdate(updateText)
                        updateText = ""
                    } label: {
                        Label("Prepare Update", systemImage: "wand.and.stars")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(SiteClawTheme.coral)
                    .disabled(updateText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

private struct TemplateGrid: View {
    @Binding var updateText: String

    var body: some View {
        VStack(spacing: 12) {
            SectionHeader(title: "Common Owner Requests", subtitle: "Fast starters for food trucks and small restaurants.")

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(QuickUpdateTemplate.samples) { template in
                    Button {
                        updateText = template.prompt
                    } label: {
                        VStack(alignment: .leading, spacing: 10) {
                            Image(systemName: template.systemImage)
                                .font(.title2)
                                .foregroundStyle(SiteClawTheme.gold)
                            Text(template.title)
                                .font(.headline)
                                .foregroundStyle(SiteClawTheme.ink)
                            Text(template.prompt)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.leading)
                                .lineLimit(3)
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, minHeight: 138, alignment: .topLeading)
                        .background(SiteClawTheme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(.black.opacity(0.06), lineWidth: 1)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

#Preview {
    QuickUpdatesView(studio: SiteClawStudio.preview)
}

//
//  BuilderView.swift
//  SiteClaw
//

import SwiftUI

struct BuilderView: View {
    @Bindable var studio: SiteClawStudio
    @State private var ownerNote = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    HeroBuilderCard(studio: studio)
                    RestaurantIntakeView(studio: studio)
                    ConversationView(studio: studio, ownerNote: $ownerNote)
                    GenerateSiteButton(studio: studio)
                }
                .padding(16)
            }
            .background(SiteClawTheme.background.ignoresSafeArea())
            .navigationTitle("Build Site")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        studio.loadVoiceExample()
                    } label: {
                        Image(systemName: "waveform")
                    }
                    .accessibilityLabel("Load voice example")
                }
            }
        }
    }
}

private struct HeroBuilderCard: View {
    let studio: SiteClawStudio

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("SiteClaw")
                        .font(.largeTitle.bold())
                        .foregroundStyle(.white)
                    Text("Voice-first website builder for local restaurants.")
                        .font(.headline)
                        .foregroundStyle(.white.opacity(0.84))
                }

                Spacer()

                Image(systemName: "fork.knife.circle.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(SiteClawTheme.gold)
            }

            HStack(spacing: 10) {
                LabelPill(title: studio.publishStatus, systemImage: "bolt.fill", color: SiteClawTheme.gold)
                LabelPill(title: "$\(studio.monthlyPrice)/mo", systemImage: "creditcard.fill", color: .white)
            }

            ProgressView(value: Double(studio.completionPercent), total: 100)
                .tint(SiteClawTheme.mint)
                .accessibilityLabel("Site completion")

            Text("\(studio.completionPercent)% complete")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.78))
        }
        .padding(18)
        .background(
            LinearGradient(
                colors: [SiteClawTheme.navy, Color(red: 0.10, green: 0.20, blue: 0.27)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct RestaurantIntakeView: View {
    @Bindable var studio: SiteClawStudio

    var body: some View {
        VStack(spacing: 12) {
            SectionHeader(
                title: "Restaurant Basics",
                subtitle: "These fields become the website copy, menu page, and local SEO."
            )

            ClawCard {
                VStack(spacing: 12) {
                    TextField("Restaurant name", text: $studio.restaurant.name)
                    TextField("Cuisine", text: $studio.restaurant.cuisine)
                    TextField("Neighborhood or city", text: $studio.restaurant.neighborhood)
                    TextField("Hours", text: $studio.restaurant.hours)
                    TextField("Short story", text: $studio.restaurant.story, axis: .vertical)
                        .lineLimit(2...4)
                }
                .textFieldStyle(.roundedBorder)
            }
        }
    }
}

private struct ConversationView: View {
    @Bindable var studio: SiteClawStudio
    @Binding var ownerNote: String

    var body: some View {
        VStack(spacing: 12) {
            SectionHeader(
                title: "AI Conversation",
                subtitle: "The owner can type or speak naturally. SiteClaw turns that into a site."
            )

            VStack(spacing: 10) {
                ForEach(studio.messages.suffix(5)) { message in
                    MessageBubble(message: message)
                }

                HStack(spacing: 10) {
                    TextField("Tell SiteClaw what to build...", text: $ownerNote, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(1...3)

                    Button {
                        studio.applyQuickUpdate(ownerNote)
                        ownerNote = ""
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title2)
                    }
                    .disabled(ownerNote.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

private struct MessageBubble: View {
    let message: BuilderMessage

    var isOwner: Bool {
        message.role == .owner
    }

    var body: some View {
        HStack {
            if isOwner { Spacer(minLength: 36) }

            Text(message.text)
                .font(.subheadline)
                .foregroundStyle(isOwner ? .white : SiteClawTheme.ink)
                .padding(12)
                .background(isOwner ? SiteClawTheme.coral : SiteClawTheme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(.black.opacity(isOwner ? 0 : 0.06), lineWidth: 1)
                }

            if !isOwner { Spacer(minLength: 36) }
        }
    }
}

private struct GenerateSiteButton: View {
    @Bindable var studio: SiteClawStudio

    var body: some View {
        Button {
            studio.generateDraft()
        } label: {
            HStack {
                Image(systemName: "sparkles")
                Text("Generate Restaurant Website")
                Spacer()
                Image(systemName: "chevron.right")
            }
            .font(.headline)
            .foregroundStyle(.white)
            .padding(16)
            .background(SiteClawTheme.coral)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
    }
}

#Preview {
    BuilderView(studio: SiteClawStudio.preview)
}

//
//  TalkToSiteClawView.swift
//  SiteClaw
//

import SwiftUI

struct TalkToSiteClawView: View {
    @Bindable var studio: SiteClawStudio
    @State private var isListening = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    RealtimeSessionCard(studio: studio, isListening: $isListening)
                    TranscriptEditor(studio: studio)
                    CapturedDetailsList(prompts: studio.voicePrompts)
                    VoiceActionPanel(studio: studio)
                }
                .padding(16)
            }
            .background(SiteClawTheme.background.ignoresSafeArea())
            .navigationTitle("Talk to SiteClaw")
        }
    }
}

private struct RealtimeSessionCard: View {
    @Bindable var studio: SiteClawStudio
    @Binding var isListening: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top, spacing: 16) {
                ZStack {
                    Circle()
                        .fill(isListening ? SiteClawTheme.coral.opacity(0.18) : SiteClawTheme.navy.opacity(0.12))
                        .frame(width: 76, height: 76)

                    Image(systemName: isListening ? "waveform" : "mic.fill")
                        .font(.system(size: 34, weight: .semibold))
                        .foregroundStyle(isListening ? SiteClawTheme.coral : SiteClawTheme.navy)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Voice Onboarding")
                        .font(.title2.bold())
                    Text(studio.realtimeStatus)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(statusColor)
                    Text("Ask for the basics, capture the owner story, then generate the first website draft.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            HStack(spacing: 12) {
                Button {
                    isListening.toggle()
                    if isListening {
                        studio.startRealtimeSession()
                    } else {
                        studio.stopRealtimeSession()
                    }
                } label: {
                    Label(isListening ? "Stop" : "Start", systemImage: isListening ? "stop.fill" : "mic.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(isListening ? SiteClawTheme.coral : SiteClawTheme.navy)

                Button {
                    isListening = false
                    studio.loadVoiceExample()
                } label: {
                    Label("Demo", systemImage: "play.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(SiteClawTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(.black.opacity(0.06), lineWidth: 1)
        }
    }

    private var statusColor: Color {
        switch studio.realtimeStatus {
        case "Listening": SiteClawTheme.coral
        case "Generated": SiteClawTheme.mint
        case "Processing": SiteClawTheme.gold
        default: SiteClawTheme.sky
        }
    }
}

private struct TranscriptEditor: View {
    @Bindable var studio: SiteClawStudio

    var body: some View {
        VStack(spacing: 12) {
            SectionHeader(
                title: "Transcript",
                subtitle: "The Realtime API will replace this text box with live speech."
            )

            ClawCard {
                TextField("Restaurant owner transcript", text: $studio.voiceTranscript, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(6...10)
            }
        }
    }
}

private struct CapturedDetailsList: View {
    let prompts: [VoiceOnboardingPrompt]

    var body: some View {
        VStack(spacing: 12) {
            SectionHeader(
                title: "Captured Details",
                subtitle: "Structured fields SiteClaw needs before generating the restaurant website."
            )

            VStack(spacing: 10) {
                ForEach(prompts) { prompt in
                    ClawCard {
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: prompt.systemImage)
                                .font(.headline)
                                .foregroundStyle(prompt.capturedAnswer.isEmpty ? .secondary : SiteClawTheme.mint)
                                .frame(width: 28, height: 28)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(prompt.question)
                                    .font(.headline)
                                Text(prompt.capturedAnswer.isEmpty ? "Waiting for answer" : prompt.capturedAnswer)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()
                        }
                    }
                }
            }
        }
    }
}

private struct VoiceActionPanel: View {
    @Bindable var studio: SiteClawStudio

    var body: some View {
        Button {
            studio.processVoiceTranscript()
        } label: {
            HStack {
                Image(systemName: "sparkles")
                Text("Generate From Voice")
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
    TalkToSiteClawView(studio: SiteClawStudio.preview)
}

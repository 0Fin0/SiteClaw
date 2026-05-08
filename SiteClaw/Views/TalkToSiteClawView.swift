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
                VStack(spacing: 16) {
                    VoiceHeroCard(studio: studio, isListening: $isListening)
                    GuidedQuestionCard(studio: studio)
                    CapturedDetailsList(prompts: studio.voicePrompts)
                    TranscriptEditor(studio: studio)
                    VoiceActionPanel(studio: studio)
                }
                .padding(16)
            }
            .background(SiteClawTheme.background.ignoresSafeArea())
            .navigationTitle("Talk to SiteClaw")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        studio.resetVoiceOnboarding()
                        isListening = false
                    } label: {
                        Image(systemName: "arrow.counterclockwise")
                    }
                    .accessibilityLabel("Reset voice onboarding")
                }
            }
        }
    }
}

private struct VoiceHeroCard: View {
    @Bindable var studio: SiteClawStudio
    @Binding var isListening: Bool
    @State private var sessionTask: Task<Void, Never>?
    @State private var realtimeAudioStreamer: RealtimeAudioStreamingService?

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top, spacing: 16) {
                VoiceOrb(isListening: isListening, audioLevel: studio.realtimeAudioLevel)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Build by Voice")
                        .font(.title.bold())
                    Text(studio.realtimeStatus)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(statusColor)
                    Text(studio.realtimeConnectionDetail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    Label(studio.realtimeSessionLabel, systemImage: "network")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(SiteClawTheme.sky)
                    Text("SiteClaw asks the owner five questions, captures the answers, then generates a restaurant website draft.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Onboarding Progress")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(Int(studio.voiceProgress * 100))%")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(SiteClawTheme.ink)
                }

                ProgressView(value: studio.voiceProgress)
                    .tint(SiteClawTheme.mint)
            }

            HStack(spacing: 10) {
                Button {
                    toggleRealtimeSession()
                } label: {
                    Label(isListening ? "Stop" : "Start", systemImage: isListening ? "stop.fill" : "mic.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(isListening ? SiteClawTheme.coral : SiteClawTheme.navy)

                Button {
                    stopRealtimeStreaming()
                    studio.loadVoiceExample()
                } label: {
                    Label("Demo", systemImage: "play.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
        }
        .onDisappear {
            stopRealtimeStreaming()
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

    private func toggleRealtimeSession() {
        if isListening {
            stopRealtimeStreaming()
            return
        }

        isListening = true
        studio.startRealtimeSession()

        let restaurantName = studio.restaurant.name
        sessionTask = Task {
            do {
                let response = try await RealtimeSessionService().createSession(restaurantName: restaurantName)
                guard !Task.isCancelled else { return }

                let streamer = await MainActor.run {
                    studio.beginRealtimeAudioStream(response)
                    let streamer = RealtimeAudioStreamingService()
                    realtimeAudioStreamer = streamer
                    return streamer
                }

                try await streamer.start(session: response, restaurantName: restaurantName) { event in
                    Task { @MainActor in
                        studio.handleRealtimeStreamEvent(event)
                    }
                }

                guard !Task.isCancelled else { return }

                await MainActor.run {
                    isListening = false
                    realtimeAudioStreamer = nil
                    studio.stopRealtimeSession()
                }
            } catch {
                guard !Task.isCancelled else { return }

                await MainActor.run {
                    isListening = false
                    realtimeAudioStreamer?.stop()
                    realtimeAudioStreamer = nil
                    studio.failRealtimeSession(error)
                }
            }
        }
    }

    private func stopRealtimeStreaming() {
        guard isListening || sessionTask != nil || realtimeAudioStreamer != nil else { return }
        sessionTask?.cancel()
        sessionTask = nil
        realtimeAudioStreamer?.stop()
        realtimeAudioStreamer = nil
        isListening = false
        studio.stopRealtimeSession()
    }

    private var statusColor: Color {
        switch studio.realtimeStatus {
        case "Connecting", "Processing", "Transcribing", "SiteClaw Replying": SiteClawTheme.gold
        case "Token Ready", "Generated": SiteClawTheme.mint
        case "Streaming", "Listening": SiteClawTheme.coral
        case "Captured": SiteClawTheme.sky
        case "Backend Needed", "Realtime Error": SiteClawTheme.coral
        default: SiteClawTheme.sky
        }
    }
}

private struct VoiceOrb: View {
    let isListening: Bool
    let audioLevel: Double

    var body: some View {
        ZStack {
            Circle()
                .fill(isListening ? SiteClawTheme.coral.opacity(0.18) : SiteClawTheme.navy.opacity(0.12))
                .frame(width: 82, height: 82)

            Circle()
                .stroke(isListening ? SiteClawTheme.coral.opacity(0.45) : SiteClawTheme.navy.opacity(0.18), lineWidth: 8)
                .frame(width: ringSize, height: ringSize)

            Image(systemName: isListening ? "waveform" : "mic.fill")
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(isListening ? SiteClawTheme.coral : SiteClawTheme.navy)
        }
        .frame(width: 86, height: 86)
        .animation(.easeInOut(duration: 0.25), value: isListening)
        .animation(.easeOut(duration: 0.12), value: audioLevel)
    }

    private var ringSize: CGFloat {
        guard isListening else { return 58 }
        return 66 + CGFloat(min(max(audioLevel, 0), 1)) * 16
    }
}

private struct GuidedQuestionCard: View {
    @Bindable var studio: SiteClawStudio

    var body: some View {
        ClawCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Label(studio.activeVoiceStepLabel, systemImage: studio.activeVoicePrompt.systemImage)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(SiteClawTheme.coral)
                    Spacer()
                    if !studio.activeVoicePrompt.capturedAnswer.isEmpty {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(SiteClawTheme.mint)
                    }
                }

                Text(studio.activeVoicePrompt.question)
                    .font(.title3.bold())
                    .foregroundStyle(SiteClawTheme.ink)

                Text(studio.activeVoicePrompt.helperText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                if !studio.activeVoicePrompt.capturedAnswer.isEmpty {
                    Text(studio.activeVoicePrompt.capturedAnswer)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(SiteClawTheme.ink)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(SiteClawTheme.mint.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }

                HStack(spacing: 10) {
                    Button {
                        studio.previousVoicePrompt()
                    } label: {
                        Label("Back", systemImage: "chevron.left")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .disabled(studio.activeVoicePromptIndex == 0)

                    Button {
                        studio.captureCurrentVoicePrompt()
                    } label: {
                        Label("Capture", systemImage: "checkmark")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(SiteClawTheme.coral)
                }
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
                                Text(shortTitle(for: prompt.question))
                                    .font(.headline)
                                Text(prompt.capturedAnswer.isEmpty ? "Waiting for answer" : prompt.capturedAnswer)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }

                            Spacer()
                        }
                    }
                }
            }
        }
    }

    private func shortTitle(for question: String) -> String {
        if question.contains("called") { return "Restaurant Name" }
        if question.contains("food") { return "Cuisine and City" }
        if question.contains("hours") { return "Hours" }
        if question.contains("menu") { return "Menu Highlights" }
        return "Owner Story"
    }
}

private struct TranscriptEditor: View {
    @Bindable var studio: SiteClawStudio

    var body: some View {
        VStack(spacing: 12) {
            SectionHeader(
                title: "Transcript",
                subtitle: "Live speech text from OpenAI Realtime appears here as turns are committed."
            )

            ClawCard {
                TextField("Restaurant owner transcript", text: $studio.voiceTranscript, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(5...8)
            }
        }
    }
}

private struct VoiceActionPanel: View {
    @Bindable var studio: SiteClawStudio
    @State private var isGeneratingDraft = false
    @State private var generationTask: Task<Void, Never>?
    @State private var generationMessage: String?

    var body: some View {
        VStack(spacing: 10) {
            Button {
                generateWebsiteDraft()
            } label: {
                HStack {
                    Image(systemName: isGeneratingDraft ? "hourglass" : "sparkles")
                    Text(isGeneratingDraft ? "Generating Draft" : "Generate Website Draft")
                    Spacer()
                    Image(systemName: "chevron.right")
                }
                .font(.headline)
                .foregroundStyle(.white)
                .padding(16)
                .background(SiteClawTheme.coral)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            .disabled(isGeneratingDraft)

            Text(generationMessage ?? "Uses the local backend to generate site copy from the transcript, then falls back to the demo generator if needed.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .onDisappear {
            generationTask?.cancel()
        }
    }

    private func generateWebsiteDraft() {
        generationTask?.cancel()
        isGeneratingDraft = true
        generationMessage = "Requesting AI website copy from the local backend."

        let request = SiteGenerationRequest(studio: studio)
        generationTask = Task {
            do {
                let response = try await SiteGenerationService().generateDraft(request: request)
                guard !Task.isCancelled else { return }

                await MainActor.run {
                    studio.applyGeneratedDraft(response)
                    generationMessage = "AI draft generated with \(response.model)."
                    isGeneratingDraft = false
                }
            } catch {
                guard !Task.isCancelled else { return }

                await MainActor.run {
                    studio.useLocalDraftFallback(after: error)
                    generationMessage = "Backend generation was unavailable, so SiteClaw used the local demo draft."
                    isGeneratingDraft = false
                }
            }
        }
    }
}

#Preview {
    TalkToSiteClawView(studio: SiteClawStudio.preview)
}

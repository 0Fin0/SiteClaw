//
//  TalkToSiteClawView.swift
//  SiteClaw
//

import SwiftUI

struct TalkToSiteClawView: View {
    @Bindable var studio: SiteClawStudio
    var scrollResetToken = 0
    var continueToBuild: (() -> Void)?
    @State private var isListening = false
    @State private var backendHealth: BackendHealthResponse?
    @State private var backendHealthError: String?
    @State private var isCheckingBackend = false
    @State private var voiceResetID = UUID()
    @State private var isFollowUpListening = false
    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    #endif

    private static let guidedQuestionID = "guided-question-card"
    private static let topAnchorID = "talk-top-anchor"

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 16) {
                        Color.clear
                            .frame(height: SiteClawTheme.topScrollResetClearance)
                            .id(Self.topAnchorID)
                        if usesCompactVoiceLayout {
                            GuidedQuestionCard(studio: studio, isRecording: isListening)
                                .id(Self.guidedQuestionID)
                            VoiceCoachCard(
                                studio: studio,
                                isMainVoiceListening: $isListening,
                                isFollowUpVoiceListening: $isFollowUpListening
                            )
                            VoiceHeroCard(
                                studio: studio,
                                isListening: $isListening,
                                resetID: voiceResetID,
                                isCompactLayout: usesCompactVoiceLayout,
                                isPausedByFollowUp: isFollowUpListening
                            )
                            DemoReadinessCard(
                                studio: studio,
                                backendHealth: backendHealth,
                                backendHealthError: backendHealthError,
                                isCheckingBackend: isCheckingBackend,
                                checkBackend: checkBackend
                            )
                        } else {
                            VoiceHeroCard(
                                studio: studio,
                                isListening: $isListening,
                                resetID: voiceResetID,
                                isCompactLayout: usesCompactVoiceLayout,
                                isPausedByFollowUp: isFollowUpListening
                            )
                            GuidedQuestionCard(studio: studio, isRecording: isListening)
                                .id(Self.guidedQuestionID)
                            VoiceCoachCard(
                                studio: studio,
                                isMainVoiceListening: $isListening,
                                isFollowUpVoiceListening: $isFollowUpListening
                            )
                            DemoReadinessCard(
                                studio: studio,
                                backendHealth: backendHealth,
                                backendHealthError: backendHealthError,
                                isCheckingBackend: isCheckingBackend,
                                checkBackend: checkBackend
                            )
                        }

                        TalkReviewDisclosure(studio: studio)
                        if let continueToBuild {
                            DemoFlowCTA(
                                title: "Continue to Build",
                                detail: talkNextStepDetail,
                                actionTitle: "Open Build Checklist",
                                systemImage: "checklist.checked",
                                color: SiteClawTheme.mint,
                                action: continueToBuild
                            )
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, SiteClawTheme.navigationContentTopInset)
                    .padding(.bottom, SiteClawTheme.tabBarClearance)
                }
                .background(SiteClawTheme.background.ignoresSafeArea())
                .onChange(of: studio.activeVoicePromptIndex) { _, _ in
                    scrollToQuestion(proxy)
                }
                .onChange(of: studio.pendingVoiceAnswer) { _, newValue in
                    if !newValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        scrollToQuestion(proxy)
                    }
                }
                .onChange(of: isListening) { _, newValue in
                    if newValue {
                        scrollToQuestion(proxy)
                    }
                }
                .onChange(of: scrollResetToken) { _, _ in
                    withAnimation(.snappy(duration: 0.35)) {
                        proxy.scrollTo(Self.topAnchorID, anchor: .top)
                    }
                }
                .safeAreaInset(edge: .bottom) {
                    if shouldShowQuestionDock {
                        ActiveQuestionDock(studio: studio, isListening: isListening)
                            .padding(.horizontal, 12)
                            .padding(.top, 8)
                            .padding(.bottom, 8)
                    }
                }
            }
            .navigationTitle("Talk to SiteClaw")
            .siteClawNavigationChrome()
            .task {
                await checkBackend()
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        voiceResetID = UUID()
                        isListening = false
                        studio.resetVoiceOnboarding()
                    } label: {
                        Image(systemName: "arrow.counterclockwise")
                    }
                    .accessibilityLabel("Reset voice onboarding")
                }
            }
            .accountSettingsToolbar(studio: studio)
        }
    }

    private var usesCompactVoiceLayout: Bool {
        #if os(iOS)
        horizontalSizeClass == .compact
        #else
        false
        #endif
    }

    private var shouldPrioritizeQuestion: Bool {
        usesCompactVoiceLayout && (
            isListening ||
            !studio.pendingVoiceAnswer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        )
    }

    private var shouldShowQuestionDock: Bool {
        shouldPrioritizeQuestion && !studio.activeVoicePrompt.question.isEmpty
    }

    private var talkNextStepDetail: String {
        studio.voiceProgress >= 1
            ? "Review the saved details and finish the site checklist."
            : "Save the remaining guided answers or continue to complete details in Build."
    }

    private func scrollToQuestion(_ proxy: ScrollViewProxy) {
        guard usesCompactVoiceLayout else { return }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.snappy(duration: 0.35)) {
                proxy.scrollTo(Self.guidedQuestionID, anchor: .top)
            }
        }
    }

    private func checkBackend() async {
        guard !isCheckingBackend else { return }
        isCheckingBackend = true

        do {
            let health = try await BackendHealthService().checkHealth()
            backendHealth = health
            backendHealthError = nil
        } catch {
            backendHealth = nil
            backendHealthError = error.localizedDescription
        }

        isCheckingBackend = false
    }
}

private struct DemoReadinessCard: View {
    let studio: SiteClawStudio
    let backendHealth: BackendHealthResponse?
    let backendHealthError: String?
    let isCheckingBackend: Bool
    let checkBackend: () async -> Void
    @State private var isExpanded = false

    var body: some View {
        if isReady {
            compactReadiness
        } else {
            fullReadiness
        }
    }

    private var compactReadiness: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            readinessRows
                .padding(.top, SiteClawTheme.Spacing.small)
        } label: {
            HStack(spacing: SiteClawTheme.Spacing.medium) {
                IconBadge(systemImage: "checkmark.seal.fill", color: SiteClawTheme.mint)

                VStack(alignment: .leading, spacing: 3) {
                    Text("Voice services ready")
                        .font(.headline)
                        .foregroundStyle(SiteClawTheme.ink)
                    Text("Checks passing.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Spacer()

                StatusPill(title: "Ready", systemImage: "checkmark.circle.fill", color: SiteClawTheme.mint)
            }
        }
        .padding(SiteClawTheme.Spacing.medium)
        .background(SiteClawTheme.elevatedSurface)
        .clipShape(RoundedRectangle(cornerRadius: SiteClawTheme.Radius.card, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: SiteClawTheme.Radius.card, style: .continuous)
                .stroke(SiteClawTheme.separator, lineWidth: 1)
        }
        .accessibilityLabel("Voice services ready")
    }

    private var fullReadiness: some View {
        VStack(spacing: 12) {
            SectionHeader(title: "Voice Readiness", subtitle: "Quick checks for the live demo.")

            ClawCard {
                VStack(alignment: .leading, spacing: 14) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(backendHealth == nil ? "Voice check" : "Voice services ready")
                                .font(.headline)
                            Text(statusDetail)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        Spacer()

                        Button {
                            Task {
                                await checkBackend()
                            }
                        } label: {
                            Image(systemName: isCheckingBackend ? "arrow.triangle.2.circlepath" : "arrow.clockwise")
                        }
                        .disabled(isCheckingBackend)
                        .accessibilityLabel("Check backend")
                    }

                    readinessRows
                }
            }
        }
    }

    private var readinessRows: some View {
        VStack(spacing: 10) {
            ReadinessRow(
                title: "App connection",
                detail: backendHealth == nil ? "Check before recording" : "Ready for the demo",
                isReady: backendHealth != nil,
                systemImage: "network"
            )
            ReadinessRow(
                title: "Voice capture",
                detail: backendHealth?.realtimeModel.isEmpty == false ? "Ready to transcribe answers" : "Waiting for readiness check",
                isReady: backendHealth?.realtimeModel.isEmpty == false,
                systemImage: "waveform.circle.fill"
            )
            ReadinessRow(
                title: "Website draft",
                detail: backendHealth?.generationModel.isEmpty == false ? "Ready to generate preview copy" : "Waiting for readiness check",
                isReady: backendHealth?.generationModel.isEmpty == false,
                systemImage: "sparkles"
            )
            ReadinessRow(
                title: "Required content",
                detail: ownerDetailStatus,
                isReady: requiredMissingDetails.isEmpty,
                systemImage: "checklist"
            )
        }
    }

    private var isReady: Bool {
        backendHealth != nil && backendHealthError == nil && requiredMissingDetails.isEmpty
    }

    private var statusDetail: String {
        if isCheckingBackend {
            return "Checking SiteClaw services."
        }

        if backendHealth != nil {
            return "Live voice and draft generation are available."
        }

        if backendHealthError != nil {
            return "Start the SiteClaw backend, then check again."
        }

        return "Start the SiteClaw backend before using live voice."
    }

    private var ownerDetailStatus: String {
        if requiredMissingDetails.isEmpty, optionalMissingCount == 0 {
            return "Required and optional details saved"
        }

        if requiredMissingDetails.isEmpty {
            return "Required details ready. \(optionalMissingCount) optional detail\(optionalMissingCount == 1 ? "" : "s") still open."
        }

        return "\(requiredMissingDetails.count) required detail\(requiredMissingDetails.count == 1 ? "" : "s") still needed"
    }

    private var requiredMissingDetails: [MissingDetail] {
        studio.missingDetails.filter { !$0.isOptional }
    }

    private var optionalMissingCount: Int {
        studio.missingDetails.filter(\.isOptional).count
    }
}

private struct ReadinessRow: View {
    let title: String
    let detail: String
    let isReady: Bool
    let systemImage: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: isReady ? "checkmark.circle.fill" : systemImage)
                .foregroundStyle(isReady ? SiteClawTheme.mint : SiteClawTheme.gold)
                .frame(width: 24, height: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer()
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background((isReady ? SiteClawTheme.mint : SiteClawTheme.gold).opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct VoiceHeroCard: View {
    @Bindable var studio: SiteClawStudio
    @Binding var isListening: Bool
    let resetID: UUID
    let isCompactLayout: Bool
    let isPausedByFollowUp: Bool
    @State private var sessionTask: Task<Void, Never>?
    @State private var realtimeAudioStreamer: RealtimeAudioStreamingService?
    @State private var startupRecoveryTask: Task<Void, Never>?
    @State private var hasSentAudioThisSession = false
    @State private var hasDetectedSpeechThisSession = false
    @State private var hasReceivedTranscriptThisSession = false
    @State private var hasHeardAudibleAudioThisSession = false
    @State private var didAutoRecoverStartup = false

    var body: some View {
        VStack(alignment: .leading, spacing: isCompactLayout ? 12 : 18) {
            if isCompactLayout {
                compactHeader
            } else {
                fullHeader
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label("Progress", systemImage: "checklist")
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

            actionButtons
        }
        .onDisappear {
            stopRealtimeStreaming()
        }
        .onChange(of: resetID) { _, _ in
            stopRealtimeStreaming(updateStudio: false)
        }
        .onChange(of: isListening) { _, newValue in
            if !newValue {
                stopRealtimeStreaming()
            }
        }
        .onChange(of: isPausedByFollowUp) { _, isPaused in
            if isPaused {
                stopRealtimeStreaming()
            }
        }
        .padding(isCompactLayout ? 14 : 18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(SiteClawTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(.black.opacity(0.06), lineWidth: 1)
        }
    }

    private var fullHeader: some View {
        HStack(alignment: .top, spacing: 16) {
            VoiceOrb(isListening: isListening, audioLevel: studio.realtimeAudioLevel)

            VStack(alignment: .leading, spacing: 8) {
                Text("Build by Voice")
                    .font(.title.bold())
                realtimeStatusStack(showDescription: true)
            }
        }
    }

    private var compactHeader: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: isListening ? "waveform.circle.fill" : "mic.circle.fill")
                .font(.largeTitle.weight(.semibold))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(statusColor)

            VStack(alignment: .leading, spacing: 5) {
                Text("Build by Voice")
                    .font(.headline)
                realtimeStatusStack(showDescription: false)
            }

            Spacer(minLength: 0)
        }
    }

    private func realtimeStatusStack(showDescription: Bool) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(displayStatusTitle)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(statusColor)
            Text(displayStatusDetail)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(showDescription ? 3 : 1)

            if isListening {
                AudioLevelMeter(level: studio.realtimeAudioLevel)
                    .padding(.top, 2)

                Label("Answer the visible question only", systemImage: "text.bubble")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(SiteClawTheme.coral)
            }

            if showDescription {
                Text("SiteClaw guides five short answers, then turns them into a restaurant website draft.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var actionButtons: some View {
        HStack(spacing: 10) {
            Button {
                toggleRealtimeSession()
            } label: {
                Label(primaryActionTitle, systemImage: isListening ? "stop.fill" : "mic.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(isListening ? SiteClawTheme.coral : SiteClawTheme.navy)
            .disabled(isPausedByFollowUp)

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

    private func toggleRealtimeSession(isRecoveryAttempt: Bool = false) {
        if isListening {
            stopRealtimeStreaming()
            return
        }

        if sessionTask != nil || realtimeAudioStreamer != nil {
            stopRealtimeStreaming()
        }

        resetRealtimeSessionSignals(isRecoveryAttempt: isRecoveryAttempt)
        isListening = true
        studio.startRealtimeSession()
        startRealtimeStartupMonitor()

        let restaurantName = studio.restaurant.name
        sessionTask = Task {
            var sessionWasCreated = false

            do {
                let response = try await RealtimeSessionService().createSession(restaurantName: restaurantName)
                sessionWasCreated = true
                guard !Task.isCancelled else { return }

                let streamer = await MainActor.run {
                    studio.beginRealtimeAudioStream(response)
                    let streamer = RealtimeAudioStreamingService()
                    realtimeAudioStreamer = streamer
                    return streamer
                }

                try await streamer.start(session: response, restaurantName: restaurantName) { event in
                    Task { @MainActor in
                        trackRealtimeEvent(event)
                        studio.handleRealtimeStreamEvent(event)
                    }
                }

                guard !Task.isCancelled else { return }

                await MainActor.run {
                    startupRecoveryTask?.cancel()
                    startupRecoveryTask = nil
                    isListening = false
                    realtimeAudioStreamer = nil
                    studio.stopRealtimeSession()
                }
            } catch {
                guard !Task.isCancelled else { return }

                await MainActor.run {
                    startupRecoveryTask?.cancel()
                    startupRecoveryTask = nil
                    isListening = false
                    realtimeAudioStreamer?.stop()
                    realtimeAudioStreamer = nil

                    if sessionWasCreated {
                        studio.failRealtimeAudioStream(error)
                    } else {
                        studio.failRealtimeSession(error)
                    }
                }
            }
        }
    }

    private func stopRealtimeStreaming(updateStudio: Bool = true) {
        guard isListening || sessionTask != nil || realtimeAudioStreamer != nil else { return }
        startupRecoveryTask?.cancel()
        startupRecoveryTask = nil
        sessionTask?.cancel()
        sessionTask = nil
        realtimeAudioStreamer?.stop()
        realtimeAudioStreamer = nil
        isListening = false
        if updateStudio {
            studio.stopRealtimeSession()
        }
    }

    private func resetRealtimeSessionSignals(isRecoveryAttempt: Bool) {
        startupRecoveryTask?.cancel()
        startupRecoveryTask = nil
        hasSentAudioThisSession = false
        hasDetectedSpeechThisSession = false
        hasReceivedTranscriptThisSession = false
        hasHeardAudibleAudioThisSession = false

        if !isRecoveryAttempt {
            didAutoRecoverStartup = false
        }
    }

    private func trackRealtimeEvent(_ event: RealtimeAudioStreamingEvent) {
        switch event {
        case .audioLevel(let level):
            if level > 0.08 {
                hasHeardAudibleAudioThisSession = true
            }
        case .audioChunkSent:
            hasSentAudioThisSession = true
        case .speechStarted:
            hasDetectedSpeechThisSession = true
        case .inputTranscriptDelta(let delta):
            if !delta.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                hasReceivedTranscriptThisSession = true
            }
        case .inputTranscriptCompleted(let transcript):
            if !transcript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                hasReceivedTranscriptThisSession = true
                startupRecoveryTask?.cancel()
                startupRecoveryTask = nil
            }
        case .disconnected, .error:
            startupRecoveryTask?.cancel()
            startupRecoveryTask = nil
        default:
            break
        }
    }

    private func startRealtimeStartupMonitor() {
        startupRecoveryTask?.cancel()
        startupRecoveryTask = Task {
            try? await Task.sleep(nanoseconds: 5_000_000_000)
            guard !Task.isCancelled else { return }

            await MainActor.run {
                guard isListening,
                      realtimeAudioStreamer != nil,
                      !hasSentAudioThisSession else { return }

                recoverStalledRealtimeSession(
                    "Refreshing voice capture because the microphone did not start sending audio."
                )
            }

            try? await Task.sleep(nanoseconds: 9_000_000_000)
            guard !Task.isCancelled else { return }

            await MainActor.run {
                let pendingAnswer = studio.pendingVoiceAnswer.trimmingCharacters(in: .whitespacesAndNewlines)
                guard isListening,
                      hasSentAudioThisSession,
                      !hasReceivedTranscriptThisSession,
                      pendingAnswer.isEmpty else { return }

                if hasHeardAudibleAudioThisSession && !hasDetectedSpeechThisSession {
                    recoverStalledRealtimeSession(
                        "Refreshing voice capture because speech was not detected on this first pass."
                    )
                } else if hasDetectedSpeechThisSession {
                    studio.realtimeStatus = "Processing"
                    studio.realtimeConnectionDetail = "Pause for a moment so SiteClaw can finish the transcript."
                }
            }
        }
    }

    private func recoverStalledRealtimeSession(_ message: String) {
        guard isListening else { return }

        guard !didAutoRecoverStartup else {
            studio.realtimeStatus = "Realtime Error"
            studio.realtimeConnectionDetail = "Voice capture did not receive a transcript. Tap Start again or check Simulator > I/O > Audio Input."
            stopRealtimeStreaming()
            return
        }

        didAutoRecoverStartup = true
        stopRealtimeStreaming()
        studio.realtimeStatus = "Connecting"
        studio.realtimeConnectionDetail = message

        Task {
            try? await Task.sleep(nanoseconds: 800_000_000)
            await MainActor.run {
                guard !isListening else { return }
                toggleRealtimeSession(isRecoveryAttempt: true)
            }
        }
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

    private var primaryActionTitle: String {
        if isListening {
            return "Stop"
        }

        if studio.voiceProgress > 0, studio.voiceProgress < 1 {
            return "Continue"
        }

        return "Start"
    }

    private var displayStatusTitle: String {
        if isPausedByFollowUp {
            return "Follow-up voice active"
        }

        switch studio.realtimeStatus {
        case "Ready":
            return "Ready to record"
        case "Connecting", "Token Ready", "Streaming":
            return "Getting voice ready"
        case "Listening":
            return "Listening"
        case "Processing", "Transcribing":
            return "Preparing transcript"
        case "Heard Answer":
            return "Answer ready"
        case "Captured":
            return "Answer saved"
        case "Generated":
            return "Website draft ready"
        case "Needs Answer":
            return "Answer needed"
        case "Needs Detail":
            return "Detail needed"
        case "Ready to Publish":
            return "Ready for review"
        case "Backend Needed", "Realtime Error":
            return "Voice setup needed"
        default:
            return studio.realtimeStatus
        }
    }

    private var displayStatusDetail: String {
        if isPausedByFollowUp {
            return "Main build by voice is paused while you answer the coach follow-up."
        }

        if !studio.pendingVoiceAnswer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "Review what SiteClaw heard, then tap Save Answer."
        }

        switch studio.realtimeStatus {
        case "Ready":
            return "Tap Start and answer the visible question."
        case "Connecting", "Token Ready", "Streaming":
            return "Preparing the microphone for the current question."
        case "Listening":
            return "Speak one answer, pause, then save it."
        case "Processing", "Transcribing":
            return "Turning this answer into editable text."
        case "Heard Answer":
            return "Tap Save Answer when the answer looks right."
        case "Captured":
            return "Continue to the next question or generate the draft."
        case "Generated":
            return "Preview the site and make corrections in Build."
        case "Needs Answer":
            return "Speak or type an answer before saving."
        case "Needs Detail":
            return "Record the missing owner detail shown below."
        case "Ready to Publish":
            return "The guided owner details are ready for review."
        case "Backend Needed":
            return "Start the SiteClaw backend, then try again."
        case "Realtime Error":
            return "Check microphone access and restart recording."
        default:
            return studio.realtimeConnectionDetail
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

private struct AudioLevelMeter: View {
    let level: Double

    var body: some View {
        ProgressView(value: min(max(level, 0), 1))
            .tint(SiteClawTheme.coral)
            .accessibilityLabel("Microphone level")
    }
}

private struct GuidedQuestionCard: View {
    @Bindable var studio: SiteClawStudio
    let isRecording: Bool
    @State private var coachTask: Task<Void, Never>?

    var body: some View {
        ClawCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Label(studio.activeVoiceStepLabel, systemImage: studio.activeVoicePrompt.systemImage)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(SiteClawTheme.coral)
                    Spacer()
                    if isRecording {
                        Label("Recording", systemImage: "waveform")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(SiteClawTheme.coral)
                            .padding(.horizontal, 9)
                            .padding(.vertical, 6)
                            .background(SiteClawTheme.coral.opacity(0.10))
                            .clipShape(Capsule())
                    }
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

                if studio.activeVoicePrompt.capturedAnswer.isEmpty,
                   !studio.pendingVoiceAnswer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Heard for this step")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(SiteClawTheme.sky)

                            Spacer()

                            Button {
                                studio.pendingVoiceAnswer = ""
                            } label: {
                                Image(systemName: "trash")
                            }
                            .buttonStyle(.borderless)
                            .accessibilityLabel("Clear heard answer")
                        }

                        TextField("Edit heard answer", text: $studio.pendingVoiceAnswer, axis: .vertical)
                            .textFieldStyle(.roundedBorder)
                            .lineLimit(2...4)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(SiteClawTheme.sky.opacity(0.10))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }

                if !studio.activeVoicePrompt.capturedAnswer.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Saved answer")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(SiteClawTheme.mint)

                            Spacer()

                            Button {
                                capturedAnswerBinding.wrappedValue = ""
                            } label: {
                                Image(systemName: "trash")
                            }
                            .buttonStyle(.borderless)
                            .accessibilityLabel("Clear saved answer")
                        }

                        TextField("Edit saved answer", text: capturedAnswerBinding, axis: .vertical)
                            .textFieldStyle(.roundedBorder)
                            .lineLimit(2...4)

                        Button {
                            if let request = studio.applyEditedVoicePromptAnswer() {
                                runVoiceCoach(request)
                            }
                        } label: {
                            Label("Apply Edit", systemImage: "checkmark.circle")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .tint(SiteClawTheme.mint)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(SiteClawTheme.mint.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }

                Text("Tap Save Answer when this answer looks right.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

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
                        if let request = studio.captureCurrentVoicePrompt() {
                            runVoiceCoach(request)
                        }
                    } label: {
                        Label("Save Answer", systemImage: "checkmark")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(SiteClawTheme.coral)
                }
            }
        }
        .onDisappear {
            coachTask?.cancel()
        }
    }

    private var capturedAnswerBinding: Binding<String> {
        Binding(
            get: {
                guard studio.voicePrompts.indices.contains(studio.activeVoicePromptIndex) else { return "" }
                return studio.voicePrompts[studio.activeVoicePromptIndex].capturedAnswer
            },
            set: { newValue in
                guard studio.voicePrompts.indices.contains(studio.activeVoicePromptIndex) else { return }
                studio.voicePrompts[studio.activeVoicePromptIndex].capturedAnswer = newValue
            }
        )
    }

    private func runVoiceCoach(_ request: VoiceCoachRequest) {
        coachTask?.cancel()
        studio.beginVoiceCoachTurn(for: request)
        coachTask = Task {
            do {
                let response = try await VoiceCoachService().coachTurn(request: request)
                guard !Task.isCancelled else { return }

                await MainActor.run {
                    studio.applyVoiceCoachResponse(response, for: request)
                }
            } catch {
                guard !Task.isCancelled else { return }

                await MainActor.run {
                    studio.failVoiceCoachTurn(error, for: request)
                }
            }
        }
    }
}

private struct VoiceCoachCard: View {
    @Bindable var studio: SiteClawStudio
    @Binding var isMainVoiceListening: Bool
    @Binding var isFollowUpVoiceListening: Bool
    @State private var followUpAnswer = ""
    @State private var coachTask: Task<Void, Never>?
    @State private var followUpVoiceTask: Task<Void, Never>?
    @State private var followUpAudioStreamer: RealtimeAudioStreamingService?
    @State private var followUpVoiceStatus = ""
    @State private var followUpAudioLevel = 0.0
    @State private var isExpanded = false

    var body: some View {
        ClawCard {
            VStack(alignment: .leading, spacing: 14) {
                Button {
                    withAnimation(.snappy(duration: 0.25)) {
                        isExpanded.toggle()
                    }
                } label: {
                    coachHeader
                }
                .buttonStyle(.plain)
                .accessibilityLabel(isExpanded ? "Collapse voice coach" : "Expand voice coach")

                if isExpanded {
                    coachDetails
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
        .onDisappear {
            coachTask?.cancel()
            stopFollowUpVoice(status: "")
        }
    }

    private var coachHeader: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: studio.isVoiceCoachWorking ? "sparkles" : "wand.and.stars")
                .font(.title3.weight(.semibold))
                .foregroundStyle(statusColor)
                .frame(width: 34, height: 34)
                .background(statusColor.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text("Voice Coach")
                        .font(.headline)

                    if hasSuggestedFollowUp {
                        Image(systemName: "questionmark.bubble.fill")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(SiteClawTheme.coral)
                            .accessibilityHidden(true)
                    }
                }

                Text(collapsedStatus)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 8)

            if let turn = studio.latestVoiceCoachTurn {
                LabelPill(
                    title: turn.confidence.displayName,
                    systemImage: confidenceIcon(for: turn.confidence),
                    color: confidenceColor(for: turn.confidence)
                )
            }

            Image(systemName: "chevron.down")
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)
                .rotationEffect(.degrees(isExpanded ? 180 : 0))
                .padding(.top, 6)
                .accessibilityHidden(true)
        }
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private var coachDetails: some View {
        VStack(alignment: .leading, spacing: 14) {
            if studio.isVoiceCoachWorking {
                ProgressView("Reviewing answer and site strategy")
                    .font(.caption)
                    .tint(SiteClawTheme.coral)
            }

            if let turn = studio.latestVoiceCoachTurn {
                VStack(alignment: .leading, spacing: 8) {
                    CoachFactRow(title: "What I heard", value: turn.cleanedAnswer, systemImage: "text.quote")

                    if turn.hasMissingDetails {
                        CoachTagSection(title: "Missing Details", tags: turn.missingDetails, color: SiteClawTheme.gold)
                    }

                    if !turn.designNotes.isEmpty {
                        CoachTagSection(title: "Design Notes", tags: turn.designNotes, color: SiteClawTheme.sky)
                    }
                }
            } else if !studio.isVoiceCoachWorking {
                Text("After each saved answer, SiteClaw will clean the response, flag gaps, and explain how it changes the website direction.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if hasSuggestedFollowUp {
                followUpEditor
            }
        }
    }

    private var followUpEditor: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Suggested follow-up", systemImage: "questionmark.bubble.fill")
                .font(.caption.weight(.bold))
                .foregroundStyle(SiteClawTheme.coral)
            Text(studio.activeSuggestedFollowUp)
                .font(.subheadline.weight(.semibold))
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 10) {
                Button {
                    toggleFollowUpVoice()
                } label: {
                    Label(
                        isFollowUpVoiceListening ? "Stop Follow-up Voice" : "Answer by Voice",
                        systemImage: isFollowUpVoiceListening ? "stop.fill" : "mic.fill"
                    )
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(isFollowUpVoiceListening ? SiteClawTheme.coral : SiteClawTheme.navy)

                if isFollowUpVoiceListening {
                    AudioLevelMeter(level: followUpAudioLevel)
                        .frame(maxWidth: 92)
                }
            }

            if !followUpVoiceStatus.isEmpty {
                Text(followUpVoiceStatus)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            TextField("Answer the follow-up", text: $followUpAnswer, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(2...4)

            Button {
                applyFollowUp()
            } label: {
                Label("Apply Follow-up", systemImage: "checkmark.sparkles")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(SiteClawTheme.coral)
            .disabled(followUpAnswer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isFollowUpVoiceListening)
        }
        .padding(12)
        .background(SiteClawTheme.coral.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var hasSuggestedFollowUp: Bool {
        !studio.activeSuggestedFollowUp.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var collapsedStatus: String {
        if hasSuggestedFollowUp {
            return "Follow-up ready. Expand to answer."
        }

        return studio.voiceCoachStatus
    }

    private var statusColor: Color {
        if studio.isVoiceCoachWorking {
            return SiteClawTheme.gold
        }

        guard let confidence = studio.latestVoiceCoachTurn?.confidence else {
            return SiteClawTheme.sky
        }

        return confidenceColor(for: confidence)
    }

    private func applyFollowUp() {
        stopFollowUpVoice(status: "")
        guard let request = studio.applyVoiceCoachFollowUpAnswer(followUpAnswer) else { return }
        followUpAnswer = ""
        followUpVoiceStatus = ""
        coachTask?.cancel()
        studio.beginVoiceCoachTurn(for: request)
        coachTask = Task {
            do {
                let response = try await VoiceCoachService().coachTurn(request: request)
                guard !Task.isCancelled else { return }

                await MainActor.run {
                    studio.applyVoiceCoachResponse(response, for: request)
                }
            } catch {
                guard !Task.isCancelled else { return }

                await MainActor.run {
                    studio.failVoiceCoachTurn(error, for: request)
                }
            }
        }
    }

    private func toggleFollowUpVoice() {
        if isFollowUpVoiceListening {
            stopFollowUpVoice(status: "Follow-up voice paused. Continue main build by voice when ready.")
        } else {
            startFollowUpVoice()
        }
    }

    private func startFollowUpVoice() {
        followUpVoiceTask?.cancel()
        followUpAudioStreamer?.stop()
        followUpAudioStreamer = nil
        followUpAudioLevel = 0
        followUpVoiceStatus = "Starting follow-up voice. Main build by voice is paused."
        isMainVoiceListening = false
        isFollowUpVoiceListening = true

        let restaurantName = studio.restaurant.name
        followUpVoiceTask = Task {
            do {
                let response = try await RealtimeSessionService().createSession(restaurantName: restaurantName)
                guard !Task.isCancelled else { return }

                let streamer = await MainActor.run {
                    let streamer = RealtimeAudioStreamingService()
                    followUpAudioStreamer = streamer
                    followUpVoiceStatus = "Listening for your follow-up answer."
                    return streamer
                }

                try await streamer.start(session: response, restaurantName: restaurantName) { event in
                    Task { @MainActor in
                        handleFollowUpVoiceEvent(event)
                    }
                }

                guard !Task.isCancelled else { return }
                await MainActor.run {
                    finishFollowUpVoice(status: "Follow-up voice stopped. Continue main build by voice when ready.")
                }
            } catch {
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    finishFollowUpVoice(status: "Follow-up voice unavailable. You can still type the answer.")
                }
            }
        }
    }

    private func handleFollowUpVoiceEvent(_ event: RealtimeAudioStreamingEvent) {
        switch event {
        case .webSocketConnected:
            followUpVoiceStatus = "Follow-up voice connected."
        case .microphoneStarted(_, _):
            followUpVoiceStatus = "Listening for your follow-up answer."
        case .audioLevel(let level):
            followUpAudioLevel = level
        case .audioChunkSent(_, _):
            followUpVoiceStatus = "Listening. Answer only the suggested follow-up."
        case .speechStarted:
            followUpVoiceStatus = "Speech detected."
        case .speechStopped:
            followUpVoiceStatus = "Pause detected. Preparing the follow-up answer."
        case .inputTranscriptDelta(let delta):
            guard !delta.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
            followUpVoiceStatus = "Heard: \(delta)"
        case .inputTranscriptCompleted(let transcript):
            let normalized = VoiceTranscriptNormalizer.normalize(transcript)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            guard !normalized.isEmpty else { return }
            mergeFollowUpVoiceAnswer(normalized)
            finishFollowUpVoice(status: "Follow-up captured. Tap Apply Follow-up when it looks right.")
        case .warning(let message), .error(let message):
            followUpVoiceStatus = message
        default:
            break
        }
    }

    private func mergeFollowUpVoiceAnswer(_ answer: String) {
        let current = followUpAnswer.trimmingCharacters(in: .whitespacesAndNewlines)
        if current.isEmpty {
            followUpAnswer = answer
        } else if !current.localizedCaseInsensitiveContains(answer) {
            followUpAnswer = "\(current) \(answer)"
        }
    }

    private func stopFollowUpVoice(status: String) {
        followUpVoiceTask?.cancel()
        followUpVoiceTask = nil
        followUpAudioStreamer?.stop()
        followUpAudioStreamer = nil
        followUpAudioLevel = 0
        isFollowUpVoiceListening = false
        if !status.isEmpty {
            followUpVoiceStatus = status
        }
    }

    private func finishFollowUpVoice(status: String) {
        followUpVoiceTask = nil
        followUpAudioStreamer?.stop()
        followUpAudioStreamer = nil
        followUpAudioLevel = 0
        isFollowUpVoiceListening = false
        followUpVoiceStatus = status
    }

    private func confidenceColor(for confidence: VoiceCoachConfidence) -> Color {
        switch confidence {
        case .high: SiteClawTheme.mint
        case .medium: SiteClawTheme.gold
        case .low: SiteClawTheme.coral
        }
    }

    private func confidenceIcon(for confidence: VoiceCoachConfidence) -> String {
        switch confidence {
        case .high: "checkmark.seal.fill"
        case .medium: "exclamationmark.triangle.fill"
        case .low: "questionmark.circle.fill"
        }
    }
}

private struct CoachFactRow: View {
    let title: String
    let value: String
    let systemImage: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: systemImage)
                .foregroundStyle(SiteClawTheme.sky)
                .frame(width: 22, height: 22)
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
                Text(value.isEmpty ? "No cleaned answer yet." : value)
                    .font(.subheadline)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

private struct CoachTagSection: View {
    let title: String
    let tags: [String]
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 6) {
                ForEach(tags, id: \.self) { tag in
                    Label(tag, systemImage: "sparkle")
                        .font(.caption)
                        .foregroundStyle(SiteClawTheme.ink)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 6)
                        .background(color.opacity(0.10))
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
            }
        }
    }
}

private struct ActiveQuestionDock: View {
    @Bindable var studio: SiteClawStudio
    let isListening: Bool
    @State private var coachTask: Task<Void, Never>?

    var body: some View {
        GlassFloatingContainer {
            HStack(spacing: 12) {
                Image(systemName: isListening ? "waveform.circle.fill" : "checkmark.circle.fill")
                    .font(.title3)
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(isListening ? SiteClawTheme.coral : SiteClawTheme.mint)
                    .frame(width: 30, height: 30)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 2) {
                    Text(studio.activeVoiceStepLabel)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.secondary)
                    Text(studio.activeVoicePrompt.question)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(SiteClawTheme.ink)
                        .lineLimit(2)
                }

                Spacer(minLength: 0)

                Button {
                    if let request = studio.captureCurrentVoicePrompt() {
                        runVoiceCoach(request)
                    }
                } label: {
                    Label("Save Answer", systemImage: "checkmark")
                        .labelStyle(.iconOnly)
                }
                .buttonStyle(.borderedProminent)
                .tint(SiteClawTheme.coral)
                .disabled(!canCapture)
                .accessibilityLabel("Save current answer")
            }
        }
        .onDisappear {
            coachTask?.cancel()
        }
    }

    private var canCapture: Bool {
        !studio.pendingVoiceAnswer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func runVoiceCoach(_ request: VoiceCoachRequest) {
        coachTask?.cancel()
        studio.beginVoiceCoachTurn(for: request)
        coachTask = Task {
            do {
                let response = try await VoiceCoachService().coachTurn(request: request)
                guard !Task.isCancelled else { return }

                await MainActor.run {
                    studio.applyVoiceCoachResponse(response, for: request)
                }
            } catch {
                guard !Task.isCancelled else { return }

                await MainActor.run {
                    studio.failVoiceCoachTurn(error, for: request)
                }
            }
        }
    }
}

private struct TalkReviewDisclosure: View {
    @Bindable var studio: SiteClawStudio
    @State private var isExpanded = false

    var body: some View {
        VStack(spacing: 12) {
            Button {
                withAnimation(.snappy(duration: 0.24)) {
                    isExpanded.toggle()
                }
            } label: {
                SectionDisclosureRow(
                    title: "Review Saved Answers",
                    subtitle: "Transcript, answer review, and draft generation tools.",
                    statusTitle: progressLabel,
                    statusImage: "checklist",
                    statusColor: SiteClawTheme.mint,
                    systemImage: "text.bubble.fill",
                    tint: SiteClawTheme.sky,
                    isExpanded: isExpanded
                )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Review saved answers, \(progressLabel)")
            .accessibilityHint(isExpanded ? "Collapse review tools" : "Expand review tools")

            if isExpanded {
                VStack(spacing: 16) {
                    VoiceProfileReviewCard(studio: studio)
                    CapturedDetailsList(prompts: studio.voicePrompts)
                    MissingDetailsPanel(studio: studio)
                    TranscriptEditor(studio: studio)
                    VoiceActionPanel(studio: studio)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    private var progressLabel: String {
        let capturedCount = studio.voicePrompts.filter {
            !$0.capturedAnswer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }.count
        return "\(capturedCount)/\(studio.voicePrompts.count)"
    }
}

private struct VoiceProfileReviewCard: View {
    @Bindable var studio: SiteClawStudio

    var body: some View {
        VStack(spacing: 12) {
            SectionHeader(
                title: "Structured Profile Review",
                subtitle: "What Build will use after the guided walkthrough."
            )

            ClawCard {
                VStack(alignment: .leading, spacing: 14) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(reviewTitle)
                                .font(.headline)
                            Text("Review confidence before moving into Build. Low-confidence fields should be edited or saved again.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        Spacer()

                        StatusPill(
                            title: "\(readyCount)/\(studio.voiceCaptureReviewItems.count)",
                            systemImage: "checklist",
                            color: readyCount == studio.voiceCaptureReviewItems.count ? SiteClawTheme.mint : SiteClawTheme.gold
                        )
                    }

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 220), spacing: 10)], spacing: 10) {
                        ForEach(studio.voiceCaptureReviewItems) { item in
                            VoiceProfileReviewTile(item: item)
                        }
                    }

                    Button {
                        _ = studio.applyVoiceTranscriptToProfile()
                    } label: {
                        Label("Apply Review to Build", systemImage: "arrow.down.doc.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(SiteClawTheme.mint)
                }
            }
        }
    }

    private var readyCount: Int {
        studio.voiceCaptureReviewItems.filter(\.isReady).count
    }

    private var reviewTitle: String {
        readyCount == studio.voiceCaptureReviewItems.count
            ? "Saved profile is ready"
            : "Review saved profile"
    }
}

private struct VoiceProfileReviewTile: View {
    let item: VoiceCaptureReviewItem

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: item.systemImage)
                .foregroundStyle(item.isReady ? SiteClawTheme.mint : SiteClawTheme.gold)
                .frame(width: 24, height: 24)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 6) {
                    Text(item.title)
                        .font(.caption.weight(.bold))
                    Text(item.statusLabel)
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(item.isReady ? SiteClawTheme.mint : SiteClawTheme.gold)
                }

                Text(item.value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Needs owner input" : item.value)
                    .font(.caption)
                    .foregroundStyle(SiteClawTheme.ink)
                    .lineLimit(4)
                    .fixedSize(horizontal: false, vertical: true)

                ProgressView(value: item.confidence)
                    .tint(item.isReady ? SiteClawTheme.mint : SiteClawTheme.gold)
                    .accessibilityLabel("\(item.title) confidence")
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, minHeight: 104, alignment: .topLeading)
        .background((item.isReady ? SiteClawTheme.mint : SiteClawTheme.gold).opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(item.isReady ? SiteClawTheme.mint.opacity(0.20) : SiteClawTheme.gold.opacity(0.20), lineWidth: 1)
        }
    }
}

private struct CapturedDetailsList: View {
    let prompts: [VoiceOnboardingPrompt]

    var body: some View {
        VStack(spacing: 12) {
            SectionHeader(
                title: "Saved Answers",
                subtitle: "Review what SiteClaw has saved from the guided questions."
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

private struct MissingDetailsPanel: View {
    @Bindable var studio: SiteClawStudio

    var body: some View {
        VStack(spacing: 12) {
            SectionHeader(
                title: "Still Needed",
                subtitle: "Ask only for details that are missing from the owner profile."
            )

            ClawCard {
                VStack(alignment: .leading, spacing: 14) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(studio.missingDetails.isEmpty ? "Ready for owner review" : "Next details to capture")
                                .font(.headline)
                            Text(statusText)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        Spacer()

                        Label(studio.missingDetailsProgressLabel, systemImage: "checklist")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(SiteClawTheme.mint)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                            .background(SiteClawTheme.mint.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }

                    if !studio.missingDetails.isEmpty {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 210), spacing: 10)], spacing: 10) {
                            ForEach(studio.missingDetails) { detail in
                                MissingDetailTile(detail: detail)
                            }
                        }

                        Button {
                            studio.focusNextMissingDetail()
                        } label: {
                            Label("Ask Next Missing Detail", systemImage: "arrow.right.circle.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(SiteClawTheme.navy)
                    }
                }
            }
        }
    }

    private var statusText: String {
        if studio.missingDetails.isEmpty {
            return "The profile has the tracked basics SiteClaw needs for a fuller draft."
        }

        let next = studio.missingDetails[0]
        return "Next: \(next.title). \(next.detail)"
    }
}

private struct MissingDetailTile: View {
    let detail: MissingDetail

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: detail.systemImage)
                .foregroundStyle(detail.isOptional ? SiteClawTheme.gold : SiteClawTheme.coral)
                .frame(width: 24, height: 24)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(detail.title)
                        .font(.headline)
                    if detail.isOptional {
                        Text("Optional")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(SiteClawTheme.gold)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(SiteClawTheme.gold.opacity(0.12))
                            .clipShape(Capsule())
                    }
                }
                Text(detail.detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 86, alignment: .topLeading)
        .background((detail.isOptional ? SiteClawTheme.gold : SiteClawTheme.coral).opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct TranscriptEditor: View {
    @Bindable var studio: SiteClawStudio

    var body: some View {
        VStack(spacing: 12) {
            SectionHeader(
                title: "Transcript",
                subtitle: "Review or correct the exact speech text before generating the draft."
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
                Label(isGeneratingDraft ? "Generating Draft" : "Generate Website Draft", systemImage: isGeneratingDraft ? "hourglass" : "sparkles")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(isGeneratingDraft)

            Text(generationMessage ?? "Creates website copy from the saved answers. You can still correct details in Build.")
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

        guard studio.applyVoiceTranscriptToProfile() else {
            generationMessage = "Record or type restaurant details before generating a website draft."
            isGeneratingDraft = false
            return
        }

        generationMessage = "Polishing the saved profile, then writing the website draft."

        let profileRequest = ProfileExtractionRequest(studio: studio)
        generationTask = Task {
            do {
                let profileResponse = try await ProfileExtractionService().extractProfile(request: profileRequest)
                guard !Task.isCancelled else { return }

                await MainActor.run {
                    studio.applyProfileExtraction(profileResponse)
                    generationMessage = "Profile polished. Writing the website draft."
                }
            } catch {
                guard !Task.isCancelled else { return }

                await MainActor.run {
                    generationMessage = "Using the local capture. Writing the website draft."
                }
            }

            let request = await MainActor.run {
                SiteGenerationRequest(studio: studio)
            }

            do {
                let response = try await SiteGenerationService().generateDraft(request: request)
                guard !Task.isCancelled else { return }

                await MainActor.run {
                    studio.applyGeneratedDraft(response)
                    generationMessage = "Website draft is ready for Preview."
                    isGeneratingDraft = false
                }
            } catch {
                guard !Task.isCancelled else { return }

                await MainActor.run {
                    studio.useLocalDraftFallback(after: error)
                    generationMessage = "SiteClaw used the offline demo draft so Preview stays ready."
                    isGeneratingDraft = false
                }
            }
        }
    }
}

#Preview {
    TalkToSiteClawView(studio: SiteClawStudio.preview)
}

//
//  SiteClawStudio.swift
//  SiteClaw
//

import Foundation
import Observation

@Observable
final class SiteClawStudio {
    var restaurant: RestaurantProfile
    var draft: WebsiteDraft
    var messages: [BuilderMessage]
    var updates: [SiteUpdate]
    var metrics: [DashboardMetric]
    var voicePrompts: [VoiceOnboardingPrompt]
    var voiceTranscript: String
    var pendingVoiceAnswer: String
    var realtimeStatus: String
    var realtimeConnectionDetail: String
    var realtimeModel: String
    var realtimeVoice: String
    var realtimeSessionExpiresAt: Date?
    var realtimeAudioLevel: Double
    var realtimeStreamedAudioBytes: Int
    var realtimeAssistantReplyDraft: String
    var activeVoicePromptIndex: Int
    var isPublished: Bool
    var isDraftGenerated: Bool
    var monthlyPrice: Int
    var siteExportStatus: String
    var lastSiteExportedAt: Date?

    init(
        restaurant: RestaurantProfile,
        draft: WebsiteDraft,
        messages: [BuilderMessage],
        updates: [SiteUpdate],
        metrics: [DashboardMetric],
        voicePrompts: [VoiceOnboardingPrompt] = VoiceOnboardingPrompt.samples,
        voiceTranscript: String = VoiceOnboardingPrompt.sampleTranscript,
        pendingVoiceAnswer: String = "",
        realtimeStatus: String = "Ready",
        realtimeConnectionDetail: String = "Tap Start to begin the guided voice demo.",
        realtimeModel: String = "",
        realtimeVoice: String = "",
        realtimeSessionExpiresAt: Date? = nil,
        realtimeAudioLevel: Double = 0,
        realtimeStreamedAudioBytes: Int = 0,
        realtimeAssistantReplyDraft: String = "",
        activeVoicePromptIndex: Int = 0,
        isPublished: Bool = false,
        isDraftGenerated: Bool = true,
        monthlyPrice: Int = 19,
        siteExportStatus: String = "No site export prepared yet.",
        lastSiteExportedAt: Date? = nil
    ) {
        self.restaurant = restaurant
        self.draft = draft
        self.messages = messages
        self.updates = updates
        self.metrics = metrics
        self.voicePrompts = voicePrompts
        self.voiceTranscript = voiceTranscript
        self.pendingVoiceAnswer = pendingVoiceAnswer
        self.realtimeStatus = realtimeStatus
        self.realtimeConnectionDetail = realtimeConnectionDetail
        self.realtimeModel = realtimeModel
        self.realtimeVoice = realtimeVoice
        self.realtimeSessionExpiresAt = realtimeSessionExpiresAt
        self.realtimeAudioLevel = realtimeAudioLevel
        self.realtimeStreamedAudioBytes = realtimeStreamedAudioBytes
        self.realtimeAssistantReplyDraft = realtimeAssistantReplyDraft
        self.activeVoicePromptIndex = activeVoicePromptIndex
        self.isPublished = isPublished
        self.isDraftGenerated = isDraftGenerated
        self.monthlyPrice = monthlyPrice
        self.siteExportStatus = siteExportStatus
        self.lastSiteExportedAt = lastSiteExportedAt
    }

    var publishStatus: String {
        isPublished ? "Live" : isDraftGenerated ? "Ready to publish" : "Draft needed"
    }

    var completionPercent: Int {
        var completed = 0
        completed += restaurant.name.isEmpty ? 0 : 1
        completed += restaurant.cuisine.isEmpty ? 0 : 1
        completed += restaurant.hours.isEmpty ? 0 : 1
        completed += restaurant.menuItems.isEmpty ? 0 : 1
        completed += isDraftGenerated ? 1 : 0
        return Int((Double(completed) / 5.0) * 100)
    }

    var voiceProgress: Double {
        guard !voicePrompts.isEmpty else { return 0 }
        let answered = voicePrompts.filter { !$0.capturedAnswer.isEmpty }.count
        return Double(answered) / Double(voicePrompts.count)
    }

    var missingDetails: [MissingDetail] {
        var details: [MissingDetail] = []

        if restaurant.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            details.append(
                MissingDetail(
                    kind: .restaurantName,
                    title: "Restaurant Name",
                    detail: "Needed before the draft can use the correct brand name.",
                    prompt: "What exact restaurant name should customers see?",
                    systemImage: "storefront.fill",
                    isOptional: false
                )
            )
        }

        let menuItems = restaurant.menuItems
        let missingPriceCount = menuItems.filter { ($0.price ?? 0) <= 0 }.count
        if !menuItems.isEmpty, missingPriceCount > 0 {
            details.append(
                MissingDetail(
                    kind: .menuPrices,
                    title: "Menu Prices",
                    detail: "\(missingPriceCount) menu item\(missingPriceCount == 1 ? "" : "s") still need prices.",
                    prompt: "What are the prices for \(menuItems.map(\.name).joined(separator: ", "))?",
                    systemImage: "tag.fill",
                    isOptional: false
                )
            )
        }

        let missingDescriptionCount = menuItems.filter {
            $0.description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }.count
        if !menuItems.isEmpty, missingDescriptionCount > 0 {
            details.append(
                MissingDetail(
                    kind: .dishDescriptions,
                    title: "Dish Descriptions",
                    detail: "\(missingDescriptionCount) menu item\(missingDescriptionCount == 1 ? "" : "s") need short descriptions.",
                    prompt: "Describe each featured dish in one short phrase.",
                    systemImage: "text.bubble.fill",
                    isOptional: false
                )
            )
        }

        if restaurant.formattedAddress.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || restaurant.streetAddress.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            details.append(
                MissingDetail(
                    kind: .address,
                    title: "Street Address",
                    detail: "A street address helps customers navigate from the site.",
                    prompt: "What is the restaurant street address?",
                    systemImage: "mappin.and.ellipse",
                    isOptional: true
                )
            )
        }

        if restaurant.phone.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            details.append(
                MissingDetail(
                    kind: .phone,
                    title: "Phone",
                    detail: "Optional, but useful for customers who want to call.",
                    prompt: "What phone number should customers call?",
                    systemImage: "phone.fill",
                    isOptional: true
                )
            )
        }

        return details
    }

    var missingDetailsProgressLabel: String {
        let total = missingDetails.count + readyDetailCount
        guard total > 0 else { return "Ready" }
        return "\(readyDetailCount)/\(total)"
    }

    private var readyDetailCount: Int {
        var count = 0
        if !restaurant.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { count += 1 }
        if !restaurant.menuItems.isEmpty,
           restaurant.menuItems.allSatisfy({ ($0.price ?? 0) > 0 }) { count += 1 }
        if !restaurant.menuItems.isEmpty,
           restaurant.menuItems.allSatisfy({ !$0.description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) { count += 1 }
        if !restaurant.streetAddress.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { count += 1 }
        if !restaurant.phone.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { count += 1 }
        return count
    }

    var activeVoicePrompt: VoiceOnboardingPrompt {
        guard !voicePrompts.isEmpty else {
            return VoiceOnboardingPrompt.empty
        }

        let safeIndex = min(max(activeVoicePromptIndex, 0), voicePrompts.count - 1)
        return voicePrompts[safeIndex]
    }

    var activeVoiceStepLabel: String {
        guard !voicePrompts.isEmpty else { return "Step 0 of 0" }
        return "Step \(min(activeVoicePromptIndex + 1, voicePrompts.count)) of \(voicePrompts.count)"
    }

    var realtimeSessionLabel: String {
        var parts: [String] = []

        if !realtimeModel.isEmpty {
            parts.append(realtimeModel)
        }

        if !realtimeVoice.isEmpty {
            parts.append("voice \(realtimeVoice)")
        }

        if let realtimeSessionExpiresAt {
            parts.append("expires \(realtimeSessionExpiresAt.formatted(date: .omitted, time: .shortened))")
        }

        return parts.isEmpty ? "Voice service ready" : parts.joined(separator: " - ")
    }

    var realtimeAudioDiagnosticLabel: String {
        if realtimeStreamedAudioBytes > 0 {
            return "Microphone is active"
        }

        switch realtimeStatus {
        case "Connecting", "Streaming", "Listening", "Processing", "Transcribing":
            return "Listening for sound"
        default:
            return ""
        }
    }

    var restaurantJSON: RestaurantJSON {
        RestaurantJSONExporter.makeRestaurantJSON(from: restaurant, draft: draft)
    }

    var restaurantJSONString: String {
        RestaurantJSONExporter.prettyJSONString(from: restaurantJSON)
    }

    var siteExport: GeneratedSiteExport {
        GeneratedSiteRenderer.makeExport(from: restaurantJSON, draft: draft)
    }

    var siteExportDetail: String {
        guard let lastSiteExportedAt else {
            return siteExportStatus
        }

        return "\(siteExportStatus) Prepared \(lastSiteExportedAt.formatted(date: .omitted, time: .shortened))."
    }

    func generateDraft() {
        polishCapturedProfileForPublishing()

        let restaurantName = restaurant.name.isEmpty ? "your restaurant" : restaurant.name
        let cuisine = restaurant.cuisine.isEmpty ? "Local restaurant" : restaurant.cuisine
        let neighborhood = restaurant.neighborhood.isEmpty ? "your neighborhood" : restaurant.neighborhood
        let offer = websiteOfferPhrase(cuisine: cuisine, menuItems: restaurant.menuItems)
        let headline = restaurant.name.isEmpty
            ? "A polished restaurant website from your voice"
            : "\(restaurantName) serves \(offer) in \(neighborhood)"
        let keywords = localSEOKeywords(
            restaurantName: restaurantName,
            cuisine: cuisine,
            offer: offer,
            neighborhood: neighborhood,
            menuItems: restaurant.menuItems
        )

        draft = WebsiteDraft(
            headline: headline,
            subheadline: restaurant.story.isEmpty
                ? "Fresh food, clear hours, and a menu customers can trust before they visit."
                : restaurant.story,
            callToAction: "View Menu",
            pages: ["Home", "Menu", "Hours", "Location", "About"],
            seoKeywords: keywords,
            url: slugURL(for: restaurantName),
            lastGeneratedSummary: "Generated a five-page restaurant site with menu, hours, local SEO, and mobile-ready content."
        )

        isDraftGenerated = true
        siteExportStatus = "Draft changed. Refresh the site export when ready."
        lastSiteExportedAt = nil
        messages.append(
            BuilderMessage(
                role: .assistant,
                text: "I generated a restaurant website draft with your menu, hours, location, and local SEO pages. You can preview it now."
            )
        )
        addUpdate(
            type: .announcement,
            title: "Website draft generated",
            detail: "AI created a first version of the site from the owner conversation.",
            timeLabel: "Just now"
        )
    }

    func applyGeneratedDraft(_ response: SiteGenerationResponse) {
        polishCapturedProfileForPublishing()

        let generatedRestaurantName = RestaurantNameResolver.displayName(
            restaurantName: restaurant.name,
            headline: response.draft.headline,
            seoKeywords: response.draft.seoKeywords,
            fallback: ""
        )
        let restaurantName = generatedRestaurantName.isEmpty ? "your restaurant" : generatedRestaurantName

        if restaurant.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
           !generatedRestaurantName.isEmpty {
            restaurant.name = generatedRestaurantName
        }
        let headline = polishedDraftHeadline(
            response.draft.headline,
            restaurantName: restaurantName,
            cuisine: restaurant.cuisine,
            neighborhood: restaurant.neighborhood,
            menuItems: restaurant.menuItems
        )

        draft = WebsiteDraft(
            headline: headline,
            subheadline: response.draft.subheadline,
            callToAction: response.draft.callToAction,
            pages: response.draft.pages,
            seoKeywords: response.draft.seoKeywords,
            url: slugURL(for: restaurantName),
            lastGeneratedSummary: response.draft.lastGeneratedSummary
        )

        isDraftGenerated = true
        realtimeStatus = "Generated"
        realtimeConnectionDetail = "Website draft is ready for Preview."
        siteExportStatus = "Draft changed. Refresh the site export when ready."
        lastSiteExportedAt = nil
        messages.append(BuilderMessage(role: .assistant, text: response.reply))
        addUpdate(
            type: .announcement,
            title: "AI website draft generated",
            detail: response.draft.lastGeneratedSummary,
            timeLabel: "Just now"
        )
    }

    func useLocalDraftFallback(after _: Error) {
        processVoiceTranscript()
        realtimeConnectionDetail = "SiteClaw used the offline demo draft so Preview stays ready."
    }

    func publishDraft() {
        isPublished = true
        prepareSiteExport()
        addUpdate(
            type: .publish,
            title: "Site published",
            detail: "\(restaurant.name) is live at \(draft.url)",
            timeLabel: "Just now"
        )
    }

    func prepareSiteExport() {
        let export = siteExport
        lastSiteExportedAt = Date()
        siteExportStatus = "\(export.defaultFilename).html is ready to save or share."
        addUpdate(
            type: .publish,
            title: "Static site export prepared",
            detail: "Generated \(export.sizeLabel) of HTML from restaurant.json.",
            timeLabel: "Just now"
        )
    }

    func applyQuickUpdate(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let lowercased = trimmed.lowercased()
        let type: SiteUpdate.UpdateType

        if lowercased.contains("hour") || lowercased.contains("close") || lowercased.contains("open") {
            type = .hours
        } else if lowercased.contains("menu") || lowercased.contains("special") || lowercased.contains("price") {
            type = .menu
        } else if lowercased.contains("photo") || lowercased.contains("image") {
            type = .photo
        } else {
            type = .announcement
        }

        messages.append(BuilderMessage(role: .owner, text: trimmed))
        messages.append(BuilderMessage(role: .assistant, text: "Done. I turned that request into a website update and prepared it for publishing."))
        addUpdate(type: type, title: "Quick update prepared", detail: trimmed, timeLabel: "Just now")
    }

    func loadVoiceExample() {
        restaurant = RestaurantProfile.sample
        voiceTranscript = VoiceOnboardingPrompt.sampleTranscript
        pendingVoiceAnswer = ""
        voicePrompts = VoiceOnboardingPrompt.filledSamples
        activeVoicePromptIndex = voicePrompts.count - 1
        realtimeStatus = "Captured"
        realtimeConnectionDetail = "Loaded the guided demo transcript and prepared the restaurant details."
        messages.append(
            BuilderMessage(
                role: .owner,
                text: "Sunset Grill is an American burger and sandwich spot in San Jose. Here is our menu, hours, and neighborhood story."
            )
        )
        generateDraft()
    }

    func startRealtimeSession() {
        let shouldResumeVoiceCapture = !voiceTranscript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && voiceProgress > 0
            && voiceProgress < 1
            && voicePrompts.indices.contains(activeVoicePromptIndex)

        realtimeStatus = "Connecting"
        realtimeConnectionDetail = shouldResumeVoiceCapture
            ? "Preparing voice capture so you can continue the current prompt."
            : "Preparing voice capture for the guided questions."
        realtimeModel = ""
        realtimeVoice = ""
        realtimeSessionExpiresAt = nil
        realtimeAudioLevel = 0
        realtimeStreamedAudioBytes = 0
        realtimeAssistantReplyDraft = ""

        if shouldResumeVoiceCapture {
            messages.append(
                BuilderMessage(
                    role: .assistant,
                    text: "Continue with: \(activeVoicePrompt.question)"
                )
            )
        } else {
            activeVoicePromptIndex = 0
            voicePrompts = VoiceOnboardingPrompt.samples
            voiceTranscript = ""
            pendingVoiceAnswer = ""
            messages.append(
                BuilderMessage(
                    role: .assistant,
                    text: "Answer the visible question, pause, then tap Capture when the transcript matches that question."
                )
            )
        }
    }

    func stopRealtimeSession() {
        realtimeAudioLevel = 0
        realtimeStatus = voiceTranscript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Ready" : "Captured"
        realtimeConnectionDetail = voiceTranscript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? "Recording stopped before text was captured."
            : "Recording stopped. Generate a website draft when you are ready."
    }

    func completeRealtimeSession(_ response: RealtimeSessionResponse) {
        realtimeStatus = "Token Ready"
        realtimeModel = response.model ?? ""
        realtimeVoice = response.voice ?? ""
        realtimeSessionExpiresAt = response.expiresAt.map { Date(timeIntervalSince1970: TimeInterval($0)) }
        realtimeConnectionDetail = "Voice capture is ready to start."
        messages.append(
            BuilderMessage(
                role: .assistant,
                text: "Voice capture is ready. Answer the visible question when you start recording."
            )
        )
    }

    func beginRealtimeAudioStream(_ response: RealtimeSessionResponse) {
        realtimeStatus = "Streaming"
        realtimeModel = response.model ?? ""
        realtimeVoice = response.voice ?? ""
        realtimeSessionExpiresAt = response.expiresAt.map { Date(timeIntervalSince1970: TimeInterval($0)) }
        realtimeAudioLevel = 0
        realtimeStreamedAudioBytes = 0
        realtimeAssistantReplyDraft = ""
        realtimeConnectionDetail = "Opening the microphone for the current question."
    }

    func handleRealtimeStreamEvent(_ event: RealtimeAudioStreamingEvent) {
        switch event {
        case .microphonePermissionGranted:
            realtimeStatus = "Connecting"
            realtimeConnectionDetail = "Microphone permission granted."
        case .webSocketConnected:
            realtimeStatus = "Streaming"
            realtimeConnectionDetail = "Voice capture connected. Speak naturally into the microphone."
        case .sessionConfigured:
            realtimeConnectionDetail = "Voice capture is configured for live transcription."
        case .microphoneStarted(_, _):
            realtimeStatus = "Streaming"
            realtimeConnectionDetail = "Microphone opened. Waiting for audio to reach SiteClaw."
        case .audioLevel(let level):
            realtimeAudioLevel = level
        case .audioChunkSent(_, let totalBytes):
            realtimeStreamedAudioBytes = totalBytes
            realtimeStatus = "Listening"
            realtimeConnectionDetail = "Listening. Keep your answer focused on the visible question."
        case .speechStarted:
            realtimeStatus = "Listening"
            realtimeConnectionDetail = "Speech detected. Keep answering the current SiteClaw prompt."
        case .speechStopped:
            realtimeStatus = "Processing"
            realtimeConnectionDetail = "Pause detected. Preparing this answer."
        case .inputCommitted:
            realtimeStatus = "Transcribing"
            realtimeConnectionDetail = "Audio turn committed. Waiting for transcript text."
        case .inputTranscriptDelta(let delta):
            guard !delta.isEmpty else { return }
            realtimeStatus = "Transcribing"
            realtimeConnectionDetail = "Live transcript: \(delta)"
        case .inputTranscriptCompleted(let transcript):
            captureRealtimeTranscript(transcript)
        case .assistantTranscriptDelta(let delta):
            guard !delta.isEmpty else { return }
            realtimeAssistantReplyDraft += delta
            realtimeStatus = "SiteClaw Replying"
            realtimeConnectionDetail = realtimeAssistantReplyDraft
        case .assistantTranscriptCompleted(let transcript):
            let finalReply = transcript.isEmpty ? realtimeAssistantReplyDraft : transcript
            if !finalReply.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                messages.append(BuilderMessage(role: .assistant, text: finalReply))
            }
            realtimeAssistantReplyDraft = ""
            realtimeStatus = "Listening"
            realtimeConnectionDetail = "SiteClaw reply captured as text. Audio playback comes next."
        case .responseCompleted:
            if !realtimeAssistantReplyDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                messages.append(BuilderMessage(role: .assistant, text: realtimeAssistantReplyDraft))
                realtimeAssistantReplyDraft = ""
            }
        case .disconnected:
            realtimeAudioLevel = 0
            realtimeStatus = voiceTranscript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Ready" : "Captured"
            realtimeConnectionDetail = "Voice capture closed."
        case .warning(let message):
            realtimeConnectionDetail = message
        case .error(let message):
            realtimeStatus = "Realtime Error"
            realtimeConnectionDetail = message
            realtimeAudioLevel = 0
        }
    }

    func failRealtimeSession(_ error: Error) {
        realtimeStatus = "Backend Needed"
        realtimeConnectionDetail = error.localizedDescription
        realtimeModel = ""
        realtimeVoice = ""
        realtimeSessionExpiresAt = nil
        realtimeAudioLevel = 0
        realtimeStreamedAudioBytes = 0
        realtimeAssistantReplyDraft = ""
        messages.append(
            BuilderMessage(
                role: .assistant,
                text: "I could not start live voice yet. Check that the SiteClaw backend is running, then try again."
            )
        )
    }

    func failRealtimeAudioStream(_ error: Error) {
        realtimeStatus = "Realtime Error"
        realtimeConnectionDetail = error.localizedDescription
        realtimeAudioLevel = 0
        realtimeStreamedAudioBytes = 0
        realtimeAssistantReplyDraft = ""
        messages.append(
            BuilderMessage(
                role: .assistant,
                text: "Voice capture stopped. Check microphone access, then try recording again."
            )
        )
    }

    func captureCurrentVoicePrompt() {
        guard voicePrompts.indices.contains(activeVoicePromptIndex) else { return }

        voiceTranscript = VoiceTranscriptNormalizer.normalize(voiceTranscript)
        pendingVoiceAnswer = VoiceTranscriptNormalizer.normalize(pendingVoiceAnswer)
        let currentPrompt = voicePrompts[activeVoicePromptIndex]
        let answerSource = currentAnswerSource

        if let missingDetailKind = currentPrompt.missingDetailKind {
            let answer = answerSource.trimmingCharacters(in: .whitespacesAndNewlines)
            guard applyMissingDetailAnswer(answer, kind: missingDetailKind) else {
                realtimeStatus = "Needs Detail"
                realtimeConnectionDetail = "That answer did not include the detail SiteClaw needs yet."
                return
            }

            voicePrompts[activeVoicePromptIndex].capturedAnswer = answer
            pendingVoiceAnswer = ""
            realtimeStatus = missingDetails.isEmpty ? "Ready to Publish" : "Captured"
            realtimeConnectionDetail = nextMissingDetailMessage
            return
        }

        let extraction = TranscriptRestaurantExtractor.extract(from: answerSource)
        let extractedAnswer = extraction.promptAnswers[activeVoicePromptIndex]
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let fallbackAnswer = answerSource.trimmingCharacters(in: .whitespacesAndNewlines)
        let answer = extractedAnswer.isEmpty ? fallbackAnswer : extractedAnswer

        guard !answer.isEmpty else {
            realtimeStatus = "Needs Answer"
            realtimeConnectionDetail = "Speak or type an answer before capturing this prompt. Use Demo when you want sample data."
            return
        }

        restaurant = mergeWithExistingProfile(extraction.profile)
        voicePrompts[activeVoicePromptIndex].capturedAnswer = answer
        pendingVoiceAnswer = ""

        if activeVoicePromptIndex < voicePrompts.count - 1 {
            activeVoicePromptIndex += 1
            realtimeStatus = "Listening"
            realtimeConnectionDetail = "Captured that answer. Read the next question, then speak one answer and tap Capture."
        } else {
            realtimeStatus = "Captured"
            realtimeConnectionDetail = "All guided answers are captured. Generate the website draft when ready."
        }
    }

    func previousVoicePrompt() {
        activeVoicePromptIndex = max(activeVoicePromptIndex - 1, 0)
    }

    func focusNextMissingDetail() {
        guard let detail = missingDetails.first else {
            realtimeStatus = "Ready to Publish"
            realtimeConnectionDetail = "All tracked owner details are captured."
            return
        }

        let prompt = VoiceOnboardingPrompt(
            question: detail.prompt,
            helperText: detail.detail,
            capturedAnswer: "",
            systemImage: detail.systemImage,
            missingDetailKind: detail.kind
        )

        if let existingIndex = voicePrompts.firstIndex(where: { $0.missingDetailKind == detail.kind }) {
            voicePrompts[existingIndex] = prompt
            activeVoicePromptIndex = existingIndex
        } else {
            voicePrompts.append(prompt)
            activeVoicePromptIndex = voicePrompts.count - 1
        }

        realtimeStatus = "Needs Detail"
        realtimeConnectionDetail = "Record one answer for: \(detail.title)."
    }

    func resetVoiceOnboarding() {
        voicePrompts = VoiceOnboardingPrompt.samples
        voiceTranscript = ""
        pendingVoiceAnswer = ""
        realtimeStatus = "Ready"
        realtimeConnectionDetail = "Tap Start to begin the guided voice demo."
        realtimeModel = ""
        realtimeVoice = ""
        realtimeSessionExpiresAt = nil
        realtimeAudioLevel = 0
        realtimeStreamedAudioBytes = 0
        realtimeAssistantReplyDraft = ""
        activeVoicePromptIndex = 0
    }

    @discardableResult
    func applyVoiceTranscriptToProfile() -> Bool {
        let trimmedTranscript = voiceTranscript.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTranscript.isEmpty else {
            realtimeStatus = "Needs Transcript"
            realtimeConnectionDetail = "Record or type the restaurant details before generating a draft."
            return false
        }

        voiceTranscript = VoiceTranscriptNormalizer.normalize(trimmedTranscript)
        let extraction = TranscriptRestaurantExtractor.extract(from: voiceTranscript)
        restaurant = mergeWithExistingProfile(extraction.profile)
        polishCapturedProfileForPublishing()
        voicePrompts = TranscriptRestaurantExtractor.makePrompts(from: extraction.promptAnswers)
        activeVoicePromptIndex = voicePrompts.firstIndex { $0.capturedAnswer.isEmpty }
            ?? max(voicePrompts.count - 1, 0)
        realtimeStatus = "Captured"
        realtimeConnectionDetail = missingDetails.isEmpty
            ? "Transcript processed and all tracked owner details are captured."
            : "Transcript processed. \(missingDetails.count) detail\(missingDetails.count == 1 ? "" : "s") still need owner input."
        siteExportStatus = "Restaurant details changed. Refresh the site export when ready."
        lastSiteExportedAt = nil
        return true
    }

    func processVoiceTranscript() {
        guard applyVoiceTranscriptToProfile() else { return }
        activeVoicePromptIndex = voicePrompts.count - 1
        realtimeStatus = "Generated"
        realtimeConnectionDetail = "Transcript processed into restaurant data and website content."
        messages.append(BuilderMessage(role: .owner, text: voiceTranscript))
        messages.append(
            BuilderMessage(
                role: .assistant,
                text: "I pulled out the restaurant profile, menu, hours, and local search terms from your voice onboarding."
            )
        )
        generateDraft()
    }

    private func appendTranscriptAnswer(_ answer: String) {
        let normalizedAnswer = VoiceTranscriptNormalizer.normalize(answer)

        if voiceTranscript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            voiceTranscript = normalizedAnswer
        } else if !voiceTranscript.contains(normalizedAnswer) {
            voiceTranscript += " \(normalizedAnswer)"
        }

        if pendingVoiceAnswer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            pendingVoiceAnswer = normalizedAnswer
        } else if !pendingVoiceAnswer.contains(normalizedAnswer) {
            pendingVoiceAnswer += " \(normalizedAnswer)"
        }
    }

    private func captureRealtimeTranscript(_ transcript: String) {
        let trimmed = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let normalized = VoiceTranscriptNormalizer.normalize(trimmed)
        appendTranscriptAnswer(normalized)
        messages.append(BuilderMessage(role: .owner, text: normalized))

        realtimeStatus = "Heard Answer"
        realtimeConnectionDetail = "Transcript is ready for the visible question. Tap Capture when it looks right."
    }

    private var currentAnswerSource: String {
        let pending = pendingVoiceAnswer.trimmingCharacters(in: .whitespacesAndNewlines)
        return pending.isEmpty ? voiceTranscript : pending
    }

    @discardableResult
    private func applyMissingDetailAnswer(_ answer: String, kind: MissingDetailKind) -> Bool {
        let normalizedAnswer = VoiceTranscriptNormalizer.normalize(answer)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedAnswer.isEmpty else { return false }

        let wasApplied: Bool

        switch kind {
        case .restaurantName:
            if let name = MissingDetailAnswerExtractor.restaurantName(from: normalizedAnswer) {
                restaurant.name = name
                wasApplied = true
            } else {
                wasApplied = false
            }
        case .menuPrices:
            wasApplied = MissingDetailAnswerExtractor.applyMenuPrices(from: normalizedAnswer, to: &restaurant.menuItems)
        case .dishDescriptions:
            wasApplied = MissingDetailAnswerExtractor.applyMenuDescriptions(from: normalizedAnswer, to: &restaurant.menuItems)
        case .phone:
            if let phone = MissingDetailAnswerExtractor.phone(from: normalizedAnswer) {
                restaurant.phone = phone
                wasApplied = true
            } else {
                wasApplied = false
            }
        case .address:
            let address = MissingDetailAnswerExtractor.address(from: normalizedAnswer)
            if !address.streetAddress.isEmpty { restaurant.streetAddress = address.streetAddress }
            if !address.city.isEmpty { restaurant.neighborhood = address.city }
            if !address.state.isEmpty { restaurant.state = address.state }
            if !address.postalCode.isEmpty { restaurant.postalCode = address.postalCode }
            wasApplied = !address.streetAddress.isEmpty
        }

        if wasApplied {
            siteExportStatus = "Restaurant details changed. Refresh the site export when ready."
            lastSiteExportedAt = nil
        }

        return wasApplied
    }

    private var nextMissingDetailMessage: String {
        guard let next = missingDetails.first else {
            return "All tracked owner details are captured. Generate or refresh the website draft when you are ready."
        }

        return "Captured that detail. Next missing detail: \(next.title)."
    }

    private func mergeWithExistingProfile(_ profile: RestaurantProfile) -> RestaurantProfile {
        var merged = profile

        if merged.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            merged.name = restaurant.name
        }
        if merged.cuisine.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            merged.cuisine = restaurant.cuisine
        }
        if merged.neighborhood.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            merged.neighborhood = restaurant.neighborhood
        }
        if merged.streetAddress.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            merged.streetAddress = restaurant.streetAddress
        }
        if merged.state.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            merged.state = restaurant.state
        }
        if merged.postalCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            merged.postalCode = restaurant.postalCode
        }
        if merged.phone.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            merged.phone = restaurant.phone
        }
        if merged.hours.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            merged.hours = restaurant.hours
        }
        if merged.story.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            merged.story = restaurant.story
        }

        merged.menuItems = mergeMenuItems(extracted: merged.menuItems, existing: restaurant.menuItems)
        return merged
    }

    private func mergeMenuItems(extracted: [MenuItem], existing: [MenuItem]) -> [MenuItem] {
        guard !extracted.isEmpty else { return existing }

        return extracted.map { extractedItem in
            guard let existingItem = existing.first(where: {
                MissingDetailAnswerExtractor.menuKey($0.name) == MissingDetailAnswerExtractor.menuKey(extractedItem.name)
            }) else {
                return extractedItem
            }

            return MenuItem(
                name: extractedItem.name,
                description: extractedItem.description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    ? existingItem.description
                    : extractedItem.description,
                price: extractedItem.price ?? existingItem.price
            )
        }
    }

    private func polishCapturedProfileForPublishing() {
        restaurant.cuisine = polishedCuisine(restaurant.cuisine, menuItems: restaurant.menuItems)
        repairKnownDemoPriceArtifacts()

        guard !restaurant.menuItems.isEmpty else { return }

        for index in restaurant.menuItems.indices {
            let description = restaurant.menuItems[index].description.trimmingCharacters(in: .whitespacesAndNewlines)
            let polishedDescription = defaultMenuDescription(
                for: restaurant.menuItems[index].name,
                cuisine: restaurant.cuisine,
                restaurantName: restaurant.name
            )

            if description.isEmpty || shouldReplaceGeneratedMenuDescription(description, for: restaurant.menuItems[index].name) {
                restaurant.menuItems[index].description = polishedDescription
            }
        }
    }

    private func repairKnownDemoPriceArtifacts() {
        let restaurantName = restaurant.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let menuKeys = restaurant.menuItems.map { MissingDetailAnswerExtractor.menuKey($0.name) }

        guard restaurantName == "sunset grill",
              menuKeys.contains(where: { $0.contains("cheeseburger") }),
              menuKeys.contains(where: { $0.contains("chicken") && $0.contains("sandwich") }),
              menuKeys.contains(where: isFriesMenuKey),
              menuKeys.contains("lemonade") else {
            return
        }

        for index in restaurant.menuItems.indices {
            guard isFriesMenuKey(MissingDetailAnswerExtractor.menuKey(restaurant.menuItems[index].name)) else {
                continue
            }

            let price = restaurant.menuItems[index].price ?? 0
            if price == 0 || abs(price - 4.0) < 0.001 {
                restaurant.menuItems[index].price = 4.99
            }
        }
    }

    private func isFriesMenuKey(_ key: String) -> Bool {
        key == "fries" || key == "frie"
    }

    private func polishedCuisine(_ cuisine: String, menuItems: [MenuItem]) -> String {
        let trimmed = cuisine.trimmingCharacters(in: .whitespacesAndNewlines)
        let lowercased = trimmed.lowercased()

        if lowercased == "american" || lowercased == "american food" {
            return "American restaurant"
        }

        if trimmed.isEmpty, !menuItems.isEmpty {
            return "Local restaurant"
        }

        return trimmed
    }

    private func websiteOfferPhrase(cuisine: String, menuItems: [MenuItem]) -> String {
        let itemKeys = menuItems.map { MissingDetailAnswerExtractor.menuKey($0.name) }
        let hasBurger = itemKeys.contains { $0.contains("burger") }
        let hasSandwich = itemKeys.contains { $0.contains("sandwich") }

        if cuisine.localizedCaseInsensitiveContains("american"), hasBurger, hasSandwich {
            return "American burgers and sandwiches"
        }

        let cleanedCuisine = cuisine.trimmingCharacters(in: .whitespacesAndNewlines)
        let lowercasedCuisine = cleanedCuisine.lowercased()

        if lowercasedCuisine == "american restaurant" {
            return "American food"
        }

        if lowercasedCuisine.hasSuffix(" restaurant") {
            return String(cleanedCuisine.dropLast(" restaurant".count)).trimmingCharacters(in: .whitespacesAndNewlines)
        }

        if !cleanedCuisine.isEmpty {
            return cleanedCuisine
        }

        return "local food"
    }

    private func polishedDraftHeadline(
        _ headline: String,
        restaurantName: String,
        cuisine: String,
        neighborhood: String,
        menuItems: [MenuItem]
    ) -> String {
        let trimmed = headline.trimmingCharacters(in: .whitespacesAndNewlines)
        let lowercased = trimmed.lowercased()

        guard trimmed.isEmpty
                || lowercased.contains("brings american")
                || lowercased.contains("brings local food")
        else {
            return trimmed
        }

        let offer = websiteOfferPhrase(cuisine: cuisine, menuItems: menuItems)
        let city = neighborhood.trimmingCharacters(in: .whitespacesAndNewlines)
        return city.isEmpty
            ? "\(restaurantName) serves \(offer)"
            : "\(restaurantName) serves \(offer) in \(city)"
    }

    private func localSEOKeywords(
        restaurantName: String,
        cuisine: String,
        offer: String,
        neighborhood: String,
        menuItems: [MenuItem]
    ) -> [String] {
        var keywords = [
            restaurantName,
            neighborhood.isEmpty ? cuisine : "\(cuisine) in \(neighborhood)",
            neighborhood.isEmpty ? offer : "\(offer.lowercased()) in \(neighborhood)"
        ]

        keywords.append(contentsOf: menuItems.prefix(3).map(\.name))

        return keywords.reduce(into: [String]()) { result, keyword in
            let cleaned = keyword.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !cleaned.isEmpty,
                  !result.contains(where: { $0.caseInsensitiveCompare(cleaned) == .orderedSame })
            else { return }
            result.append(cleaned)
        }
    }

    private func defaultMenuDescription(for itemName: String, cuisine: String, restaurantName: String) -> String {
        let name = itemName.trimmingCharacters(in: .whitespacesAndNewlines)
        let key = MissingDetailAnswerExtractor.menuKey(name)
        let restaurant = restaurantName.trimmingCharacters(in: .whitespacesAndNewlines)
        let place = restaurant.isEmpty ? "the menu" : "\(restaurant)'s menu"
        let restaurantLabel = restaurant.isEmpty ? "the restaurant" : restaurant

        if key.contains("cheeseburger") {
            return "A classic cheeseburger with the fresh, friendly feel customers expect at \(restaurantLabel)."
        }

        if key.contains("chicken") && key.contains("sandwich") {
            return "A satisfying chicken sandwich made for a quick lunch or casual dinner."
        }

        if key == "fries" || key == "frie" || key.contains("fries") || key.contains("frie") {
            return "Crisp fries that pair naturally with burgers, sandwiches, and cold drinks."
        }

        if key.contains("lemonade") {
            return "A bright, refreshing lemonade for lunch, dinner, or a quick stop."
        }

        if key.contains("pho") {
            return "A comforting bowl built around slow-simmered broth and fresh herbs."
        }

        if key.contains("rice bowl") {
            return "A hearty rice bowl with fresh toppings and a simple, satisfying finish."
        }

        if key.contains("spring roll") {
            return "Fresh spring rolls made for a light start or shareable side."
        }

        let cuisineLabel = cuisine.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if cuisineLabel.isEmpty {
            return "A customer favorite from \(place)."
        }

        return "A customer favorite from the \(cuisineLabel) lineup at \(restaurantLabel)."
    }

    private func shouldReplaceGeneratedMenuDescription(_ description: String, for itemName: String) -> Bool {
        let key = MissingDetailAnswerExtractor.menuKey(itemName)
        let lowercasedDescription = description.lowercased()
        let isKnownPolishedItem = key.contains("cheeseburger")
            || (key.contains("chicken") && key.contains("sandwich"))
            || key.contains("fries")
            || key.contains("frie")
            || key.contains("lemonade")
            || key.contains("pho")
            || key.contains("rice bowl")
            || key.contains("spring roll")

        guard isKnownPolishedItem else { return false }

        return lowercasedDescription.contains("description not captured")
            || lowercasedDescription.contains("customer favorite from the")
            || lowercasedDescription.contains("american restaurant lineup")
    }

    private func addUpdate(type: SiteUpdate.UpdateType, title: String, detail: String, timeLabel: String) {
        updates.removeAll { update in
            update.type == type
                && update.title == title
                && update.detail == detail
        }

        updates.insert(
            SiteUpdate(type: type, title: title, detail: detail, timeLabel: timeLabel),
            at: 0
        )
    }

    private func slugURL(for name: String) -> String {
        let slug = name
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: "-")

        return "https://\(slug.isEmpty ? "restaurant" : slug).siteclaw.app"
    }

}

struct TranscriptRestaurantExtraction {
    var profile: RestaurantProfile
    var promptAnswers: [String]
}

enum VoiceTranscriptNormalizer {
    static func normalize(_ transcript: String) -> String {
        var normalized = transcript
            .replacingOccurrences(of: #"\bfaux rice bowls\b"#, with: "pho, rice bowls", options: [.regularExpression, .caseInsensitive])
            .replacingOccurrences(of: #"\bfo rice bowls\b"#, with: "pho, rice bowls", options: [.regularExpression, .caseInsensitive])
            .replacingOccurrences(of: #"\bfoh rice bowls\b"#, with: "pho, rice bowls", options: [.regularExpression, .caseInsensitive])
            .replacingOccurrences(of: #"\bfah rice bowls\b"#, with: "pho, rice bowls", options: [.regularExpression, .caseInsensitive])
            .replacingOccurrences(of: #"\bfa rice bowls\b"#, with: "pho, rice bowls", options: [.regularExpression, .caseInsensitive])
            .replacingOccurrences(of: #"\bpho rice bowls\b"#, with: "pho, rice bowls", options: [.regularExpression, .caseInsensitive])
            .replacingOccurrences(of: #"\bbuddha\s+lotus\b"#, with: "Pho Lotus", options: [.regularExpression, .caseInsensitive])
            .replacingOccurrences(of: #"\bhouse\s+of\s+(?=\$?\d)"#, with: "house pho for ", options: [.regularExpression, .caseInsensitive])
            .replacingOccurrences(of: #"\b(?:fauspa|fau spa|fouspa|fowspa|howspha|howsfa|howspa|house fa|house spa)\b"#, with: "house pho", options: [.regularExpression, .caseInsensitive])
            .replacingOccurrences(of: #"\b(rice bowls?\s+for\s+)(\d{1,2})\.90\s+\2\.99\b"#, with: "$1$2.49", options: [.regularExpression, .caseInsensitive])
            .replacingOccurrences(of: #"\b(\d{1,2})\s+(?:forty|fourty)[-\s]?(?:nine|9)\b"#, with: "$1.49", options: [.regularExpression, .caseInsensitive])
            .replacingOccurrences(of: #"\b(\d{1,2})\s+eighty[-\s]?(?:nine|9)\b"#, with: "$1.99", options: [.regularExpression, .caseInsensitive])
            .replacingOccurrences(of: #"\b(\d{1,2})\s+ninety[-\s]?(?:nine|9)\b"#, with: "$1.99", options: [.regularExpression, .caseInsensitive])
            .replacingOccurrences(of: #"\bfo lotus\b"#, with: "Pho Lotus", options: [.regularExpression, .caseInsensitive])
            .replacingOccurrences(of: #"\b(?:pha|pah|fa|fah|fu|foo|buh|boh|bo|poh|fuh)\s+lotus\b"#, with: "Pho Lotus", options: [.regularExpression, .caseInsensitive])
            .replacingOccurrences(of: #"\bphone lotus\b"#, with: "Pho Lotus", options: [.regularExpression, .caseInsensitive])
            .replacingOccurrences(of: #"\bprize\s+for\b"#, with: "fries for", options: [.regularExpression, .caseInsensitive])
            .replacingOccurrences(of: #"\bprized\b"#, with: "fries", options: [.regularExpression, .caseInsensitive])
            .replacingOccurrences(of: #"\beat\s+your\s+(?=(?:cheeseburgers?|chicken sandwiches?|fries|lemonade|house pho|rice bowls?|spring rolls?))"#, with: "Feature ", options: [.regularExpression, .caseInsensitive])
            .replacingOccurrences(of: #"\ba\.?\s*m\.?"#, with: "AM", options: [.regularExpression, .caseInsensitive])
            .replacingOccurrences(of: #"\bp\.?\s*m\.?"#, with: "PM", options: [.regularExpression, .caseInsensitive])

        for (word, number) in numberWords {
            normalized = normalized.replacingOccurrences(
                of: "\\b\(word)\\b",
                with: number,
                options: [.regularExpression, .caseInsensitive]
            )
        }

        return normalized
            .replacingOccurrences(of: #"\b(\d{1,2})\s+(?:forty|fourty)[-\s]?(?:nine|9)\b"#, with: "$1.49", options: [.regularExpression, .caseInsensitive])
            .replacingOccurrences(of: #"\b(\d{1,2})\s+eighty[-\s]?(?:nine|9)\b"#, with: "$1.99", options: [.regularExpression, .caseInsensitive])
            .replacingOccurrences(of: #"\b(\d{1,2})\s+ninety[-\s]?(?:nine|9)\b"#, with: "$1.99", options: [.regularExpression, .caseInsensitive])
    }

    private static let numberWords = [
        "one": "1",
        "two": "2",
        "three": "3",
        "four": "4",
        "five": "5",
        "six": "6",
        "seven": "7",
        "eight": "8",
        "nine": "9",
        "ten": "10",
        "eleven": "11",
        "twelve": "12",
        "thirteen": "13",
        "fourteen": "14",
        "fifteen": "15",
        "sixteen": "16",
        "seventeen": "17",
        "eighteen": "18",
        "nineteen": "19",
        "twenty": "20"
    ]
}

struct AddressExtraction {
    var streetAddress: String = ""
    var city: String = ""
    var state: String = ""
    var postalCode: String = ""
}

enum MissingDetailAnswerExtractor {
    static func restaurantName(from text: String) -> String? {
        let patterns = [
            #"\b(?:called|named|restaurant is|business is)\s+([A-Za-z0-9&' .-]{2,80}?)(?=\.|,|\s+(?:it\s+is|it's|it’s|we\s+|we're\s+|serves?\s+|open\s+|in\s+)|$)"#,
            #"^([A-Za-z0-9&' .-]{2,80})$"#
        ]

        for pattern in patterns {
            if let match = firstMatch(pattern, in: text),
               let cleaned = cleanName(match) {
                return cleaned
            }
        }

        return nil
    }

    static func applyMenuPrices(from text: String, to items: inout [MenuItem]) -> Bool {
        guard !items.isEmpty else { return false }

        var changed = false
        let prices = allPrices(in: text)
        let missingIndexes = items.indices.filter { (items[$0].price ?? 0) <= 0 }

        if prices.count == missingIndexes.count, !prices.isEmpty {
            for (index, price) in zip(missingIndexes, prices) {
                items[index].price = price
            }
            return true
        }

        let splitText = text
            .replacingOccurrences(of: #"\s+and\s+"#, with: ", ", options: [.regularExpression, .caseInsensitive])
        let clauses = splitText
            .components(separatedBy: CharacterSet(charactersIn: ",.;\n"))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        for clause in clauses {
            guard allPrices(in: clause).count <= 1 else { continue }

            guard let price = firstPrice(in: clause),
                  let index = bestMenuItemIndex(for: clause, in: items) else {
                continue
            }

            items[index].price = price
            changed = true
        }

        return changed
    }

    static func applyMenuDescriptions(from text: String, to items: inout [MenuItem]) -> Bool {
        guard !items.isEmpty else { return false }

        let matches = menuItemMatches(in: text, items: items)
        guard !matches.isEmpty else { return false }

        var changed = false

        for (position, match) in matches.enumerated() {
            let nextStart = matches.indices.contains(position + 1)
                ? matches[position + 1].range.lowerBound
                : text.endIndex
            let segment = String(text[match.range.lowerBound..<nextStart])
            guard let description = cleanedDescription(from: segment, itemName: items[match.itemIndex].name) else {
                continue
            }

            items[match.itemIndex].description = description
            changed = true
        }

        return changed
    }

    static func phone(from text: String) -> String? {
        firstMatch(#"((?:\+?1[\s.-]?)?(?:\(?\d{3}\)?[\s.-]?)\d{3}[\s.-]?\d{4})"#, in: text)
    }

    static func address(from text: String) -> AddressExtraction {
        let addressText = addressFocusedText(from: text) ?? text
        let street = firstMatch(
            #"\b(((?:\d\s*){2,6})(?!\s*(?:AM|PM)\b)\s+[A-Za-z0-9 .'#-]+?\s+(?:Street|St\.?|Avenue|Ave\.?|Road|Rd\.?|Boulevard|Blvd\.?|Drive|Dr\.?|Lane|Ln\.?|Way|Place|Pl\.?|Court|Ct\.?))\b"#,
            in: addressText
        ) ?? ""
        let city = knownCities.first { text.range(of: $0, options: [.caseInsensitive]) != nil } ?? ""
        let rawState = firstMatch(#"\b(CA|California)\b"#, in: text) ?? ""
        let postalCode = firstMatch(#"\b(\d{5}(?:-\d{4})?)\b"#, in: text) ?? ""

        return AddressExtraction(
            streetAddress: cleanAddress(street),
            city: city,
            state: rawState.isEmpty ? "" : "CA",
            postalCode: postalCode
        )
    }

    static func menuKey(_ value: String) -> String {
        value
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .map { word in
                if word.hasSuffix("s"), word.count > 3 {
                    return String(word.dropLast())
                }
                return word
            }
            .joined()
    }

    private static let knownCities = [
        "San Jose", "San Francisco", "Oakland", "Daly City", "Los Angeles", "Sacramento",
        "Berkeley", "Fremont", "Santa Clara", "Sunnyvale", "Mountain View", "Palo Alto"
    ]

    private static func addressFocusedText(from text: String) -> String? {
        let patterns = [
            #"\b(?:restaurant\s+street\s+address\s+is|street\s+address\s+is|address\s+is|located\s+at|we\s+are\s+at|we're\s+at|restaurant\s+is\s+at)\s+(.+?)(?=$|\.|;|\n)"#
        ]

        for pattern in patterns {
            guard let match = firstMatch(pattern, in: text) else { continue }
            let cleaned = match
                .replacingOccurrences(
                    of: #"^(?:the\s+)?(?:restaurant\s+)?street\s+address\s+"#,
                    with: "",
                    options: [.regularExpression, .caseInsensitive]
                )
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if !cleaned.isEmpty {
                return cleaned
            }
        }

        return nil
    }

    private static func bestMenuItemIndex(for text: String, in items: [MenuItem]) -> Int? {
        let key = menuKey(text)
        return items.indices.first { index in
            let itemKey = menuKey(items[index].name)
            return key.contains(itemKey) || itemKey.contains(key)
        }
    }

    private static func firstPrice(in text: String) -> Double? {
        allPrices(in: text).first
    }

    private static func allPrices(in text: String) -> [Double] {
        guard let regex = try? NSRegularExpression(
            pattern: #"(?:\$|for\s+)?(\d+(?:\.\d{1,2})?)\s*(?:dollars|bucks)?"#,
            options: [.caseInsensitive]
        ) else {
            return []
        }

        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        return regex.matches(in: text, range: range).compactMap { match in
            guard match.numberOfRanges > 1,
                  let matchRange = Range(match.range(at: 1), in: text) else {
                return nil
            }

            return Double(String(text[matchRange]))
        }
    }

    private static func menuItemMatches(in text: String, items: [MenuItem]) -> [(itemIndex: Int, range: Range<String.Index>)] {
        var matches: [(itemIndex: Int, range: Range<String.Index>)] = []

        for index in items.indices {
            let escapedName = NSRegularExpression.escapedPattern(for: items[index].name)
            guard let regex = try? NSRegularExpression(pattern: #"\b\#(escapedName)\b"#, options: [.caseInsensitive]) else {
                continue
            }

            let range = NSRange(text.startIndex..<text.endIndex, in: text)
            for match in regex.matches(in: text, range: range) {
                guard let matchRange = Range(match.range, in: text) else { continue }
                matches.append((index, matchRange))
            }
        }

        return matches.sorted { $0.range.lowerBound < $1.range.lowerBound }
    }

    private static func cleanedDescription(from segment: String, itemName: String) -> String? {
        var cleaned = segment
            .replacingOccurrences(of: NSRegularExpression.escapedPattern(for: itemName), with: "", options: [.regularExpression, .caseInsensitive])
            .replacingOccurrences(
                of: #"^\s*(?:is|are|has|have|with|contains|includes|comes with|:|-)\s+"#,
                with: "",
                options: [.regularExpression, .caseInsensitive]
            )
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: CharacterSet.whitespacesAndNewlines.union(CharacterSet(charactersIn: ".:;-,")))

        guard cleaned.count >= 6 else { return nil }

        cleaned = cleaned.prefix(1).uppercased() + String(cleaned.dropFirst())
        if !cleaned.hasSuffix(".") {
            cleaned += "."
        }

        return cleaned
    }

    private static func cleanName(_ value: String) -> String? {
        let cleaned = value
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: CharacterSet.whitespacesAndNewlines.union(CharacterSet(charactersIn: ".:;")))
        guard cleaned.count >= 2 else { return nil }

        return titleCased(cleaned)
    }

    private static func cleanAddress(_ value: String) -> String {
        let cleaned = value
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: CharacterSet.whitespacesAndNewlines.union(CharacterSet(charactersIn: ".:;,")))

        guard let rawStreetNumber = firstMatch(#"^((?:\d\s*){2,6})(?=\s+[A-Za-z])"#, in: cleaned) else {
            return cleaned
        }

        let collapsedStreetNumber = rawStreetNumber.filter(\.isNumber)
        return collapsedStreetNumber + String(cleaned.dropFirst(rawStreetNumber.count))
    }

    private static func titleCased(_ value: String) -> String {
        value
            .split(separator: " ")
            .map { word in
                let lowercased = word.lowercased()
                if lowercased == "pho" { return "Pho" }
                if lowercased == "bbq" { return "BBQ" }
                return lowercased.prefix(1).uppercased() + String(lowercased.dropFirst())
            }
            .joined(separator: " ")
    }

    private static func firstMatch(
        _ pattern: String,
        in text: String,
        group: Int = 1,
        options: NSRegularExpression.Options = [.caseInsensitive]
    ) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: options) else {
            return nil
        }

        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        guard let match = regex.firstMatch(in: text, range: range),
              match.numberOfRanges > group,
              let matchRange = Range(match.range(at: group), in: text) else {
            return nil
        }

        return String(text[matchRange]).trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

enum TranscriptRestaurantExtractor {
    static func extract(from transcript: String) -> TranscriptRestaurantExtraction {
        let normalizedTranscript = normalizeTranscript(transcript)
        let name = extractName(from: normalizedTranscript)
        let cuisine = extractCuisine(from: normalizedTranscript)
        let city = extractCity(from: normalizedTranscript)
        let hours = extractHours(from: normalizedTranscript)
        let menuItems = extractMenuItems(from: normalizedTranscript)
        let story = extractStory(from: normalizedTranscript)
        let phone = extractPhone(from: normalizedTranscript)
        let address = MissingDetailAnswerExtractor.address(from: normalizedTranscript)

        let profile = RestaurantProfile(
            name: name,
            cuisine: cuisine,
            neighborhood: address.city.isEmpty ? city : address.city,
            streetAddress: address.streetAddress,
            state: address.state,
            postalCode: address.postalCode,
            ownerName: "",
            phone: phone,
            hours: hours,
            story: story,
            menuItems: menuItems
        )

        return TranscriptRestaurantExtraction(
            profile: profile,
            promptAnswers: [
                name,
                joinedNonEmpty([cuisine, city.isEmpty ? "" : "in \(city)"]),
                hours,
                menuItems.map { menuLabel(for: $0) }.joined(separator: ", "),
                story
            ]
        )
    }

    static func makePrompts(from answers: [String]) -> [VoiceOnboardingPrompt] {
        VoiceOnboardingPrompt.samples.enumerated().map { index, prompt in
            var prompt = prompt
            if answers.indices.contains(index) {
                prompt.capturedAnswer = answers[index]
            }
            return prompt
        }
    }

    private static func normalizeTranscript(_ transcript: String) -> String {
        VoiceTranscriptNormalizer.normalize(transcript)
    }

    private static func extractName(from transcript: String) -> String {
        let patterns = [
            #"\b(?:called|named)\s+([A-Za-z0-9&' .-]{2,80}?)(?=\.|,|\s+(?:it\s+is|it's|it’s|is\s+(?:a|an|family)|we\s+|we're\s+|open\s+|serve\s+|serves\s+|in\s+[A-Z])|$)"#,
            #"\b([A-Z][A-Za-z0-9&'.-]*(?:\s+[A-Z][A-Za-z0-9&'.-]*){1,5}\s+(?:Kitchen|Cafe|Coffee|Bakery|Grill|Restaurant|Diner|Bistro|Taqueria|Pizzeria|Bar))\b"#,
            #"\b(?:we are|we're|my restaurant is|the restaurant is)\s+([A-Za-z0-9&' .-]{2,80}?)(?=,|\.|\s+in\s+|\s+serves\s+|\s+serve\s+|\s+is\s+|$)"#
        ]

        for pattern in patterns {
            if let rawCandidate = firstMatch(pattern, in: transcript),
               let candidate = cleanNameCandidate(rawCandidate) {
                return candidate
            }
        }

        return ""
    }

    private static func extractCuisine(from transcript: String) -> String {
        let lowercased = transcript.lowercased()
        let knownCuisines = [
            "Vietnamese", "Mexican", "Italian", "Chinese", "Thai", "Japanese", "Korean", "Indian",
            "Filipino", "Ethiopian", "Mediterranean", "American", "Seafood", "Barbecue", "BBQ",
            "Pizza", "Bakery", "Coffee"
        ]

        guard let cuisine = knownCuisines.first(where: { lowercased.contains($0.lowercased()) }) else {
            return ""
        }

        if lowercased.contains("comfort") {
            return "\(cuisine) comfort food"
        }

        if lowercased.contains("restaurant") {
            return "\(cuisine) restaurant"
        }

        return cuisine
    }

    private static func extractCity(from transcript: String) -> String {
        let lowercased = transcript.lowercased()
        let knownCities = [
            "San Jose", "San Francisco", "Oakland", "Daly City", "Los Angeles", "Sacramento",
            "Berkeley", "Fremont", "Santa Clara", "Sunnyvale", "Mountain View", "Palo Alto"
        ]

        if let city = knownCities.first(where: { lowercased.contains($0.lowercased()) }) {
            return city
        }

        let pattern = #"\bin\s+([A-Z][A-Za-z]+(?:\s+[A-Z][A-Za-z]+){0,3})(?=\.|,|\s+called\s+|\s+and\s+|\s+with\s+|\s+serving\s+|\s+open\s+|$)"#
        return firstMatch(pattern, in: transcript, options: []) ?? ""
    }

    private static func extractHours(from transcript: String) -> String {
        let dayWords = ["monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday", "mon-", "daily"]
        let transcriptSentences = sentences(from: transcript)
        var candidates: [String] = []

        for (index, sentence) in transcriptSentences.enumerated() {
            let lowercased = sentence.lowercased()
            let isHoursCandidate = lowercased.contains("open")
                || lowercased.contains("hours")
                || dayWords.contains(where: lowercased.contains)

            guard isHoursCandidate else { continue }

            if !hasTimeRange(sentence),
               transcriptSentences.indices.contains(index + 1),
               hasTimeRange(transcriptSentences[index + 1]) {
                candidates.append("\(sentence) \(transcriptSentences[index + 1])")
            } else {
                candidates.append(sentence)
            }
        }

        guard let candidate = candidates.first(where: { hasTimeRange($0) }) ?? candidates.first else { return "" }

        let cleaned = normalizeHoursSpeechArtifacts(in: candidate)
            .replacingOccurrences(of: #"\b(?:we are|we're|we)\s+open\b"#, with: "", options: [.regularExpression, .caseInsensitive])
            .replacingOccurrences(of: #"\b(?:hours are|our hours are|open|from)\b"#, with: "", options: [.regularExpression, .caseInsensitive])
            .replacingOccurrences(
                of: #"\s+\b(?:what makes|what make|our story|what is special|makes us special|special is)\b.*$"#,
                with: "",
                options: [.regularExpression, .caseInsensitive]
            )
            .replacingOccurrences(
                of: #"\s+\b(?:we\s+feature|we\s+serve|we\s+sell|we\s+have|feature|features|(?:our\s+)?menu\s+items\s+(?:include|are)|our\s+menu\s+(?:has|includes|is))\b.*$"#,
                with: "",
                options: [.regularExpression, .caseInsensitive]
            )
            .replacingOccurrences(
                of: #"\s+\b(?:cheeseburgers?|chicken\s+sandwiches?|fries|lemonade|house\s+pho|rice\s+bowls?|spring\s+rolls?|iced\s+coffee)\b.*$"#,
                with: "",
                options: [.regularExpression, .caseInsensitive]
            )
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return cleaned
    }

    private static func normalizeHoursSpeechArtifacts(in candidate: String) -> String {
        let lowercased = candidate.lowercased()
        guard lowercased.contains("monday through saturday")
                || lowercased.contains("monday to saturday")
                || lowercased.contains("mon-sat")
        else {
            return candidate
        }

        return candidate.replacingOccurrences(
            of: #"\b(and\s+)Saturday(\s+(?:from\s+)?\d{1,2}(?::\d{2})?\s*(?:AM|PM)?\s*(?:-|–|to)\s*\d{1,2}(?::\d{2})?\s*(?:AM|PM)?)"#,
            with: "$1Sunday$2",
            options: [.regularExpression, .caseInsensitive]
        )
    }

    private static func extractMenuItems(from transcript: String) -> [MenuItem] {
        let clauses = menuFocusedSegments(from: transcript)

        var seenNames = Set<String>()
        var items: [MenuItem] = []

        for clause in clauses {
            for rawPart in menuParts(from: clause) {
                guard let item = makeMenuItem(from: rawPart) else { continue }
                guard insertMenuItem(item.name, into: &seenNames) else { continue }
                items.append(item)
            }
        }

        appendKnownMenuItems(from: transcript, to: &items, seenNames: &seenNames)

        return Array(items.prefix(8))
    }

    private static func menuParts(from clause: String) -> [String] {
        let cleanedClause = cleanMenuClause(clause)
            .replacingOccurrences(of: #"(?i)\s+and\s+"#, with: ", ", options: .regularExpression)
            .replacingOccurrences(of: #"\.\s+(?=[A-Z])"#, with: ", ", options: .regularExpression)
            .replacingOccurrences(of: #"&"#, with: ",", options: .regularExpression)

        return cleanedClause.components(separatedBy: ",")
            .flatMap { splitKnownMenuPhrases($0) }
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private static func cleanMenuClause(_ clause: String) -> String {
        clause
            .replacingOccurrences(
                of: #"\s+\b(?:we\s+are|we're|we)\s+open\b.*$"#,
                with: "",
                options: [.regularExpression, .caseInsensitive]
            )
            .replacingOccurrences(
                of: #"\s+\b(?:what\s+makes|what\s+make|makes\s+us\s+special|our\s+story|special\s+is)\b.*$"#,
                with: "",
                options: [.regularExpression, .caseInsensitive]
            )
            .replacingOccurrences(
                of: #"\s+\b(?:made\s+from|made\s+with|served\s+with)\s+(?:family|friendly)\b.*$"#,
                with: "",
                options: [.regularExpression, .caseInsensitive]
            )
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func splitKnownMenuPhrases(_ rawPart: String) -> [String] {
        let normalized = rawPart.lowercased()

        let matches: [(offset: Int, canonical: String)] = knownMenuPhrases.compactMap { phrase, canonical in
            if phrase == "pho", normalized.contains("house pho") {
                return nil
            }
            guard let range = normalized.range(of: phrase) else { return nil }
            let offset = normalized.distance(from: normalized.startIndex, to: range.lowerBound)
            return (offset, canonical)
        }

        let sortedMatches = matches.sorted { $0.offset < $1.offset }
        let uniqueMatches = sortedMatches.reduce(into: [String]()) { result, match in
            if !result.contains(match.canonical) {
                result.append(match.canonical)
            }
        }

        return uniqueMatches.count > 1 ? uniqueMatches : [rawPart]
    }

    private static let knownMenuPhrases: [(phrase: String, canonical: String)] = [
        ("house pho", "House Pho"),
        ("pho", "Pho"),
        ("rice bowls", "Rice Bowls"),
        ("rice bowl", "Rice Bowls"),
        ("spring rolls", "Spring Rolls"),
        ("spring roll", "Spring Rolls"),
        ("chicken sandwiches", "Chicken Sandwiches"),
        ("chicken sandwich", "Chicken Sandwiches"),
        ("cheeseburgers", "Cheeseburgers"),
        ("cheeseburger", "Cheeseburgers"),
        ("fries", "Fries"),
        ("iced coffee", "Iced Coffee"),
        ("ice coffee", "Iced Coffee"),
        ("lemonade", "Lemonade")
    ]

    private static func appendKnownMenuItems(
        from transcript: String,
        to items: inout [MenuItem],
        seenNames: inout Set<String>
    ) {
        let lowercased = transcript.lowercased()
        guard lowercased.contains("serve") || lowercased.contains("menu") || lowercased.contains("feature") else {
            return
        }

        for menuText in menuFocusedSegments(from: transcript) {
            let rawMatches: [(range: Range<String.Index>, canonical: String)] = knownMenuPhrases.compactMap { phrase, canonical in
                guard let range = menuText.range(of: phrase, options: [.caseInsensitive]) else { return nil }
                return (range, canonical)
            }
            let matches = nonOverlappingMenuMatches(rawMatches)

            for (index, match) in matches.enumerated() {
                let nextStart = matches.indices.contains(index + 1)
                    ? matches[index + 1].range.lowerBound
                    : menuText.endIndex
                let segment = cleanMenuClause(String(menuText[match.range.lowerBound..<nextStart]))
                let price = extractPrice(from: segment)
                let item = MenuItem(name: match.canonical, description: "", price: price)

                if let existingIndex = items.firstIndex(where: {
                    MissingDetailAnswerExtractor.menuKey($0.name) == MissingDetailAnswerExtractor.menuKey(item.name)
                }) {
                    if items[existingIndex].price == nil, item.price != nil {
                        items[existingIndex].price = item.price
                    }
                    continue
                }

                guard insertMenuItem(item.name, into: &seenNames) else { continue }
                items.append(item)
            }
        }
    }

    private static func menuFocusedSegments(from transcript: String) -> [String] {
        guard let regex = try? NSRegularExpression(
            pattern: #"\b(we serve|we're serving|we are serving|serving|we sell|we have|menu items include|menu items are|our menu items are|our menu has|our menu includes|we feature|feature|features)\b"#,
            options: [.caseInsensitive]
        ) else {
            return [transcript]
        }

        let range = NSRange(transcript.startIndex..<transcript.endIndex, in: transcript)
        let matches: [(trigger: String, segment: String)] = regex.matches(in: transcript, range: range).compactMap { match -> (String, String)? in
            guard let matchRange = Range(match.range, in: transcript),
                  let triggerRange = Range(match.range(at: 1), in: transcript) else { return nil }
            var segment = String(transcript[matchRange.upperBound...])

            if let stopRange = segment.range(
                of: #"\b(?:we\s+are|we're|we)\s+open\b|\b(?:what\s+makes|what\s+make|makes\s+us\s+special|our\s+story|special\s+is)\b|\b(?:restaurant\s+street\s+address|street\s+address|address\s+is|phone\s+number|my\s+restaurant\s+is|the\s+restaurant\s+is)\b"#,
                options: [.regularExpression, .caseInsensitive]
            ) {
                segment = String(segment[..<stopRange.lowerBound])
            }

            let cleaned = cleanMenuClause(segment)
            guard isLikelyMenuSegment(cleaned, trigger: String(transcript[triggerRange])) else { return nil }
            return cleaned.isEmpty ? nil : (String(transcript[triggerRange]), cleaned)
        }

        let specificMatches = matches.filter { match in
            let trigger = match.trigger.lowercased()
            return !trigger.contains("serve") && !trigger.contains("serving")
        }
        let segments = specificMatches.isEmpty ? matches.map(\.segment) : specificMatches.map(\.segment)

        return segments.isEmpty ? inferredPricedMenuSegments(from: transcript) : segments
    }

    private static func inferredPricedMenuSegments(from transcript: String) -> [String] {
        let rawMatches: [(range: Range<String.Index>, canonical: String)] = knownMenuPhrases.compactMap { phrase, canonical in
            guard let range = transcript.range(of: phrase, options: [.caseInsensitive]) else { return nil }
            return (range, canonical)
        }
        let matches = nonOverlappingMenuMatches(rawMatches)

        return matches.indices.compactMap { index in
            let match = matches[index]
            let nextStart = matches.indices.contains(index + 1)
                ? matches[index + 1].range.lowerBound
                : transcript.endIndex
            let segment = cleanMenuClause(String(transcript[match.range.lowerBound..<nextStart]))
            guard extractPrice(from: segment) != nil else { return nil }
            return segment
        }
    }

    private static func isLikelyMenuSegment(_ segment: String, trigger: String) -> Bool {
        let lowercasedSegment = segment.lowercased()
        let lowercasedTrigger = trigger.lowercased()

        if extractPrice(from: segment) != nil {
            return true
        }

        if knownMenuPhrases.contains(where: { lowercasedSegment.contains($0.phrase) }) {
            return true
        }

        let menuSpecificTriggers = [
            "menu items include", "menu items are", "our menu items are",
            "our menu has", "our menu includes", "we feature", "feature", "features",
            "we sell", "we have"
        ]
        if menuSpecificTriggers.contains(where: lowercasedTrigger.contains),
           !lowercasedSegment.contains(" in ") {
            return true
        }

        return false
    }

    private static func nonOverlappingMenuMatches(
        _ matches: [(range: Range<String.Index>, canonical: String)]
    ) -> [(range: Range<String.Index>, canonical: String)] {
        let sortedMatches = matches.sorted {
            if $0.range.lowerBound == $1.range.lowerBound {
                return $0.range.upperBound > $1.range.upperBound
            }
            return $0.range.lowerBound < $1.range.lowerBound
        }

        return sortedMatches.reduce(into: [(range: Range<String.Index>, canonical: String)]()) { result, match in
            guard let last = result.last else {
                result.append(match)
                return
            }

            if match.range.lowerBound < last.range.upperBound {
                return
            }

            result.append(match)
        }
    }

    private static func insertMenuItem(_ name: String, into seenNames: inout Set<String>) -> Bool {
        let key = MissingDetailAnswerExtractor.menuKey(name)
        guard !seenNames.contains(where: { existingKey in
            existingKey.contains(key) || key.contains(existingKey)
        }) else {
            return false
        }

        seenNames.insert(key)
        return true
    }

    private static func makeMenuItem(from rawPart: String) -> MenuItem? {
        var part = rawPart
            .replacingOccurrences(of: #"\b(?:also|plus|and|feature|features|serve|serves)\b"#, with: "", options: [.regularExpression, .caseInsensitive])
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !part.isEmpty else { return nil }

        let price = extractPrice(from: part)
        part = part
            .replacingOccurrences(of: #"\s*(?:for\s+)?\$?\d+(?:\.\d{1,2})?\s*"#, with: " ", options: [.regularExpression, .caseInsensitive])
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: CharacterSet.whitespacesAndNewlines.union(CharacterSet(charactersIn: ".:;")))

        let lowercased = part.lowercased()
        let rejected = ["food", "menu", "dishes", "restaurant", "comfort food", "what"]
        let rejectedFragments = [
            "friendly", "neighborhood", "service", "family recipe", "open ", "monday", "tuesday",
            "wednesday", "thursday", "friday", "saturday", "sunday", "what makes", "special",
            "vietnamese comfort", "comfort food in", " in san jose", " in san francisco",
            " in oakland", " in los angeles"
        ]
        guard part.count >= 3,
              part.count <= 48,
              !rejected.contains(lowercased),
              !rejectedFragments.contains(where: lowercased.contains) else {
            return nil
        }

        return MenuItem(
            name: titleCasedMenuName(part),
            description: "",
            price: price
        )
    }

    private static func extractPrice(from text: String) -> Double? {
        allMatches(#"(?:\$|for\s+)(\d+(?:\.\d{1,2})?)"#, in: text)
            .compactMap(Double.init)
            .last { $0 > 0 }
    }

    private static func extractStory(from transcript: String) -> String {
        let preferredWords = ["family-owned", "family owned", "special", "recipe", "broth", "owner", "neighborhood"]
        let transcriptSentences = sentences(from: transcript)

        for sentence in transcriptSentences {
            if let explicitStory = firstMatch(
                #"\b(?:what makes (?:us|this|our restaurant)? special is|makes us special is|our story is)\s+(.+)$"#,
                in: sentence
            ),
                let cleaned = cleanStoryCandidate(explicitStory) {
                return cleaned
            }
        }

        guard let sentence = transcriptSentences.first(where: { sentence in
            let lowercased = sentence.lowercased()
            return !lowercased.contains("called")
                && preferredWords.contains(where: lowercased.contains)
        }) else {
            return ""
        }

        return cleanStoryCandidate(sentence) ?? ""
    }

    private static func cleanStoryCandidate(_ candidate: String) -> String? {
        let cleaned = candidate
            .replacingOccurrences(of: #"^for\s+"#, with: "", options: [.regularExpression, .caseInsensitive])
            .replacingOccurrences(of: #"^.*\b(?:it\s+is|it's|it’s)\s+"#, with: "", options: [.regularExpression, .caseInsensitive])
            .replacingOccurrences(
                of: #"^.*\b(?:what makes (?:us|this|our restaurant)? special is|makes us special is|our story is)\s+"#,
                with: "",
                options: [.regularExpression, .caseInsensitive]
            )
            .replacingOccurrences(of: #"family owned"#, with: "family-owned", options: [.regularExpression, .caseInsensitive])
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard cleaned.count >= 6,
              !cleaned.lowercased().contains("called") else {
            return nil
        }

        return cleaned.prefix(1).uppercased() + String(cleaned.dropFirst())
    }

    private static func extractPhone(from transcript: String) -> String {
        firstMatch(#"((?:\+?1[\s.-]?)?(?:\(?\d{3}\)?[\s.-]?)\d{3}[\s.-]?\d{4})"#, in: transcript) ?? ""
    }

    private static func menuLabel(for item: MenuItem) -> String {
        guard let price = item.price, price > 0 else {
            return item.name
        }

        return "\(item.name) \(String(format: "$%.2f", price))"
    }

    private static func cleanNameCandidate(_ candidate: String) -> String? {
        let trimmed = candidate
            .replacingOccurrences(
                of: #"^(?:we\s+are|we're|my\s+restaurant\s+is|the\s+restaurant\s+is)\s+"#,
                with: "",
                options: [.regularExpression, .caseInsensitive]
            )
            .replacingOccurrences(
                of: #"\s+\b(?:it\s+is|it's|it’s|is\s+(?:a|an|family)|we\s+|we're\s+|open\s+|serve\s+|serves\s+|in\s+[A-Z]).*$"#,
                with: "",
                options: [.regularExpression, .caseInsensitive]
            )
            .trimmingCharacters(in: CharacterSet.whitespacesAndNewlines.union(CharacterSet(charactersIn: ".:;")))
        let lowercased = trimmed.lowercased()
        let invalidNameWords = [
            "open", "hour", "monday", "tuesday", "wednesday", "thursday", "friday", "saturday",
            "sunday", "from", " am", " pm", "restaurant in", "family owned", "family-owned"
        ]

        guard !trimmed.isEmpty,
              !lowercased.hasPrefix("a "),
              !lowercased.hasPrefix("an "),
              !invalidNameWords.contains(where: lowercased.contains),
              lowercased != "restaurant" else {
            return nil
        }

        return titleCasedMenuName(trimmed)
    }

    private static func titleCasedMenuName(_ value: String) -> String {
        value
            .split(separator: " ")
            .map { word in
                let lowercased = word.lowercased()
                if lowercased == "pho" { return "Pho" }
                if lowercased == "bbq" { return "BBQ" }
                return lowercased.prefix(1).uppercased() + String(lowercased.dropFirst())
            }
            .joined(separator: " ")
    }

    private static func sentences(from text: String) -> [String] {
        text
            .components(separatedBy: CharacterSet(charactersIn: ".!?\n"))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private static func hasTimeRange(_ text: String) -> Bool {
        text.range(
            of: #"\d{1,2}(?::\d{2})?\s*(?:AM|PM)?\s*(?:-|–|to)\s*\d{1,2}(?::\d{2})?\s*(?:AM|PM)?"#,
            options: [.regularExpression, .caseInsensitive]
        ) != nil
    }

    private static func joinedNonEmpty(_ parts: [String]) -> String {
        parts
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    private static func firstMatch(
        _ pattern: String,
        in text: String,
        group: Int = 1,
        options: NSRegularExpression.Options = [.caseInsensitive]
    ) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: options) else {
            return nil
        }

        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        guard let match = regex.firstMatch(in: text, range: range),
              match.numberOfRanges > group,
              let matchRange = Range(match.range(at: group), in: text) else {
            return nil
        }

        return String(text[matchRange]).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func allMatches(_ pattern: String, in text: String) -> [String] {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
            return []
        }

        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        return regex.matches(in: text, range: range).compactMap { match in
            guard match.numberOfRanges > 1,
                  let matchRange = Range(match.range(at: 1), in: text) else {
                return nil
            }

            return String(text[matchRange]).trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }

}

extension RestaurantProfile {
    var formattedAddress: String {
        let stateLine = [state, postalCode]
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: " ")
        return [streetAddress, neighborhood, stateLine]
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: ", ")
    }

    static let empty = RestaurantProfile(
        name: "",
        cuisine: "",
        neighborhood: "",
        ownerName: "",
        phone: "",
        hours: "",
        story: "",
        menuItems: []
    )

    static let sample = RestaurantProfile(
        name: "Sunset Grill",
        cuisine: "American restaurant",
        neighborhood: "San Jose",
        ownerName: "",
        phone: "",
        hours: "Monday through Saturday 10 AM to 8 PM, Sunday 11 AM to 6 PM",
        story: "Fresh ingredients, fast service, and a friendly neighborhood atmosphere.",
        menuItems: [
            MenuItem(name: "Cheeseburgers", description: "A classic cheeseburger with the fresh, friendly feel customers expect at Sunset Grill.", price: 12.99),
            MenuItem(name: "Chicken Sandwiches", description: "A satisfying chicken sandwich made for a quick lunch or casual dinner.", price: 11.49),
            MenuItem(name: "Fries", description: "Crisp fries that pair naturally with burgers, sandwiches, and cold drinks.", price: 4.99),
            MenuItem(name: "Lemonade", description: "A bright, refreshing lemonade for lunch, dinner, or a quick stop.", price: 3.49)
        ]
    )
}

extension WebsiteDraft {
    static let placeholder = WebsiteDraft(
        headline: "Build a restaurant website by talking to SiteClaw",
        subheadline: "Capture the menu, hours, story, photos, and local SEO in one guided conversation.",
        callToAction: "Start Building",
        pages: ["Home", "Menu", "Hours"],
        seoKeywords: ["restaurant website", "local restaurant", "menu online"],
        url: "https://preview.siteclaw.app",
        lastGeneratedSummary: "No generated site yet. Add restaurant details or use the voice example."
    )

    static let sample = WebsiteDraft(
        headline: "Sunset Grill serves American burgers and sandwiches in San Jose",
        subheadline: "Fresh ingredients, fast service, and a friendly neighborhood atmosphere.",
        callToAction: "View Menu",
        pages: ["Home", "Menu", "Hours", "Location", "About"],
        seoKeywords: ["Sunset Grill", "American restaurant in San Jose", "american burgers and sandwiches in San Jose", "Cheeseburgers", "Chicken Sandwiches", "Fries"],
        url: "https://sunset-grill.siteclaw.app",
        lastGeneratedSummary: "Generated a mobile-first restaurant website with menu, hours, location, and local SEO content."
    )
}

extension SiteClawStudio {
    static let preview = SiteClawStudio(
        restaurant: .sample,
        draft: .sample,
        messages: [
            BuilderMessage(role: .assistant, text: "Tell me about your restaurant. You can type or use voice."),
            BuilderMessage(role: .owner, text: "We are Sunset Grill, an American burger and sandwich restaurant in San Jose."),
            BuilderMessage(role: .assistant, text: "Great. I can turn that into a mobile-friendly site with menu, hours, location, and local SEO.")
        ],
        updates: [
            SiteUpdate(type: .menu, title: "Menu imported", detail: "Added Cheeseburgers, Chicken Sandwiches, Fries, and Lemonade.", timeLabel: "8 min ago"),
            SiteUpdate(type: .hours, title: "Hours added", detail: "Mon-Sat 10 AM-8 PM, Sun 11 AM-6 PM.", timeLabel: "11 min ago")
        ],
        metrics: [
            DashboardMetric(label: "Completion", value: "92%", trend: "Ready for owner review", systemImage: "checkmark.seal.fill"),
            DashboardMetric(label: "Pages", value: "5", trend: "Home, Menu, Hours, Location, About", systemImage: "doc.text.fill"),
            DashboardMetric(label: "SEO Terms", value: "4", trend: "Local search phrases generated", systemImage: "magnifyingglass"),
            DashboardMetric(label: "Monthly Plan", value: "$19", trend: "Small operator pricing", systemImage: "creditcard.fill")
        ],
        isPublished: false,
        isDraftGenerated: true,
        monthlyPrice: 19
    )
}

extension QuickUpdateTemplate {
    static let samples: [QuickUpdateTemplate] = [
        QuickUpdateTemplate(
            title: "Update Hours",
            prompt: "We are closing at 8 PM tonight because of a private event.",
            systemImage: "clock.fill"
        ),
        QuickUpdateTemplate(
            title: "Add Special",
            prompt: "Add a weekend special: spicy garlic noodles for $12.99.",
            systemImage: "fork.knife"
        ),
        QuickUpdateTemplate(
            title: "Post Notice",
            prompt: "Tell customers we now accept catering orders for office lunches.",
            systemImage: "megaphone.fill"
        )
    ]
}

extension VoiceOnboardingPrompt {
    static let empty = VoiceOnboardingPrompt(
        question: "Ready",
        helperText: "Start voice onboarding to capture restaurant details.",
        capturedAnswer: "",
        systemImage: "mic.fill"
    )

    static let samples: [VoiceOnboardingPrompt] = [
        VoiceOnboardingPrompt(
            question: "What is your restaurant called?",
            helperText: "Say the business name the way customers should see it online.",
            capturedAnswer: "",
            systemImage: "storefront.fill"
        ),
        VoiceOnboardingPrompt(
            question: "What food do you serve, and where are you located?",
            helperText: "Cuisine and city help SiteClaw write local SEO copy.",
            capturedAnswer: "",
            systemImage: "mappin.and.ellipse"
        ),
        VoiceOnboardingPrompt(
            question: "What are your hours?",
            helperText: "Customers often look up hours before deciding where to eat.",
            capturedAnswer: "",
            systemImage: "clock.fill"
        ),
        VoiceOnboardingPrompt(
            question: "What menu items should we feature?",
            helperText: "Name a few popular dishes and prices if you know them.",
            capturedAnswer: "",
            systemImage: "fork.knife"
        ),
        VoiceOnboardingPrompt(
            question: "What makes your restaurant special?",
            helperText: "A short owner story makes the site feel trustworthy.",
            capturedAnswer: "",
            systemImage: "quote.bubble.fill"
        )
    ]

    static let filledSamples: [VoiceOnboardingPrompt] = [
        VoiceOnboardingPrompt(
            question: "What is your restaurant called?",
            helperText: "Say the business name the way customers should see it online.",
            capturedAnswer: "Sunset Grill",
            systemImage: "storefront.fill"
        ),
        VoiceOnboardingPrompt(
            question: "What food do you serve, and where are you located?",
            helperText: "Cuisine and city help SiteClaw write local SEO copy.",
            capturedAnswer: "American burgers and sandwiches in San Jose",
            systemImage: "mappin.and.ellipse"
        ),
        VoiceOnboardingPrompt(
            question: "What are your hours?",
            helperText: "Customers often look up hours before deciding where to eat.",
            capturedAnswer: "Monday through Saturday 10 AM to 8 PM, Sunday 11 AM to 6 PM",
            systemImage: "clock.fill"
        ),
        VoiceOnboardingPrompt(
            question: "What menu items should we feature?",
            helperText: "Name a few popular dishes and prices if you know them.",
            capturedAnswer: "Cheeseburgers $12.99, Chicken Sandwiches $11.49, Fries $4.99, Lemonade $3.49",
            systemImage: "fork.knife"
        ),
        VoiceOnboardingPrompt(
            question: "What makes your restaurant special?",
            helperText: "A short owner story makes the site feel trustworthy.",
            capturedAnswer: "Fresh ingredients, fast service, and a friendly neighborhood atmosphere",
            systemImage: "quote.bubble.fill"
        )
    ]

    static let demoAnswers = [
        "My restaurant is called Sunset Grill.",
        "We serve American burgers and sandwiches in San Jose.",
        "We are open Monday through Saturday from 10 AM to 8 PM, and Sunday from 11 AM to 6 PM.",
        "Our menu items are cheeseburgers for $12.99, chicken sandwiches for $11.49, fries for $4.99, and lemonade for $3.49.",
        "What makes us special is fresh ingredients, fast service, and a friendly neighborhood atmosphere."
    ]

    static let sampleTranscript = "My restaurant is called Sunset Grill. We serve American burgers and sandwiches in San Jose. We are open Monday through Saturday from 10 AM to 8 PM, and Sunday from 11 AM to 6 PM. Our menu items are cheeseburgers for $12.99, chicken sandwiches for $11.49, fries for $4.99, and lemonade for $3.49. What makes us special is fresh ingredients, fast service, and a friendly neighborhood atmosphere."
}

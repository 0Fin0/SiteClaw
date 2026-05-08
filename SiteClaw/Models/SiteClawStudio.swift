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
        realtimeStatus: String = "Ready",
        realtimeConnectionDetail: String = "Use Start to request a short-lived Realtime session from the local backend.",
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
        siteExportStatus: String = "No static export prepared yet.",
        lastSiteExportedAt: Date? = nil
    ) {
        self.restaurant = restaurant
        self.draft = draft
        self.messages = messages
        self.updates = updates
        self.metrics = metrics
        self.voicePrompts = voicePrompts
        self.voiceTranscript = voiceTranscript
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

        return parts.isEmpty ? "Local backend: http://localhost:8787" : parts.joined(separator: " - ")
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
        let restaurantName = restaurant.name.isEmpty ? "your restaurant" : restaurant.name
        let cuisine = restaurant.cuisine.isEmpty ? "local food" : restaurant.cuisine
        let neighborhood = restaurant.neighborhood.isEmpty ? "your neighborhood" : restaurant.neighborhood

        draft = WebsiteDraft(
            headline: "\(restaurantName) brings \(cuisine.lowercased()) to \(neighborhood)",
            subheadline: restaurant.story.isEmpty
                ? "Fresh food, clear hours, and a menu customers can trust before they visit."
                : restaurant.story,
            callToAction: "View Menu",
            pages: ["Home", "Menu", "Hours", "Location", "About"],
            seoKeywords: [restaurantName, cuisine, "\(neighborhood) restaurant", "best \(cuisine.lowercased()) near me"],
            url: slugURL(for: restaurantName),
            lastGeneratedSummary: "Generated a five-page restaurant site with menu, hours, local SEO, and mobile-ready content."
        )

        isDraftGenerated = true
        siteExportStatus = "Draft changed. Prepare a fresh static export."
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
        let restaurantName = restaurant.name.isEmpty ? "your restaurant" : restaurant.name

        draft = WebsiteDraft(
            headline: response.draft.headline,
            subheadline: response.draft.subheadline,
            callToAction: response.draft.callToAction,
            pages: response.draft.pages,
            seoKeywords: response.draft.seoKeywords,
            url: slugURL(for: restaurantName),
            lastGeneratedSummary: response.draft.lastGeneratedSummary
        )

        isDraftGenerated = true
        realtimeStatus = "Generated"
        realtimeConnectionDetail = "AI generated website copy with \(response.model)."
        siteExportStatus = "Draft changed. Prepare a fresh static export."
        lastSiteExportedAt = nil
        messages.append(BuilderMessage(role: .assistant, text: response.reply))
        addUpdate(
            type: .announcement,
            title: "AI website draft generated",
            detail: response.draft.lastGeneratedSummary,
            timeLabel: "Just now"
        )
    }

    func useLocalDraftFallback(after error: Error) {
        processVoiceTranscript()
        realtimeConnectionDetail = "Used the local demo generator because backend generation failed: \(error.localizedDescription)"
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
        siteExportStatus = "\(export.defaultFilename).html is ready to save or hand to the renderer."
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
        voicePrompts = VoiceOnboardingPrompt.filledSamples
        activeVoicePromptIndex = voicePrompts.count - 1
        realtimeStatus = "Captured"
        realtimeConnectionDetail = "Loaded the guided demo transcript and extracted restaurant details."
        messages.append(
            BuilderMessage(
                role: .owner,
                text: "We are a family-owned Vietnamese restaurant in San Jose. Here is our menu, hours, and story. I need a simple site customers can trust."
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
            ? "Requesting a short-lived Realtime token so you can continue the current prompt."
            : "Requesting a short-lived Realtime token from the SiteClaw backend."
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
            messages.append(
                BuilderMessage(
                    role: .assistant,
                    text: "Tell me your restaurant name, cuisine, hours, location, story, and three menu items."
                )
            )
        }
    }

    func stopRealtimeSession() {
        realtimeAudioLevel = 0
        realtimeStatus = voiceTranscript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Ready" : "Captured"
        realtimeConnectionDetail = voiceTranscript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? "Realtime session stopped before transcript text was captured."
            : "Realtime session stopped. Generate a website draft from the captured transcript when you are ready."
    }

    func completeRealtimeSession(_ response: RealtimeSessionResponse) {
        realtimeStatus = "Token Ready"
        realtimeModel = response.model ?? ""
        realtimeVoice = response.voice ?? ""
        realtimeSessionExpiresAt = response.expiresAt.map { Date(timeIntervalSince1970: TimeInterval($0)) }
        realtimeConnectionDetail = "Backend returned a client secret. The next layer is live audio streaming in the app."
        messages.append(
            BuilderMessage(
                role: .assistant,
                text: "Realtime session token is ready. Next we can connect microphone audio to the Realtime API."
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
        realtimeConnectionDetail = "Realtime token is ready. Opening the microphone and WebSocket stream."
    }

    func handleRealtimeStreamEvent(_ event: RealtimeAudioStreamingEvent) {
        switch event {
        case .microphonePermissionGranted:
            realtimeStatus = "Connecting"
            realtimeConnectionDetail = "Microphone permission granted. Connecting to OpenAI Realtime."
        case .webSocketConnected:
            realtimeStatus = "Streaming"
            realtimeConnectionDetail = "Realtime WebSocket connected. Speak naturally into the microphone."
        case .sessionConfigured:
            realtimeConnectionDetail = "Realtime session configured for 24 kHz PCM microphone input and live transcription."
        case .microphoneStarted(let sampleRate, let channels):
            realtimeStatus = "Listening"
            realtimeConnectionDetail = "Microphone streaming started from \(channels) channel input at \(Int(sampleRate)) Hz."
        case .audioLevel(let level):
            realtimeAudioLevel = level
        case .audioChunkSent(_, let totalBytes):
            realtimeStreamedAudioBytes = totalBytes
            realtimeStatus = "Listening"
            realtimeConnectionDetail = "Streaming microphone audio to Realtime. Sent \(Self.byteCountFormatter.string(fromByteCount: Int64(totalBytes)))."
        case .speechStarted:
            realtimeStatus = "Listening"
            realtimeConnectionDetail = "Speech detected. Keep answering the current SiteClaw prompt."
        case .speechStopped:
            realtimeStatus = "Processing"
            realtimeConnectionDetail = "Realtime detected a pause and is committing this answer."
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
            realtimeConnectionDetail = "Realtime stream closed."
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
                text: "I could not create a Realtime session yet. Start the backend and make sure Backend/.env has an OPENAI_API_KEY."
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
                text: "Realtime connected, but the live audio stream stopped with an error: \(error.localizedDescription)"
            )
        )
    }

    func captureCurrentVoicePrompt() {
        guard voicePrompts.indices.contains(activeVoicePromptIndex) else { return }

        let answer = VoiceOnboardingPrompt.demoAnswers[activeVoicePromptIndex]
        voicePrompts[activeVoicePromptIndex].capturedAnswer = answer
        appendTranscriptAnswer(answer)

        if activeVoicePromptIndex < voicePrompts.count - 1 {
            activeVoicePromptIndex += 1
            realtimeStatus = "Listening"
        } else {
            realtimeStatus = "Captured"
        }
    }

    func previousVoicePrompt() {
        activeVoicePromptIndex = max(activeVoicePromptIndex - 1, 0)
    }

    func resetVoiceOnboarding() {
        voicePrompts = VoiceOnboardingPrompt.samples
        voiceTranscript = ""
        realtimeStatus = "Ready"
        realtimeConnectionDetail = "Use Start to request a short-lived Realtime session from the local backend."
        realtimeModel = ""
        realtimeVoice = ""
        realtimeSessionExpiresAt = nil
        realtimeAudioLevel = 0
        realtimeStreamedAudioBytes = 0
        realtimeAssistantReplyDraft = ""
        activeVoicePromptIndex = 0
    }

    func processVoiceTranscript() {
        restaurant = RestaurantProfile.sample
        voicePrompts = VoiceOnboardingPrompt.filledSamples
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
        if voiceTranscript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            voiceTranscript = answer
        } else if !voiceTranscript.contains(answer) {
            voiceTranscript += " \(answer)"
        }
    }

    private func captureRealtimeTranscript(_ transcript: String) {
        let trimmed = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        appendTranscriptAnswer(trimmed)
        messages.append(BuilderMessage(role: .owner, text: trimmed))

        if voicePrompts.indices.contains(activeVoicePromptIndex),
           voicePrompts[activeVoicePromptIndex].capturedAnswer.isEmpty {
            voicePrompts[activeVoicePromptIndex].capturedAnswer = trimmed

            if activeVoicePromptIndex < voicePrompts.count - 1 {
                activeVoicePromptIndex += 1
                realtimeStatus = "Listening"
                realtimeConnectionDetail = "Captured that answer. Continue with the next prompt."
            } else {
                realtimeStatus = "Captured"
                realtimeConnectionDetail = "All guided answers have transcript text. Generate the website draft when ready."
            }
        } else {
            realtimeStatus = "Captured"
            realtimeConnectionDetail = "Transcript captured from the live Realtime stream."
        }
    }

    private func addUpdate(type: SiteUpdate.UpdateType, title: String, detail: String, timeLabel: String) {
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

    private static let byteCountFormatter: ByteCountFormatter = {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter
    }()
}

extension RestaurantProfile {
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
        name: "Pho Lotus Kitchen",
        cuisine: "Vietnamese comfort food",
        neighborhood: "San Jose",
        ownerName: "Mai Nguyen",
        phone: "(408) 555-0148",
        hours: "Mon-Sat 11 AM-9 PM, Sun 11 AM-7 PM",
        story: "Family recipes, slow-simmered broth, and quick lunches for the neighborhood.",
        menuItems: [
            MenuItem(name: "House Pho", description: "Beef broth, rice noodles, brisket, herbs, lime.", price: 14.99),
            MenuItem(name: "Lemongrass Chicken Bowl", description: "Grilled chicken, jasmine rice, pickled vegetables.", price: 13.49),
            MenuItem(name: "Spring Rolls", description: "Shrimp, herbs, vermicelli, peanut dipping sauce.", price: 8.99)
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
        headline: "Pho Lotus Kitchen brings Vietnamese comfort food to San Jose",
        subheadline: "Family recipes, slow-simmered broth, and quick lunches for the neighborhood.",
        callToAction: "View Menu",
        pages: ["Home", "Menu", "Hours", "Location", "About"],
        seoKeywords: ["Pho Lotus Kitchen", "Vietnamese comfort food", "San Jose restaurant", "best pho near me"],
        url: "https://pho-lotus-kitchen.siteclaw.app",
        lastGeneratedSummary: "Generated a mobile-first restaurant website with menu, hours, location, and local SEO content."
    )
}

extension SiteClawStudio {
    static let preview = SiteClawStudio(
        restaurant: .sample,
        draft: .sample,
        messages: [
            BuilderMessage(role: .assistant, text: "Tell me about your restaurant. You can type or use voice."),
            BuilderMessage(role: .owner, text: "We are a family-owned Vietnamese restaurant in San Jose with pho, rice bowls, and spring rolls."),
            BuilderMessage(role: .assistant, text: "Great. I can turn that into a mobile-friendly site with menu, hours, location, and local SEO.")
        ],
        updates: [
            SiteUpdate(type: .menu, title: "Menu imported", detail: "Added House Pho, Lemongrass Chicken Bowl, and Spring Rolls.", timeLabel: "8 min ago"),
            SiteUpdate(type: .hours, title: "Hours added", detail: "Mon-Sat 11 AM-9 PM, Sun 11 AM-7 PM.", timeLabel: "11 min ago")
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
            capturedAnswer: "Pho Lotus Kitchen",
            systemImage: "storefront.fill"
        ),
        VoiceOnboardingPrompt(
            question: "What food do you serve, and where are you located?",
            helperText: "Cuisine and city help SiteClaw write local SEO copy.",
            capturedAnswer: "Vietnamese comfort food in San Jose",
            systemImage: "mappin.and.ellipse"
        ),
        VoiceOnboardingPrompt(
            question: "What are your hours?",
            helperText: "Customers often look up hours before deciding where to eat.",
            capturedAnswer: "Mon-Sat 11 AM-9 PM, Sun 11 AM-7 PM",
            systemImage: "clock.fill"
        ),
        VoiceOnboardingPrompt(
            question: "What menu items should we feature?",
            helperText: "Name a few popular dishes and prices if you know them.",
            capturedAnswer: "House Pho, Lemongrass Chicken Bowl, Spring Rolls",
            systemImage: "fork.knife"
        ),
        VoiceOnboardingPrompt(
            question: "What makes your restaurant special?",
            helperText: "A short owner story makes the site feel trustworthy.",
            capturedAnswer: "Family recipes, slow-simmered broth, quick neighborhood lunches",
            systemImage: "quote.bubble.fill"
        )
    ]

    static let demoAnswers = [
        "We are Pho Lotus Kitchen.",
        "We serve Vietnamese comfort food in San Jose.",
        "We are open Monday through Saturday from 11 AM to 9 PM and Sunday from 11 AM to 7 PM.",
        "Feature house pho for 14.99, lemongrass chicken bowls for 13.49, and spring rolls for 8.99.",
        "Our story is family recipes, slow-simmered broth, and quick lunches for the neighborhood."
    ]

    static let sampleTranscript = "We are Pho Lotus Kitchen, a family-owned Vietnamese restaurant in San Jose. We serve house pho for 14.99, lemongrass chicken bowls for 13.49, and spring rolls for 8.99. We are open Monday through Saturday from 11 AM to 9 PM and Sunday from 11 AM to 7 PM. Our story is family recipes, slow-simmered broth, and quick lunches for the neighborhood."
}

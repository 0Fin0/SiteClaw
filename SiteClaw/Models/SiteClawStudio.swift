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
    var account: SiteClawAccount
    var subscription: SiteClawSubscription
    var gatewayEndpoints: [SiteClawGatewayEndpoint]
    var secretBoundary: [SiteClawSecretBoundary]
    var accountStatus: String
    var billingStatus: String
    var pendingBillingURL: URL?
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
        account: SiteClawAccount = SiteClawMock.account,
        subscription: SiteClawSubscription = SiteClawMock.subscription,
        gatewayEndpoints: [SiteClawGatewayEndpoint] = SiteClawMock.gatewayEndpoints,
        secretBoundary: [SiteClawSecretBoundary] = SiteClawMock.secretBoundary,
        accountStatus: String = "Signed in with local mock auth.",
        billingStatus: String = "Billing is mocked until Stripe checkout routes are wired.",
        pendingBillingURL: URL? = nil,
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
        self.account = account
        self.subscription = subscription
        self.gatewayEndpoints = gatewayEndpoints
        self.secretBoundary = secretBoundary
        self.accountStatus = accountStatus
        self.billingStatus = billingStatus
        self.pendingBillingURL = pendingBillingURL
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

    var accountDisplayName: String {
        if !account.ownerName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return account.ownerName
        }

        if !restaurant.ownerName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return restaurant.ownerName
        }

        return "Restaurant Owner"
    }

    var billingRenewalLabel: String {
        guard let currentPeriodEnd = subscription.currentPeriodEnd else {
            return subscription.plan == .founding ? "No renewal date" : "Renewal not set"
        }

        return currentPeriodEnd.formatted(date: .abbreviated, time: .omitted)
    }

    var canUseCustomerPortal: Bool {
        account.isAuthenticated && subscription.stripeCustomerID != nil
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

    func signInWithMockGateway(email: String, restaurantName: String) async {
        do {
            let gateway = MockSiteClawGateway()
            account = try await gateway.signIn(email: email, restaurantName: restaurantName)
            if restaurant.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                restaurant.name = restaurantName
            }
            accountStatus = "Signed in as \(account.email) with mock gateway auth."
        } catch {
            accountStatus = error.localizedDescription
        }
    }

    func startProductionSignIn(email: String, restaurantName: String) async {
        do {
            let gateway = ProductionSiteClawGateway()
            account = try await gateway.signIn(email: email, restaurantName: restaurantName)
            if restaurant.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                restaurant.name = restaurantName
            }
            accountStatus = "Check your email for the Supabase code, then enter it here to finish live sign-in."
        } catch {
            accountStatus = error.localizedDescription
        }
    }

    func completeProductionSignIn(email: String, token: String, restaurantName: String) async {
        do {
            let gateway = ProductionSiteClawGateway()
            account = try await gateway.verifyEmailOTP(email: email, token: token, restaurantName: restaurantName)
            if restaurant.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                restaurant.name = restaurantName
            }
            accountStatus = "Supabase session verified for \(account.email)."
        } catch {
            accountStatus = error.localizedDescription
        }
    }

    func signOut() {
        account = SiteClawMock.signedOutAccount
        accountStatus = "Signed out locally. Production Supabase session clearing comes next."
    }

    func chooseBillingPlan(_ plan: SiteClawSubscriptionPlan) async {
        do {
            let gateway = MockSiteClawGateway()
            let result = try await gateway.checkout(
                plan: plan,
                currentSubscription: subscription,
                email: account.email
            )
            subscription = result.subscription
            pendingBillingURL = result.checkoutURL
            monthlyPrice = subscription.plan.monthlyPrice
            billingStatus = plan == .founding
                ? "Founding partner access is active with unlimited edits."
                : "\(plan.title) checkout mocked. Stripe will replace this local state."
        } catch {
            billingStatus = error.localizedDescription
        }
    }

    func startProductionCheckout(_ plan: SiteClawSubscriptionPlan) async -> URL? {
        do {
            let gateway = ProductionSiteClawGateway()
            let result = try await gateway.checkout(
                plan: plan,
                currentSubscription: subscription,
                email: account.isAuthenticated ? account.email : nil
            )
            subscription = result.subscription
            pendingBillingURL = result.checkoutURL
            monthlyPrice = plan.monthlyPrice
            billingStatus = result.checkoutURL == nil
                ? "\(plan.title) checkout route responded without a URL."
                : "Opening Stripe Checkout for \(plan.title)."
            return result.checkoutURL
        } catch {
            pendingBillingURL = nil
            billingStatus = error.localizedDescription
            return nil
        }
    }

    func openMockCustomerPortal() async {
        do {
            let gateway = MockSiteClawGateway()
            let portalURL = try await gateway.openCustomerPortal(for: account)
            billingStatus = "Customer portal route ready: \(portalURL)"
        } catch {
            billingStatus = error.localizedDescription
        }
    }

    func startProductionCustomerPortal() async -> URL? {
        do {
            let gateway = ProductionSiteClawGateway()
            let portalURL = try await gateway.openCustomerPortal(for: account)
            billingStatus = "Opening Stripe Customer Portal."
            return URL(string: portalURL)
        } catch {
            billingStatus = error.localizedDescription
            return nil
        }
    }

    func applyGeneratedDraft(_ response: SiteGenerationResponse) {
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

        voiceTranscript = VoiceTranscriptNormalizer.normalize(voiceTranscript)
        let currentPrompt = voicePrompts[activeVoicePromptIndex]

        if let missingDetailKind = currentPrompt.missingDetailKind {
            let answer = voiceTranscript.trimmingCharacters(in: .whitespacesAndNewlines)
            guard applyMissingDetailAnswer(answer, kind: missingDetailKind) else {
                realtimeStatus = "Needs Detail"
                realtimeConnectionDetail = "That answer did not include the detail SiteClaw needs yet."
                return
            }

            voicePrompts[activeVoicePromptIndex].capturedAnswer = answer
            realtimeStatus = missingDetails.isEmpty ? "Ready to Publish" : "Captured"
            realtimeConnectionDetail = nextMissingDetailMessage
            return
        }

        let extraction = TranscriptRestaurantExtractor.extract(from: voiceTranscript)
        let answer = extraction.promptAnswers[activeVoicePromptIndex]
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !answer.isEmpty else {
            realtimeStatus = "Needs Answer"
            realtimeConnectionDetail = "Speak or type an answer before capturing this prompt. Use Demo when you want sample data."
            return
        }

        restaurant = mergeWithExistingProfile(extraction.profile)
        voicePrompts[activeVoicePromptIndex].capturedAnswer = answer

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
        voicePrompts = TranscriptRestaurantExtractor.makePrompts(from: extraction.promptAnswers)
        activeVoicePromptIndex = voicePrompts.firstIndex { $0.capturedAnswer.isEmpty }
            ?? max(voicePrompts.count - 1, 0)
        realtimeStatus = "Captured"
        realtimeConnectionDetail = missingDetails.isEmpty
            ? "Transcript processed and all tracked owner details are captured."
            : "Transcript processed. \(missingDetails.count) detail\(missingDetails.count == 1 ? "" : "s") still need owner input."
        siteExportStatus = "Restaurant details changed. Prepare a fresh static export."
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
            if let missingDetailKind = voicePrompts[activeVoicePromptIndex].missingDetailKind {
                if applyMissingDetailAnswer(trimmed, kind: missingDetailKind) {
                    voicePrompts[activeVoicePromptIndex].capturedAnswer = trimmed
                    realtimeStatus = missingDetails.isEmpty ? "Ready to Publish" : "Captured"
                    realtimeConnectionDetail = nextMissingDetailMessage
                } else {
                    realtimeStatus = "Needs Detail"
                    realtimeConnectionDetail = "I heard that answer, but it did not include the detail SiteClaw needs yet."
                }
                return
            }

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
            siteExportStatus = "Restaurant details changed. Prepare a fresh static export."
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

private struct TranscriptRestaurantExtraction {
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
            .replacingOccurrences(of: #"\bfo lotus\b"#, with: "Pho Lotus", options: [.regularExpression, .caseInsensitive])
            .replacingOccurrences(of: #"\b(?:pha|pah|fa|fah|fu|foo|buh|boh|bo|poh|fuh)\s+lotus\b"#, with: "Pho Lotus", options: [.regularExpression, .caseInsensitive])
            .replacingOccurrences(of: #"\bphone lotus\b"#, with: "Pho Lotus", options: [.regularExpression, .caseInsensitive])
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

private struct AddressExtraction {
    var streetAddress: String = ""
    var city: String = ""
    var state: String = ""
    var postalCode: String = ""
}

private enum MissingDetailAnswerExtractor {
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
        let street = firstMatch(
            #"\b(\d{2,6}\s+[A-Za-z0-9 .'#-]+?\s+(?:Street|St\.?|Avenue|Ave\.?|Road|Rd\.?|Boulevard|Blvd\.?|Drive|Dr\.?|Lane|Ln\.?|Way|Place|Pl\.?|Court|Ct\.?))\b"#,
            in: text
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
        value
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: CharacterSet.whitespacesAndNewlines.union(CharacterSet(charactersIn: ".:;,")))
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

private enum TranscriptRestaurantExtractor {
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

        let cleaned = candidate
            .replacingOccurrences(of: #"\b(?:we are|we're|we)\s+open\b"#, with: "", options: [.regularExpression, .caseInsensitive])
            .replacingOccurrences(of: #"\b(?:hours are|our hours are|open|from)\b"#, with: "", options: [.regularExpression, .caseInsensitive])
            .replacingOccurrences(
                of: #"\s+\b(?:what makes|what make|our story|what is special|makes us special|special is)\b.*$"#,
                with: "",
                options: [.regularExpression, .caseInsensitive]
            )
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return cleaned
    }

    private static func extractMenuItems(from transcript: String) -> [MenuItem] {
        let clauses = allMatches(
            #"\b(?:we serve|we're serving|we are serving|serving|menu items include|our menu has|feature|features)\s+([^.;]+)"#,
            in: transcript
        )

        var seenNames = Set<String>()
        var items: [MenuItem] = []

        for clause in clauses {
            for rawPart in menuParts(from: clause) {
                guard let item = makeMenuItem(from: rawPart) else { continue }
                let key = item.name.lowercased()
                guard !seenNames.contains(key) else { continue }
                seenNames.insert(key)
                items.append(item)
            }
        }

        return Array(items.prefix(8))
    }

    private static func menuParts(from clause: String) -> [String] {
        let cleanedClause = cleanMenuClause(clause)
            .replacingOccurrences(of: #"(?i)\s+and\s+"#, with: ", ", options: .regularExpression)
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
        let knownPhrases: [(phrase: String, canonical: String)] = [
            ("house pho", "House Pho"),
            ("pho", "Pho"),
            ("rice bowls", "Rice Bowls"),
            ("rice bowl", "Rice Bowls"),
            ("spring rolls", "Spring Rolls"),
            ("spring roll", "Spring Rolls"),
            ("iced coffee", "Iced Coffee"),
            ("ice coffee", "Iced Coffee")
        ]

        let matches: [(offset: Int, canonical: String)] = knownPhrases.compactMap { phrase, canonical in
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
        let rejected = ["food", "menu", "dishes", "restaurant", "comfort food"]
        let rejectedFragments = [
            "friendly", "neighborhood", "service", "family recipe", "open ", "monday", "tuesday",
            "wednesday", "thursday", "friday", "saturday", "sunday", "what makes", "special"
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
        guard let match = firstMatch(#"(?:\$|for\s+)(\d+(?:\.\d{1,2})?)"#, in: text),
              let price = Double(match),
              price > 0 else {
            return nil
        }

        return price
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
        name: "Pho Lotus Kitchen",
        cuisine: "Vietnamese comfort food",
        neighborhood: "San Jose",
        ownerName: "Mai Nguyen",
        phone: "",
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

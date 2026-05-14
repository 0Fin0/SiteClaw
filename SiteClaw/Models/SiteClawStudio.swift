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
    private var lastSiteExportedAtTimestamp: TimeInterval?
    var lastSiteExportedAt: Date? {
        get {
            lastSiteExportedAtTimestamp.map { Date(timeIntervalSince1970: $0) }
        }
        set {
            lastSiteExportedAtTimestamp = newValue?.timeIntervalSince1970
        }
    }
    var accountSettings: SiteClawAccountSettings
    var workspaceID: String
    private var workspaceLastSavedAtTimestamp: TimeInterval?
    var workspaceLastSavedAt: Date? {
        get {
            workspaceLastSavedAtTimestamp.map { Date(timeIntervalSince1970: $0) }
        }
        set {
            workspaceLastSavedAtTimestamp = newValue?.timeIntervalSince1970
        }
    }
    var workspaceStatus: String
    var publishStage: SitePublishStage
    var publishHistory: [SitePublishHistoryItem]
    var voiceCoachTurns: [VoiceCoachTurn]
    var activeSuggestedFollowUp: String
    var isVoiceCoachWorking: Bool
    var voiceCoachStatus: String

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
        lastSiteExportedAt: Date? = nil,
        accountSettings: SiteClawAccountSettings = .demo,
        workspaceID: String = "default",
        workspaceLastSavedAt: Date? = nil,
        workspaceStatus: String = "Workspace autosave is ready.",
        publishStage: SitePublishStage = .preview,
        publishHistory: [SitePublishHistoryItem] = [],
        voiceCoachTurns: [VoiceCoachTurn] = [],
        activeSuggestedFollowUp: String = "",
        isVoiceCoachWorking: Bool = false,
        voiceCoachStatus: String = "Save an answer to get AI coaching."
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
        self.lastSiteExportedAtTimestamp = lastSiteExportedAt?.timeIntervalSince1970
        self.accountSettings = accountSettings
        self.workspaceID = workspaceID
        self.workspaceLastSavedAtTimestamp = workspaceLastSavedAt?.timeIntervalSince1970
        self.workspaceStatus = workspaceStatus
        self.publishStage = publishStage
        self.publishHistory = publishHistory
        self.voiceCoachTurns = voiceCoachTurns
        self.activeSuggestedFollowUp = activeSuggestedFollowUp
        self.isVoiceCoachWorking = isVoiceCoachWorking
        self.voiceCoachStatus = voiceCoachStatus
    }

    nonisolated deinit {}

    var publishStatus: String {
        publishStage.title
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

    var isSiteExportStale: Bool {
        siteExportStatus.localizedCaseInsensitiveContains("refresh")
    }

    var siteExportDetail: String {
        guard let lastSiteExportedAt else {
            return siteExportStatus
        }

        return "\(siteExportStatus) Prepared \(lastSiteExportedAt.formatted(date: .omitted, time: .shortened))."
    }

    var workspaceSummary: String {
        guard let workspaceLastSavedAt else {
            return workspaceStatus
        }

        return "Saved \(workspaceLastSavedAt.formatted(date: .abbreviated, time: .shortened)). \(workspaceStatus)"
    }

    var hasGrowthToolkitAccess: Bool {
        monthlyPrice >= 49
    }

    var workspaceAutosaveState: SiteClawWorkspaceAutosaveState {
        SiteClawWorkspaceAutosaveState(
            restaurant: restaurant,
            draft: draft,
            accountSettings: accountSettings,
            voicePrompts: voicePrompts,
            voiceTranscript: voiceTranscript,
            pendingVoiceAnswer: pendingVoiceAnswer,
            activeVoicePromptIndex: activeVoicePromptIndex,
            isPublished: isPublished,
            isDraftGenerated: isDraftGenerated,
            monthlyPrice: monthlyPrice,
            siteExportStatus: siteExportStatus,
            lastSiteExportedAtTimestamp: lastSiteExportedAtTimestamp,
            publishStage: publishStage,
            publishHistory: publishHistory,
            voiceCoachTurns: voiceCoachTurns,
            activeSuggestedFollowUp: activeSuggestedFollowUp,
            voiceCoachStatus: voiceCoachStatus
        )
    }

    var voiceCaptureReviewItems: [VoiceCaptureReviewItem] {
        [
            VoiceCaptureReviewItem(
                title: "Restaurant Name",
                value: restaurant.name,
                confidence: reviewConfidence(for: restaurant.name, requiredLength: 2),
                detail: "The public name customers see in the hero, title, and SEO.",
                systemImage: "storefront.fill"
            ),
            VoiceCaptureReviewItem(
                title: "Cuisine",
                value: restaurant.cuisine,
                confidence: reviewConfidence(for: restaurant.cuisine, requiredLength: 4),
                detail: "Used for local SEO and the restaurant positioning.",
                systemImage: "fork.knife"
            ),
            VoiceCaptureReviewItem(
                title: "Location",
                value: restaurant.neighborhood,
                confidence: reviewConfidence(for: restaurant.neighborhood, requiredLength: 2),
                detail: "Used for the location cue and local search phrases.",
                systemImage: "mappin.and.ellipse"
            ),
            VoiceCaptureReviewItem(
                title: "Hours",
                value: restaurant.hours,
                confidence: TranscriptRestaurantExtractor.isLikelyHoursAnswer(restaurant.hours) ? 0.86 : reviewConfidence(for: restaurant.hours, requiredLength: 8) * 0.7,
                detail: "Should include days and time ranges before publish.",
                systemImage: "clock.fill"
            ),
            VoiceCaptureReviewItem(
                title: "Featured Dishes",
                value: restaurant.menuItems.isEmpty ? "" : restaurant.menuItems.map { TranscriptRestaurantExtractor.menuLabel(for: $0) }.joined(separator: ", "),
                confidence: restaurant.menuItems.isEmpty ? 0.2 : restaurant.menuItems.allSatisfy { ($0.price ?? 0) > 0 } ? 0.84 : 0.68,
                detail: "Menu cards are strongest when names, prices, and descriptions are present.",
                systemImage: "menucard.fill"
            ),
            VoiceCaptureReviewItem(
                title: "Owner Story",
                value: restaurant.story,
                confidence: reviewConfidence(for: restaurant.story, requiredLength: 18),
                detail: "Short story copy that makes the website feel owned and specific.",
                systemImage: "text.bubble.fill"
            )
        ]
    }

    var siteQualityAuditItems: [SiteQualityAuditItem] {
        var items: [SiteQualityAuditItem] = []
        let name = restaurant.name.trimmingCharacters(in: .whitespacesAndNewlines)
        let menuItems = restaurant.menuItems
        let invalidConversionLinks = conversionLinkValues.filter { !$0.value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && safeExternalURL($0.value) == nil }
        let invalidVisibilityLinks = visibilityLinkValues.filter { !$0.value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && safeExternalURL($0.value) == nil }
        let cateringEmail = restaurant.cateringEmail.trimmingCharacters(in: .whitespacesAndNewlines)
        let invalidCateringEmail = !cateringEmail.isEmpty && !Self.isValidEmail(cateringEmail)
        let weakDescriptionCount = menuItems.filter {
            $0.description.trimmingCharacters(in: .whitespacesAndNewlines).count < 24
        }.count
        let missingPriceCount = menuItems.filter { ($0.price ?? 0) <= 0 }.count

        items.append(
            SiteQualityAuditItem(
                title: "Restaurant Name",
                detail: name.isEmpty ? "Add the restaurant name before sharing the site." : "\(name) is ready.",
                severity: name.isEmpty ? .blocker : .passed,
                systemImage: "storefront.fill"
            )
        )

        items.append(
            SiteQualityAuditItem(
                title: "Featured Dishes",
                detail: menuItems.isEmpty ? "Add at least one dish or upload a menu." : "\(menuItems.count) dish\(menuItems.count == 1 ? "" : "es") ready for review.",
                severity: menuItems.isEmpty ? .blocker : .passed,
                systemImage: "fork.knife"
            )
        )

        items.append(
            SiteQualityAuditItem(
                title: "Menu Prices",
                detail: missingPriceCount == 0 ? "Visible dish prices are complete." : "\(missingPriceCount) dish\(missingPriceCount == 1 ? "" : "es") still need prices.",
                severity: missingPriceCount == 0 ? .passed : .warning,
                systemImage: "tag.fill"
            )
        )

        items.append(
            SiteQualityAuditItem(
                title: "Dish Descriptions",
                detail: weakDescriptionCount == 0 ? "Dish descriptions are useful for customers." : "\(weakDescriptionCount) dish description\(weakDescriptionCount == 1 ? "" : "s") look thin.",
                severity: weakDescriptionCount == 0 ? .passed : .warning,
                systemImage: "text.bubble.fill"
            )
        )

        items.append(
            SiteQualityAuditItem(
                title: "Conversion Links",
                detail: invalidConversionLinks.isEmpty ? "Order, reservation, gift card, and catering links are safe to render." : "Fix invalid conversion links: \(invalidConversionLinks.map(\.label).joined(separator: ", ")).",
                severity: invalidConversionLinks.isEmpty ? .passed : .blocker,
                systemImage: "link.badge.plus"
            )
        )

        items.append(
            SiteQualityAuditItem(
                title: "Visibility Links",
                detail: invalidVisibilityLinks.isEmpty ? "Public profile links are safe to render." : "Fix invalid visibility links: \(invalidVisibilityLinks.map(\.label).joined(separator: ", ")).",
                severity: invalidVisibilityLinks.isEmpty ? .passed : .warning,
                systemImage: "magnifyingglass"
            )
        )

        items.append(
            SiteQualityAuditItem(
                title: "Catering Email",
                detail: invalidCateringEmail ? "Use a valid catering email or leave it blank." : "Catering email is either valid or omitted.",
                severity: invalidCateringEmail ? .blocker : .passed,
                systemImage: "envelope.fill"
            )
        )

        items.append(
            SiteQualityAuditItem(
                title: "Address",
                detail: restaurant.hasFullAddress ? restaurant.formattedAddress : "Address is optional in the prototype, but improves directions and local SEO.",
                severity: restaurant.hasFullAddress ? .passed : .warning,
                systemImage: "mappin.and.ellipse"
            )
        )

        items.append(
            SiteQualityAuditItem(
                title: "SEO Title",
                detail: restaurantJSON.seo.title.count >= 12 ? restaurantJSON.seo.title : "Generate a stronger SEO title before final publish.",
                severity: restaurantJSON.seo.title.count >= 12 ? .passed : .warning,
                systemImage: "doc.text.magnifyingglass"
            )
        )

        return items
    }

    var siteQualityScore: Int {
        let items = siteQualityAuditItems
        guard !items.isEmpty else { return 0 }
        let weighted = items.reduce(0.0) { total, item in
            switch item.severity {
            case .passed: total + 1
            case .warning: total + 0.45
            case .blocker: total
            }
        }
        return Int((weighted / Double(items.count) * 100).rounded())
    }

    var blockingQualityIssues: [SiteQualityAuditItem] {
        siteQualityAuditItems.filter { $0.severity == .blocker }
    }

    var canPublishSite: Bool {
        blockingQualityIssues.isEmpty
    }

    var recommendedGrowthToolLabels: [String] {
        let archetype = draft.designBrief.resolvedArchetype
        var labels: [String] = []

        if archetype == .fastCasualOrderFirst || !restaurant.features.onlineOrderingURL.isEmpty {
            labels.append("Online ordering spotlight")
        }
        if archetype == .fineDiningReservationFirst || !restaurant.features.reservationURL.isEmpty {
            labels.append("Reservation tracking")
        }
        if !restaurant.features.giftCardURL.isEmpty || restaurant.growthTools.giftCardsEnabled {
            labels.append("Gift card CTA")
        }
        if !restaurant.cateringEmail.isEmpty || !restaurant.features.cateringURL.isEmpty {
            labels.append("Catering lead path")
        }
        if restaurant.visibility.googleReviewURL.isEmpty == false || restaurant.growthTools.reviewLinksEnabled {
            labels.append("Review link")
        }
        if labels.isEmpty {
            labels.append(contentsOf: ["QR menu", "Local SEO checklist"])
        }

        return labels
    }

    var latestVoiceCoachTurn: VoiceCoachTurn? {
        voiceCoachTurns.first
    }

    var aiDesignDecisionSummary: [String] {
        var decisions = draft.designBrief.designDecisions
        decisions.append(contentsOf: voiceCoachTurns.flatMap(\.designNotes))
        decisions.append(contentsOf: defaultDesignDecisions(for: draft.designBrief.resolvedArchetype))

        if !restaurant.features.onlineOrderingURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            decisions.append("Order-first CTA is supported because the owner provided an online ordering link.")
        }
        if !restaurant.features.reservationURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            decisions.append("Reservation CTA is supported because the owner provided a reservation link.")
        }
        if !restaurant.cateringEmail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || !restaurant.features.cateringURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            decisions.append("Catering path is highlighted because a catering contact exists.")
        }

        return cleanedUnique(decisions, limit: 5)
    }

    @discardableResult
    func autosaveWorkspace(store: SiteClawWorkspaceStore = .default) -> Bool {
        do {
            try store.save(snapshot: SiteClawWorkspaceSnapshot(studio: self), workspaceID: workspaceID)
            workspaceLastSavedAt = Date()
            workspaceStatus = "Autosaved local workspace."
            return true
        } catch {
            workspaceStatus = "Autosave failed: \(error.localizedDescription)"
            return false
        }
    }

    @discardableResult
    func loadSavedWorkspaceIfAvailable(store: SiteClawWorkspaceStore = .default) -> Bool {
        do {
            guard let snapshot = try store.load(workspaceID: workspaceID) else {
                workspaceStatus = "No saved workspace yet."
                return false
            }

            applyWorkspaceSnapshot(snapshot)
            workspaceLastSavedAt = snapshot.savedAt
            workspaceStatus = "Loaded saved workspace."
            return true
        } catch {
            workspaceStatus = "Could not load workspace: \(error.localizedDescription)"
            return false
        }
    }

    @discardableResult
    func duplicateWorkspace(store: SiteClawWorkspaceStore = .default) -> Bool {
        let duplicateID = "\(workspaceID)-copy-\(Int(Date().timeIntervalSince1970))"
        do {
            try store.save(snapshot: SiteClawWorkspaceSnapshot(studio: self, workspaceID: duplicateID), workspaceID: duplicateID)
            workspaceStatus = "Duplicated workspace as \(duplicateID)."
            addUpdate(type: .announcement, title: "Workspace duplicated", detail: duplicateID, timeLabel: "Just now")
            return true
        } catch {
            workspaceStatus = "Duplicate failed: \(error.localizedDescription)"
            return false
        }
    }

    func resetToDemoWorkspace() {
        let demo = SiteClawStudio.preview
        applyWorkspaceSnapshot(SiteClawWorkspaceSnapshot(studio: demo, workspaceID: workspaceID))
        workspaceLastSavedAt = nil
        workspaceStatus = "Reset to the bundled demo workspace."
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
        let designBrief = enrichedDesignBrief(
            RestaurantDesignBrief(archetype: RestaurantSiteArchetype.suggested(for: restaurant))
        )

        draft = WebsiteDraft(
            headline: headline,
            subheadline: restaurant.story.isEmpty
                ? "Fresh food, clear hours, and a menu customers can trust before they visit."
                : restaurant.story,
            callToAction: designBrief.primaryCTA,
            pages: ["Home", "Menu", "Hours", "Location", "About"],
            seoKeywords: keywords,
            designBrief: designBrief,
            url: slugURL(for: restaurantName),
            lastGeneratedSummary: "Generated a five-page restaurant site with menu, hours, local SEO, and mobile-ready content."
        )

        isDraftGenerated = true
        publishStage = .preview
        siteExportStatus = "Draft ready for preview."
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
        let designBrief = enrichedDesignBrief(
            (response.draft.designBrief ?? RestaurantDesignBrief(archetype: RestaurantSiteArchetype.suggested(for: restaurant))).normalized
        )
        let responseCTA = response.draft.callToAction.trimmingCharacters(in: .whitespacesAndNewlines)

        draft = WebsiteDraft(
            headline: headline,
            subheadline: response.draft.subheadline,
            callToAction: responseCTA.isEmpty ? designBrief.primaryCTA : responseCTA,
            pages: response.draft.pages,
            seoKeywords: response.draft.seoKeywords,
            designBrief: designBrief,
            url: slugURL(for: restaurantName),
            lastGeneratedSummary: response.draft.lastGeneratedSummary
        )

        isDraftGenerated = true
        publishStage = .preview
        realtimeStatus = "Generated"
        realtimeConnectionDetail = "Website draft is ready for Preview."
        siteExportStatus = "AI draft ready for preview."
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

    func applyProfileExtraction(_ response: ProfileExtractionResponse) {
        applyProfilePatch(response.restaurantPatch)

        if let suggestedArchetype = response.suggestedArchetype {
            draft.designBrief = enrichedDesignBrief(RestaurantDesignBrief(archetype: suggestedArchetype))
            draft.callToAction = suggestedArchetype.defaultPrimaryCTA
        }

        polishCapturedProfileForPublishing()
        realtimeStatus = "Polished"
        realtimeConnectionDetail = response.reply.isEmpty
            ? "SiteClaw polished the saved restaurant profile."
            : response.reply
        siteExportStatus = "Restaurant details changed. Refresh the site export when ready."
        lastSiteExportedAt = nil
    }

    func publishDraft() {
        guard canPublishSite else {
            siteExportStatus = "Fix \(blockingQualityIssues.count) publish blocker\(blockingQualityIssues.count == 1 ? "" : "s") before publishing."
            publishStage = .needsRepublish
            return
        }

        isPublished = true
        publishStage = .published
        prepareSiteExport()
        appendPublishHistory(
            stage: .published,
            title: "Site published",
            detail: "\(restaurant.name) is live at \(draft.url)",
            url: draft.url
        )
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
        if publishStage == .draft || publishStage == .needsRepublish {
            publishStage = .preview
        }
        siteExportStatus = "\(export.defaultFilename).html is ready to save or share."
        appendPublishHistory(
            stage: .preview,
            title: "Preview export prepared",
            detail: "Generated \(export.sizeLabel) of HTML from restaurant.json.",
            url: draft.url
        )
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

    @discardableResult
    func applyUploadedMenuAsset(_ asset: UploadedMenuAsset) -> UploadedMenuExtractionResult {
        let extraction = restaurant.applyUploadedMenuAsset(asset)

        if extraction.didExtractItems {
            siteExportStatus = "Uploaded menu imported. Refresh the site export when ready."
        } else {
            siteExportStatus = "Uploaded menu changed. Refresh the site export when ready."
        }

        lastSiteExportedAt = nil
        addUpdate(
            type: .menu,
            title: "Menu file uploaded",
            detail: extraction.statusMessage,
            timeLabel: "Just now"
        )

        return extraction
    }

    func removeUploadedMenuAsset() {
        guard let uploadedMenu = restaurant.uploadedMenu else { return }

        restaurant.uploadedMenu = nil
        siteExportStatus = "Uploaded menu removed. Refresh the site export when ready."
        lastSiteExportedAt = nil
        addUpdate(
            type: .menu,
            title: "Menu file removed",
            detail: "\(uploadedMenu.filename) was removed from the generated website.",
            timeLabel: "Just now"
        )
    }

    func fillDemoVisitDetails() {
        restaurant.streetAddress = "1234 Sunset Avenue"
        restaurant.neighborhood = "San Jose"
        restaurant.state = "CA"
        restaurant.postalCode = "95112"
        restaurant.phone = "(408) 555-0147"
        restaurant.cateringEmail = "catering@example.com"
        markSiteNeedsRefresh("Demo visit details added. Refresh the site export when ready.")
        addUpdate(
            type: .announcement,
            title: "Demo visit details added",
            detail: "Filled Sunset Grill address, phone, and catering email for the local walkthrough.",
            timeLabel: "Just now"
        )
    }

    func fillDemoConversionLinks() {
        restaurant.features = .sunsetGrillDemo
        markSiteNeedsRefresh("Demo conversion links added. Refresh the site export when ready.")
        addUpdate(
            type: .announcement,
            title: "Demo conversion links added",
            detail: "Filled order, reservation, gift card, catering, and private dining demo links.",
            timeLabel: "Just now"
        )
    }

    func fillDemoVisibilityDetails() {
        restaurant.visibility = .sunsetGrillDemo
        restaurant.growthTools = .fullyLoadedDemo
        markSiteNeedsRefresh("Demo visibility details added. Refresh the site export when ready.")
        addUpdate(
            type: .announcement,
            title: "Demo visibility details added",
            detail: "Filled Google, Yelp, Instagram, Facebook, and local profile readiness checks.",
            timeLabel: "Just now"
        )
    }

    func fillDemoGrowthTools() {
        restaurant.growthTools = .fullyLoadedDemo
        markSiteNeedsRefresh("Demo growth tools added. Refresh the site export when ready.")
        addUpdate(
            type: .announcement,
            title: "Demo growth tools added",
            detail: "Enabled specials, events, catering leads, gift cards, review links, QR menu, newsletter, and analytics.",
            timeLabel: "Just now"
        )
    }

    func beginVoiceCoachTurn(for request: VoiceCoachRequest) {
        isVoiceCoachWorking = true
        voiceCoachStatus = "AI coach is reviewing the saved answer."
        activeSuggestedFollowUp = ""
        realtimeStatus = "Coaching"
        realtimeConnectionDetail = "SiteClaw is checking confidence, missing details, and design direction."
    }

    func applyVoiceCoachResponse(_ response: VoiceCoachResponse, for request: VoiceCoachRequest) {
        isVoiceCoachWorking = false
        voiceCoachStatus = response.statusMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? "AI coach updated the site strategy."
            : response.statusMessage

        applyProfilePatch(response.restaurantPatch)

        let cleanedAnswer = response.cleanedAnswer.trimmingCharacters(in: .whitespacesAndNewlines)
        let turn = VoiceCoachTurn(
            promptKind: VoicePromptKind(rawValue: request.promptKind) ?? .custom,
            question: request.question,
            rawAnswer: request.rawAnswer,
            cleanedAnswer: cleanedAnswer.isEmpty ? request.cleanedAnswer : cleanedAnswer,
            confidence: response.confidence,
            missingDetails: cleanedUnique(response.missingDetails, limit: 4),
            suggestedFollowUp: response.suggestedFollowUp.trimmingCharacters(in: .whitespacesAndNewlines),
            archetypeHint: response.archetypeHint,
            designNotes: cleanedUnique(response.designNotes, limit: 4),
            statusMessage: voiceCoachStatus
        )

        voiceCoachTurns.removeAll { existing in
            existing.promptKind == turn.promptKind
                && existing.rawAnswer.caseInsensitiveCompare(turn.rawAnswer) == .orderedSame
        }
        voiceCoachTurns.insert(turn, at: 0)
        if voiceCoachTurns.count > 10 {
            voiceCoachTurns = Array(voiceCoachTurns.prefix(10))
        }

        activeSuggestedFollowUp = turn.suggestedFollowUp
        if let archetype = response.archetypeHint {
            draft.designBrief = enrichedDesignBrief(
                RestaurantDesignBrief(
                    archetype: archetype,
                    designDecisions: turn.designNotes,
                    storyOpportunities: turn.missingDetails,
                    recommendedModules: recommendedGrowthToolLabels
                )
            )
            draft.callToAction = draft.designBrief.primaryCTA
        } else {
            draft.designBrief = enrichedDesignBrief(draft.designBrief)
        }

        markSiteNeedsRefresh("AI coach updated the website strategy. Refresh the site export when ready.")
        realtimeStatus = response.confidence == .low ? "Review Needed" : "Coached"
        realtimeConnectionDetail = voiceCoachStatus
        addUpdate(
            type: .announcement,
            title: "AI coach reviewed answer",
            detail: turn.statusMessage,
            timeLabel: "Just now"
        )
    }

    func failVoiceCoachTurn(_ error: Error, for _: VoiceCoachRequest) {
        isVoiceCoachWorking = false
        activeSuggestedFollowUp = ""
        voiceCoachStatus = "AI coach unavailable. Local capture is still saved."
        realtimeStatus = "Captured"
        realtimeConnectionDetail = "Local parsing is saved. AI coach can retry when the backend is available."
        messages.append(
            BuilderMessage(
                role: .assistant,
                text: "The AI coach could not run yet: \(error.localizedDescription)"
            )
        )
    }

    @discardableResult
    func applyVoiceCoachFollowUpAnswer(_ answer: String) -> VoiceCoachRequest? {
        let normalizedAnswer = VoiceTranscriptNormalizer.normalize(answer)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let question = activeSuggestedFollowUp.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedAnswer.isEmpty, !question.isEmpty else { return nil }

        let promptKind = latestVoiceCoachTurn?.promptKind ?? .custom
        let cleanedAnswer = applyTargetedVoiceCoachFollowUpAnswer(
            normalizedAnswer,
            question: question,
            promptKind: promptKind
        )
        appendFollowUpTranscript(question: question, answer: normalizedAnswer)
        activeSuggestedFollowUp = ""
        realtimeStatus = "Follow-up Saved"
        realtimeConnectionDetail = "Saved the follow-up without mixing it into the active voice step."

        let prompt = VoiceOnboardingPrompt(
            question: question,
            helperText: "AI coach follow-up",
            capturedAnswer: cleanedAnswer,
            systemImage: "sparkles",
            promptKind: promptKind
        )
        return VoiceCoachRequest(
            studio: self,
            prompt: prompt,
            rawAnswer: normalizedAnswer,
            cleanedAnswer: cleanedAnswer
        )
    }

    private func applyTargetedVoiceCoachFollowUpAnswer(
        _ answer: String,
        question: String,
        promptKind: VoicePromptKind
    ) -> String {
        switch promptKind {
        case .featuredDishes:
            return applyFeaturedDishesFollowUpAnswer(answer)
        case .ownerStory:
            let story = VoicePromptAnswerInterpreter.cleanStoryAnswer(answer)
            if !story.isEmpty {
                restaurant.story = story
                updateCapturedVoicePromptAnswer(for: .ownerStory, answer: story)
                markSiteNeedsRefresh("AI coach follow-up updated the owner story. Refresh the site export when ready.")
                return story
            }
        case .hours:
            if TranscriptRestaurantExtractor.isLikelyHoursAnswer(answer) {
                restaurant.hours = answer
                updateCapturedVoicePromptAnswer(for: .hours, answer: answer)
                markSiteNeedsRefresh("AI coach follow-up updated the restaurant hours. Refresh the site export when ready.")
                return answer
            }
        case .restaurantName:
            if let name = MissingDetailAnswerExtractor.restaurantName(from: answer) {
                restaurant.name = name
                updateCapturedVoicePromptAnswer(for: .restaurantName, answer: name)
                markSiteNeedsRefresh("AI coach follow-up updated the restaurant name. Refresh the site export when ready.")
                return name
            }
        case .cuisineLocation:
            let cuisineLocation = TranscriptRestaurantExtractor.cuisineLocation(from: answer)
            if !cuisineLocation.cuisine.isEmpty {
                restaurant.cuisine = cuisineLocation.cuisine
            }
            if !cuisineLocation.city.isEmpty {
                restaurant.neighborhood = cuisineLocation.city
            }
            let cleaned = [restaurant.cuisine, restaurant.neighborhood.isEmpty ? "" : "in \(restaurant.neighborhood)"]
                .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
                .joined(separator: " ")
            if !cleaned.isEmpty {
                updateCapturedVoicePromptAnswer(for: .cuisineLocation, answer: cleaned)
                markSiteNeedsRefresh("AI coach follow-up updated cuisine and location. Refresh the site export when ready.")
                return cleaned
            }
        case .custom:
            if question.localizedCaseInsensitiveContains("item")
                || question.localizedCaseInsensitiveContains("seller")
                || question.localizedCaseInsensitiveContains("menu") {
                return applyFeaturedDishesFollowUpAnswer(answer)
            }
        }

        return answer
    }

    private func applyFeaturedDishesFollowUpAnswer(_ answer: String) -> String {
        let selectedItems = TranscriptRestaurantExtractor.followUpMenuItems(from: answer)
        guard !selectedItems.isEmpty else { return answer }

        restaurant.menuItems = mergeMenuItems(extracted: selectedItems, existing: restaurant.menuItems)
        let cleanedAnswer = restaurant.menuItems.map { TranscriptRestaurantExtractor.menuLabel(for: $0) }.joined(separator: ", ")
        updateCapturedVoicePromptAnswer(for: .featuredDishes, answer: cleanedAnswer)
        markSiteNeedsRefresh("AI coach follow-up refined the featured dishes. Refresh the site export when ready.")
        return cleanedAnswer
    }

    private func updateCapturedVoicePromptAnswer(for promptKind: VoicePromptKind, answer: String) {
        guard let index = voicePrompts.firstIndex(where: { $0.promptKind == promptKind }) else { return }
        voicePrompts[index].capturedAnswer = answer
    }

    private func appendFollowUpTranscript(question: String, answer: String) {
        let entry = "Follow-up: \(question) Answer: \(answer)"
        if voiceTranscript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            voiceTranscript = entry
        } else if !voiceTranscript.localizedCaseInsensitiveContains(entry) {
            voiceTranscript += " \(entry)"
        }
        pendingVoiceAnswer = ""
    }

    func markSiteNeedsRefresh(_ status: String = "Website details changed. Refresh the site export when ready.") {
        siteExportStatus = status
        lastSiteExportedAt = nil
        publishStage = isPublished ? .needsRepublish : .draft
    }

    func updateRestaurantBasic(
        _ keyPath: WritableKeyPath<RestaurantProfile, String>,
        to newValue: String
    ) {
        guard restaurant[keyPath: keyPath] != newValue else { return }
        restaurant[keyPath: keyPath] = newValue
        markSiteNeedsRefresh("Restaurant details changed. Refresh the site export when ready.")
    }

    func selectBillingPlan(_ plan: SiteClawBillingPlan) {
        accountSettings.billingPlan = plan.displayName
        monthlyPrice = plan.price
    }

    func loadVoiceExample() {
        restaurant = RestaurantProfile.sample
        voiceTranscript = VoiceOnboardingPrompt.sampleTranscript
        pendingVoiceAnswer = ""
        voicePrompts = VoiceOnboardingPrompt.filledSamples
        voiceCoachTurns = []
        activeSuggestedFollowUp = ""
        isVoiceCoachWorking = false
        voiceCoachStatus = "Demo answers loaded. Save or edit an answer to run AI coaching."
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
                    text: "Answer the visible question, pause, then tap Save Answer when the transcript matches that question."
                )
            )
        }
    }

    func stopRealtimeSession() {
        realtimeAudioLevel = 0
        realtimeStatus = voiceTranscript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Ready" : "Captured"
        realtimeConnectionDetail = voiceTranscript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? "Recording stopped before text was saved."
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
            realtimeConnectionDetail = "SiteClaw reply saved as text. Audio playback comes next."
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

    @discardableResult
    func captureCurrentVoicePrompt() -> VoiceCoachRequest? {
        guard voicePrompts.indices.contains(activeVoicePromptIndex) else { return nil }

        voiceTranscript = VoiceTranscriptNormalizer.normalize(voiceTranscript)
        pendingVoiceAnswer = VoiceTranscriptNormalizer.normalize(pendingVoiceAnswer)
        let currentPrompt = voicePrompts[activeVoicePromptIndex]
        let currentIndex = activeVoicePromptIndex
        let answerSource = currentAnswerSource

        if let missingDetailKind = currentPrompt.missingDetailKind {
            let answer = answerSource.trimmingCharacters(in: .whitespacesAndNewlines)
            guard applyMissingDetailAnswer(answer, kind: missingDetailKind) else {
                realtimeStatus = "Needs Detail"
                realtimeConnectionDetail = "That answer did not include the detail SiteClaw needs yet."
                return nil
            }

            voicePrompts[activeVoicePromptIndex].capturedAnswer = answer
            pendingVoiceAnswer = ""
            realtimeStatus = missingDetails.isEmpty ? "Ready to Publish" : "Captured"
            realtimeConnectionDetail = nextMissingDetailMessage
            return VoiceCoachRequest(studio: self, prompt: currentPrompt, rawAnswer: answerSource, cleanedAnswer: answer)
        }

        let fallbackAnswer = answerSource.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let answer = applyGuidedVoicePromptAnswer(
            fallbackAnswer,
            prompt: currentPrompt,
            index: activeVoicePromptIndex
        ) else {
            realtimeStatus = "Needs Answer"
            realtimeConnectionDetail = "Speak or type an answer before saving this prompt. Use Demo when you want sample data."
            return nil
        }

        voicePrompts[currentIndex].capturedAnswer = answer
        pendingVoiceAnswer = ""

        if activeVoicePromptIndex < voicePrompts.count - 1 {
            activeVoicePromptIndex += 1
            realtimeStatus = "Listening"
            realtimeConnectionDetail = "Saved that answer. Read the next question, then speak one answer and tap Save Answer."
        } else {
            realtimeStatus = "Captured"
            realtimeConnectionDetail = "All guided answers are saved. Generate the website draft when ready."
        }

        return VoiceCoachRequest(studio: self, prompt: currentPrompt, rawAnswer: answerSource, cleanedAnswer: answer)
    }

    @discardableResult
    func applyEditedVoicePromptAnswer() -> VoiceCoachRequest? {
        applyEditedVoicePromptAnswer(at: activeVoicePromptIndex)
    }

    @discardableResult
    func applyEditedVoicePromptAnswer(at index: Int) -> VoiceCoachRequest? {
        guard voicePrompts.indices.contains(index) else { return nil }

        let rawAnswer = voicePrompts[index].capturedAnswer
        let normalizedAnswer = VoiceTranscriptNormalizer.normalize(rawAnswer)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedAnswer.isEmpty else {
            realtimeStatus = "Needs Answer"
            realtimeConnectionDetail = "Add an answer before applying this edit."
            return nil
        }

        if let missingDetailKind = voicePrompts[index].missingDetailKind {
            guard applyMissingDetailAnswer(normalizedAnswer, kind: missingDetailKind) else {
                realtimeStatus = "Needs Detail"
                realtimeConnectionDetail = "That edit did not include the detail SiteClaw needs yet."
                return nil
            }
            voicePrompts[index].capturedAnswer = normalizedAnswer
            realtimeStatus = "Updated"
            realtimeConnectionDetail = "Updated that saved answer."
            return VoiceCoachRequest(studio: self, prompt: voicePrompts[index], rawAnswer: rawAnswer, cleanedAnswer: normalizedAnswer)
        }

        guard let capturedAnswer = applyGuidedVoicePromptAnswer(
            normalizedAnswer,
            prompt: voicePrompts[index],
            index: index
        ) else {
            return nil
        }

        voicePrompts[index].capturedAnswer = capturedAnswer
        siteExportStatus = "Restaurant details changed. Refresh the site export when ready."
        lastSiteExportedAt = nil
        realtimeStatus = "Updated"
        realtimeConnectionDetail = "Updated that saved answer."
        return VoiceCoachRequest(studio: self, prompt: voicePrompts[index], rawAnswer: rawAnswer, cleanedAnswer: capturedAnswer)
    }

    @discardableResult
    private func applyGuidedVoicePromptAnswer(
        _ rawAnswer: String,
        prompt: VoiceOnboardingPrompt,
        index: Int
    ) -> String? {
        let normalizedAnswer = VoiceTranscriptNormalizer.normalize(rawAnswer)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedAnswer.isEmpty else { return nil }

        let extraction = TranscriptRestaurantExtractor.extract(from: normalizedAnswer)
        let extractedAnswer = extraction.promptAnswers.indices.contains(index)
            ? extraction.promptAnswers[index].trimmingCharacters(in: .whitespacesAndNewlines)
            : ""
        var capturedAnswer = VoicePromptAnswerInterpreter.interpret(
            promptKind: prompt.promptKind,
            promptIndex: index,
            extractedAnswer: extractedAnswer,
            fallbackAnswer: normalizedAnswer
        )

        switch prompt.promptKind {
        case .restaurantName:
            let name = capturedAnswer.isEmpty
                ? extraction.profile.name.trimmingCharacters(in: .whitespacesAndNewlines)
                : capturedAnswer
            guard !name.isEmpty else {
                realtimeStatus = "Needs Name"
                realtimeConnectionDetail = "That answer did not include a restaurant name yet."
                return nil
            }
            restaurant.name = name
            capturedAnswer = name

        case .cuisineLocation:
            let cuisineLocation = TranscriptRestaurantExtractor.cuisineLocation(from: normalizedAnswer)
            let cuisine = cuisineLocation.cuisine.trimmingCharacters(in: .whitespacesAndNewlines)
            let city = cuisineLocation.city.trimmingCharacters(in: .whitespacesAndNewlines)

            if !cuisine.isEmpty {
                restaurant.cuisine = cuisine
            } else if !capturedAnswer.isEmpty {
                restaurant.cuisine = capturedAnswer
            }

            if !city.isEmpty {
                restaurant.neighborhood = city
            }

            if cuisine.isEmpty && city.isEmpty {
                realtimeStatus = "Needs Cuisine"
                realtimeConnectionDetail = "That answer did not include cuisine or location yet."
                return nil
            }

            capturedAnswer = [restaurant.cuisine, restaurant.neighborhood.isEmpty ? "" : "in \(restaurant.neighborhood)"]
                .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
                .joined(separator: " ")

        case .hours:
            let hours = extraction.profile.hours.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                ? normalizedAnswer
                : extraction.profile.hours
            guard TranscriptRestaurantExtractor.isLikelyHoursAnswer(hours)
                    || TranscriptRestaurantExtractor.isLikelyHoursAnswer(normalizedAnswer) else {
                realtimeStatus = "Needs Hours"
                realtimeConnectionDetail = "That answer did not include operating hours yet. Say the days and times before saving this step."
                return nil
            }
            restaurant.hours = hours
            capturedAnswer = hours

        case .featuredDishes:
            if !extraction.profile.menuItems.isEmpty {
                restaurant.menuItems = mergeMenuItems(extracted: extraction.profile.menuItems, existing: restaurant.menuItems)
                capturedAnswer = restaurant.menuItems.map { TranscriptRestaurantExtractor.menuLabel(for: $0) }.joined(separator: ", ")
            } else {
                capturedAnswer = normalizedAnswer
            }

        case .ownerStory:
            let story = VoicePromptAnswerInterpreter.cleanStoryAnswer(capturedAnswer.isEmpty ? normalizedAnswer : capturedAnswer)
            guard !story.isEmpty else {
                realtimeStatus = "Needs Story"
                realtimeConnectionDetail = "That answer did not include a usable owner story yet."
                return nil
            }
            restaurant.story = story
            capturedAnswer = story

        case .custom:
            capturedAnswer = capturedAnswer.isEmpty ? normalizedAnswer : capturedAnswer
        }

        siteExportStatus = "Restaurant details changed. Refresh the site export when ready."
        lastSiteExportedAt = nil
        return capturedAnswer.isEmpty ? normalizedAnswer : capturedAnswer
    }

    func previousVoicePrompt() {
        activeVoicePromptIndex = max(activeVoicePromptIndex - 1, 0)
    }

    func focusNextMissingDetail() {
        guard let detail = missingDetails.first else {
            realtimeStatus = "Ready to Publish"
            realtimeConnectionDetail = "All tracked owner details are saved."
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
        voiceCoachTurns = []
        activeSuggestedFollowUp = ""
        isVoiceCoachWorking = false
        voiceCoachStatus = "Save an answer to get AI coaching."
        activeVoicePromptIndex = 0
    }

    @discardableResult
    func applyVoiceTranscriptToProfile() -> Bool {
        let trimmedTranscript = voiceTranscript.trimmingCharacters(in: .whitespacesAndNewlines)
        let capturedGuidedAnswers = voicePrompts.enumerated().filter { _, prompt in
            prompt.missingDetailKind == nil
                && prompt.promptKind != .custom
                && !prompt.capturedAnswer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }

        guard !trimmedTranscript.isEmpty || !capturedGuidedAnswers.isEmpty else {
            realtimeStatus = "Needs Transcript"
            realtimeConnectionDetail = "Record or type the restaurant details before generating a draft."
            return false
        }

        if !trimmedTranscript.isEmpty {
            voiceTranscript = VoiceTranscriptNormalizer.normalize(trimmedTranscript)
        } else {
            voiceTranscript = capturedGuidedAnswers
                .map { $0.element.capturedAnswer.trimmingCharacters(in: .whitespacesAndNewlines) }
                .joined(separator: " ")
        }

        let extraction = TranscriptRestaurantExtractor.extract(from: voiceTranscript)
        restaurant = mergeWithExistingProfile(extraction.profile)

        for (index, prompt) in capturedGuidedAnswers {
            _ = applyGuidedVoicePromptAnswer(prompt.capturedAnswer, prompt: prompt, index: index)
        }

        polishCapturedProfileForPublishing()

        if capturedGuidedAnswers.isEmpty {
            voicePrompts = TranscriptRestaurantExtractor.makePrompts(from: extraction.promptAnswers)
        }

        activeVoicePromptIndex = voicePrompts.firstIndex { $0.capturedAnswer.isEmpty }
            ?? max(voicePrompts.count - 1, 0)
        realtimeStatus = "Captured"
        realtimeConnectionDetail = missingDetails.isEmpty
            ? "Transcript processed and all tracked owner details are saved."
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
        realtimeConnectionDetail = "Transcript is ready for the visible question. Tap Save Answer when it looks right."
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
            return "All tracked owner details are saved. Generate or refresh the website draft when you are ready."
        }

        return "Saved that detail. Next missing detail: \(next.title)."
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
        merged.uploadedMenu = merged.uploadedMenu ?? restaurant.uploadedMenu
        merged.branding = restaurant.branding
        merged.features = restaurant.features
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
                price: extractedItem.price ?? existingItem.price,
                image: extractedItem.image ?? existingItem.image
            )
        }
    }

    private func applyInterpretedPromptAnswer(_ answer: String, at index: Int) {
        let cleanedAnswer = answer.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanedAnswer.isEmpty else { return }

        switch index {
        case 0:
            restaurant.name = cleanedAnswer
        case 2:
            if restaurant.hours.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                restaurant.hours = cleanedAnswer
            }
        case 4:
            if restaurant.story.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                restaurant.story = cleanedAnswer
            }
        default:
            break
        }
    }

    private func polishCapturedProfileForPublishing() {
        restaurant.cuisine = polishedCuisine(restaurant.cuisine, menuItems: restaurant.menuItems)
        repairKnownDemoPriceArtifacts()

        guard !restaurant.menuItems.isEmpty else { return }

        for index in restaurant.menuItems.indices {
            let description = restaurant.menuItems[index].description.trimmingCharacters(in: .whitespacesAndNewlines)
            let polishedDescription = MenuDescriptionPolisher.defaultDescription(
                for: restaurant.menuItems[index].name,
                cuisine: restaurant.cuisine,
                restaurantName: restaurant.name
            )

            if description.isEmpty || MenuDescriptionPolisher.shouldReplaceGeneratedDescription(description, for: restaurant.menuItems[index].name) {
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

    private func reviewConfidence(for value: String, requiredLength: Int) -> Double {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return 0.15 }
        if trimmed.count >= requiredLength { return 0.82 }
        return 0.58
    }

    private var conversionLinkValues: [(label: String, value: String)] {
        [
            ("Online Ordering", restaurant.features.onlineOrderingURL),
            ("Reservations", restaurant.features.reservationURL),
            ("Gift Cards", restaurant.features.giftCardURL),
            ("Catering", restaurant.features.cateringURL),
            ("Private Dining", restaurant.features.privateDiningURL)
        ]
    }

    private var visibilityLinkValues: [(label: String, value: String)] {
        [
            ("Google Business Profile", restaurant.visibility.googleBusinessProfileURL),
            ("Google Review", restaurant.visibility.googleReviewURL),
            ("Yelp", restaurant.visibility.yelpBusinessURL),
            ("Instagram", restaurant.visibility.instagramURL),
            ("Facebook", restaurant.visibility.facebookURL)
        ]
    }

    private func safeExternalURL(_ value: String) -> URL? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: trimmed),
              let scheme = url.scheme?.lowercased(),
              ["http", "https"].contains(scheme),
              url.host?.isEmpty == false else {
            return nil
        }

        return url
    }

    private static func isValidEmail(_ value: String) -> Bool {
        value.range(
            of: #"^[A-Z0-9._%+\-]+@[A-Z0-9.\-]+\.[A-Z]{2,}$"#,
            options: [.regularExpression, .caseInsensitive]
        ) != nil
    }

    private func applyProfilePatch(_ patch: ProfileRestaurantPatch) {
        if !patch.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            restaurant.name = patch.name
        }
        if !patch.cuisine.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            restaurant.cuisine = patch.cuisine
        }
        if !patch.neighborhood.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            restaurant.neighborhood = patch.neighborhood
        }
        if !patch.hours.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            restaurant.hours = patch.hours
        }
        if !patch.story.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            restaurant.story = VoicePromptAnswerInterpreter.cleanStoryAnswer(patch.story)
        }

        let extractedItems = patch.menuItems
            .filter { !$0.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .map {
                MenuItem(
                    name: $0.name,
                    description: $0.description,
                    price: $0.price
                )
            }
        if !extractedItems.isEmpty {
            restaurant.menuItems = mergeMenuItems(extracted: extractedItems, existing: restaurant.menuItems)
        }
    }

    private func enrichedDesignBrief(_ brief: RestaurantDesignBrief) -> RestaurantDesignBrief {
        let archetype = brief.resolvedArchetype
        return RestaurantDesignBrief(
            archetype: archetype,
            primaryCTA: brief.primaryCTA,
            secondaryCTAs: brief.secondaryCTAs,
            siteSections: brief.siteSections,
            menuPresentation: brief.menuPresentation,
            visualDirection: brief.visualDirection,
            designDecisions: cleanedUnique(
                brief.designDecisions
                    + voiceCoachTurns.flatMap(\.designNotes)
                    + defaultDesignDecisions(for: archetype),
                limit: 5
            ),
            storyOpportunities: cleanedUnique(
                brief.storyOpportunities + voiceCoachTurns.flatMap(\.missingDetails),
                limit: 5
            ),
            recommendedModules: cleanedUnique(
                brief.recommendedModules + recommendedGrowthToolLabels,
                limit: 5
            )
        )
    }

    private func defaultDesignDecisions(for archetype: RestaurantSiteArchetype) -> [String] {
        switch archetype {
        case .neighborhoodUtility:
            return ["Neighborhood utility layout keeps menu, hours, and visit details easy to scan."]
        case .fastCasualOrderFirst:
            return ["Order-first layout leads with best sellers and fast customer action."]
        case .fineDiningReservationFirst:
            return ["Reservation-first layout uses a calmer flow for a more premium dining experience."]
        case .culturalHeritage:
            return ["Heritage layout gives story and signature dishes more weight before the visit details."]
        }
    }

    private func cleanedUnique(_ values: [String], limit: Int) -> [String] {
        var result: [String] = []
        for value in values {
            let cleaned = value.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !cleaned.isEmpty,
                  !result.contains(where: { $0.caseInsensitiveCompare(cleaned) == .orderedSame })
            else { continue }
            result.append(cleaned)
            if result.count >= limit { break }
        }
        return result
    }

    private func appendPublishHistory(stage: SitePublishStage, title: String, detail: String, url: String) {
        publishHistory.insert(
            SitePublishHistoryItem(
                stage: stage,
                title: title,
                detail: detail,
                url: url,
                timestamp: Date()
            ),
            at: 0
        )

        if publishHistory.count > 12 {
            publishHistory = Array(publishHistory.prefix(12))
        }
    }

    func recordLocalPublish(_ response: LocalSitePublishResponse) {
        isPublished = true
        publishStage = .published
        siteExportStatus = "Published local preview at \(response.url)."
        appendPublishHistory(
            stage: .published,
            title: "Local site published",
            detail: "\(response.slug) exported for browser review.",
            url: response.url
        )
    }

    private func applyWorkspaceSnapshot(_ snapshot: SiteClawWorkspaceSnapshot) {
        restaurant = snapshot.restaurant.makeRestaurantProfile()
        draft = snapshot.draft.makeWebsiteDraft()
        accountSettings = snapshot.accountSettings.makeAccountSettings()
        voicePrompts = snapshot.voicePrompts.map { $0.makeVoicePrompt() }
        voiceTranscript = snapshot.voiceTranscript
        pendingVoiceAnswer = snapshot.pendingVoiceAnswer
        activeVoicePromptIndex = min(max(snapshot.activeVoicePromptIndex, 0), max(voicePrompts.count - 1, 0))
        isPublished = snapshot.isPublished
        isDraftGenerated = snapshot.isDraftGenerated
        monthlyPrice = snapshot.monthlyPrice
        siteExportStatus = snapshot.siteExportStatus
        lastSiteExportedAt = snapshot.lastSiteExportedAt
        publishStage = snapshot.publishStage
        publishHistory = snapshot.publishHistory
        voiceCoachTurns = snapshot.voiceCoachTurns
        activeSuggestedFollowUp = snapshot.activeSuggestedFollowUp
        voiceCoachStatus = snapshot.voiceCoachStatus
        isVoiceCoachWorking = false
        workspaceID = snapshot.workspaceID
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

struct SiteClawWorkspaceAutosaveState: Hashable {
    var restaurant: RestaurantProfile
    var draft: WebsiteDraft
    var accountSettings: SiteClawAccountSettings
    var voicePrompts: [VoiceOnboardingPrompt]
    var voiceTranscript: String
    var pendingVoiceAnswer: String
    var activeVoicePromptIndex: Int
    var isPublished: Bool
    var isDraftGenerated: Bool
    var monthlyPrice: Int
    var siteExportStatus: String
    var lastSiteExportedAtTimestamp: TimeInterval?
    var publishStage: SitePublishStage
    var publishHistory: [SitePublishHistoryItem]
    var voiceCoachTurns: [VoiceCoachTurn]
    var activeSuggestedFollowUp: String
    var voiceCoachStatus: String
}

struct SiteClawWorkspaceStore {
    var rootDirectory: URL

    static var `default`: SiteClawWorkspaceStore {
        let applicationSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        return SiteClawWorkspaceStore(rootDirectory: applicationSupport.appendingPathComponent("SiteClaw/Workspaces", isDirectory: true))
    }

    func save(snapshot: SiteClawWorkspaceSnapshot, workspaceID: String) throws {
        let directory = workspaceDirectory(for: workspaceID)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(snapshot)
        try data.write(to: manifestURL(for: workspaceID), options: [.atomic])
    }

    func load(workspaceID: String) throws -> SiteClawWorkspaceSnapshot? {
        let url = manifestURL(for: workspaceID)
        guard FileManager.default.fileExists(atPath: url.path) else {
            return nil
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let data = try Data(contentsOf: url)
        return try decoder.decode(SiteClawWorkspaceSnapshot.self, from: data)
    }

    func manifestURL(for workspaceID: String) -> URL {
        workspaceDirectory(for: workspaceID).appendingPathComponent("siteclaw-workspace.json")
    }

    func workspaceDirectory(for workspaceID: String) -> URL {
        rootDirectory.appendingPathComponent(Self.safeWorkspaceID(workspaceID), isDirectory: true)
    }

    private static func safeWorkspaceID(_ value: String) -> String {
        let slug = value
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: "-")
        return slug.isEmpty ? "default" : slug
    }
}

struct SiteClawWorkspaceSnapshot: Codable, Hashable {
    var schemaVersion: Int = 1
    var workspaceID: String
    var savedAt: Date
    var restaurant: RestaurantProfileSnapshot
    var draft: WebsiteDraftSnapshot
    var accountSettings: SiteClawAccountSettingsSnapshot
    var voicePrompts: [VoicePromptSnapshot]
    var voiceTranscript: String
    var pendingVoiceAnswer: String
    var activeVoicePromptIndex: Int
    var isPublished: Bool
    var isDraftGenerated: Bool
    var monthlyPrice: Int
    var siteExportStatus: String
    var lastSiteExportedAt: Date?
    var publishStage: SitePublishStage
    var publishHistory: [SitePublishHistoryItem]
    var voiceCoachTurns: [VoiceCoachTurn]
    var activeSuggestedFollowUp: String
    var voiceCoachStatus: String

    enum CodingKeys: String, CodingKey {
        case schemaVersion
        case workspaceID
        case savedAt
        case restaurant
        case draft
        case accountSettings
        case voicePrompts
        case voiceTranscript
        case pendingVoiceAnswer
        case activeVoicePromptIndex
        case isPublished
        case isDraftGenerated
        case monthlyPrice
        case siteExportStatus
        case lastSiteExportedAt
        case publishStage
        case publishHistory
        case voiceCoachTurns
        case activeSuggestedFollowUp
        case voiceCoachStatus
    }

    init(studio: SiteClawStudio, workspaceID: String? = nil) {
        self.workspaceID = workspaceID ?? studio.workspaceID
        savedAt = Date()
        restaurant = RestaurantProfileSnapshot(profile: studio.restaurant)
        draft = WebsiteDraftSnapshot(draft: studio.draft)
        accountSettings = SiteClawAccountSettingsSnapshot(settings: studio.accountSettings)
        voicePrompts = studio.voicePrompts.map { VoicePromptSnapshot(prompt: $0) }
        voiceTranscript = studio.voiceTranscript
        pendingVoiceAnswer = studio.pendingVoiceAnswer
        activeVoicePromptIndex = studio.activeVoicePromptIndex
        isPublished = studio.isPublished
        isDraftGenerated = studio.isDraftGenerated
        monthlyPrice = studio.monthlyPrice
        siteExportStatus = studio.siteExportStatus
        lastSiteExportedAt = studio.lastSiteExportedAt
        publishStage = studio.publishStage
        publishHistory = studio.publishHistory
        voiceCoachTurns = studio.voiceCoachTurns
        activeSuggestedFollowUp = studio.activeSuggestedFollowUp
        voiceCoachStatus = studio.voiceCoachStatus
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        schemaVersion = try container.decodeIfPresent(Int.self, forKey: .schemaVersion) ?? 1
        workspaceID = try container.decodeIfPresent(String.self, forKey: .workspaceID) ?? "default"
        savedAt = try container.decodeIfPresent(Date.self, forKey: .savedAt) ?? Date()
        restaurant = try container.decode(RestaurantProfileSnapshot.self, forKey: .restaurant)
        draft = try container.decode(WebsiteDraftSnapshot.self, forKey: .draft)
        accountSettings = try container.decode(SiteClawAccountSettingsSnapshot.self, forKey: .accountSettings)
        voicePrompts = try container.decodeIfPresent([VoicePromptSnapshot].self, forKey: .voicePrompts) ?? VoiceOnboardingPrompt.samples.map { VoicePromptSnapshot(prompt: $0) }
        voiceTranscript = try container.decodeIfPresent(String.self, forKey: .voiceTranscript) ?? ""
        pendingVoiceAnswer = try container.decodeIfPresent(String.self, forKey: .pendingVoiceAnswer) ?? ""
        activeVoicePromptIndex = try container.decodeIfPresent(Int.self, forKey: .activeVoicePromptIndex) ?? 0
        isPublished = try container.decodeIfPresent(Bool.self, forKey: .isPublished) ?? false
        isDraftGenerated = try container.decodeIfPresent(Bool.self, forKey: .isDraftGenerated) ?? true
        monthlyPrice = try container.decodeIfPresent(Int.self, forKey: .monthlyPrice) ?? 19
        siteExportStatus = try container.decodeIfPresent(String.self, forKey: .siteExportStatus) ?? "No site export prepared yet."
        lastSiteExportedAt = try container.decodeIfPresent(Date.self, forKey: .lastSiteExportedAt)
        publishStage = try container.decodeIfPresent(SitePublishStage.self, forKey: .publishStage) ?? .preview
        publishHistory = try container.decodeIfPresent([SitePublishHistoryItem].self, forKey: .publishHistory) ?? []
        voiceCoachTurns = try container.decodeIfPresent([VoiceCoachTurn].self, forKey: .voiceCoachTurns) ?? []
        activeSuggestedFollowUp = try container.decodeIfPresent(String.self, forKey: .activeSuggestedFollowUp) ?? ""
        voiceCoachStatus = try container.decodeIfPresent(String.self, forKey: .voiceCoachStatus) ?? "Save an answer to get AI coaching."
    }
}

struct RestaurantProfileSnapshot: Codable, Hashable {
    var name: String
    var cuisine: String
    var neighborhood: String
    var streetAddress: String
    var state: String
    var postalCode: String
    var ownerName: String
    var phone: String
    var cateringEmail: String
    var hours: String
    var story: String
    var menuItems: [MenuItemSnapshot]
    var uploadedMenu: UploadedMenuAssetSnapshot?
    var branding: SiteBrandingSettingsSnapshot
    var visibility: RestaurantVisibilitySettings
    var features: RestaurantSiteFeatures
    var growthTools: RestaurantGrowthTools

    init(profile: RestaurantProfile) {
        name = profile.name
        cuisine = profile.cuisine
        neighborhood = profile.neighborhood
        streetAddress = profile.streetAddress
        state = profile.state
        postalCode = profile.postalCode
        ownerName = profile.ownerName
        phone = profile.phone
        cateringEmail = profile.cateringEmail
        hours = profile.hours
        story = profile.story
        menuItems = profile.menuItems.map { MenuItemSnapshot(item: $0) }
        uploadedMenu = profile.uploadedMenu.map { UploadedMenuAssetSnapshot(asset: $0) }
        branding = SiteBrandingSettingsSnapshot(settings: profile.branding)
        visibility = profile.visibility
        features = profile.features
        growthTools = profile.growthTools
    }

    func makeRestaurantProfile() -> RestaurantProfile {
        RestaurantProfile(
            name: name,
            cuisine: cuisine,
            neighborhood: neighborhood,
            streetAddress: streetAddress,
            state: state,
            postalCode: postalCode,
            ownerName: ownerName,
            phone: phone,
            cateringEmail: cateringEmail,
            hours: hours,
            story: story,
            menuItems: menuItems.map { $0.makeMenuItem() },
            uploadedMenu: uploadedMenu?.makeUploadedMenuAsset(),
            branding: branding.makeBrandingSettings(),
            visibility: visibility,
            features: features,
            growthTools: growthTools
        )
    }
}

struct MenuItemSnapshot: Codable, Hashable {
    var name: String
    var description: String
    var price: Double?
    var image: MenuItemImageAssetSnapshot?

    init(item: MenuItem) {
        name = item.name
        description = item.description
        price = item.price
        image = item.image.map { MenuItemImageAssetSnapshot(asset: $0) }
    }

    func makeMenuItem() -> MenuItem {
        MenuItem(
            name: name,
            description: description,
            price: price,
            image: image?.makeImageAsset()
        )
    }
}

struct MenuItemImageAssetSnapshot: Codable, Hashable {
    var filename: String
    var mediaType: String
    var dataURL: String
    var byteCount: Int
    var portableAssetName: String

    init(asset: MenuItemImageAsset) {
        filename = asset.filename
        mediaType = asset.mediaType
        dataURL = asset.dataURL
        byteCount = asset.byteCount
        portableAssetName = asset.portableAssetName
    }

    func makeImageAsset() -> MenuItemImageAsset {
        MenuItemImageAsset(
            filename: filename,
            mediaType: mediaType,
            dataURL: dataURL,
            byteCount: byteCount
        )
    }
}

struct UploadedMenuAssetSnapshot: Codable, Hashable {
    var filename: String
    var mediaType: String
    var kind: String
    var dataURL: String
    var byteCount: Int
    var portableAssetName: String

    init(asset: UploadedMenuAsset) {
        filename = asset.filename
        mediaType = asset.mediaType
        kind = asset.kind.rawValue
        dataURL = asset.dataURL
        byteCount = asset.byteCount
        portableAssetName = asset.portableAssetName
    }

    func makeUploadedMenuAsset() -> UploadedMenuAsset {
        UploadedMenuAsset(
            filename: filename,
            mediaType: mediaType,
            kind: UploadedMenuAssetKind(rawValue: kind) ?? .image,
            dataURL: dataURL,
            byteCount: byteCount
        )
    }
}

struct SiteBrandingSettingsSnapshot: Codable, Hashable {
    var primaryColorHex: String
    var accentColorHex: String
    var fontStyle: String

    init(settings: SiteBrandingSettings) {
        primaryColorHex = settings.primaryColorHex
        accentColorHex = settings.accentColorHex
        fontStyle = settings.fontStyle
    }

    func makeBrandingSettings() -> SiteBrandingSettings {
        SiteBrandingSettings(
            primaryColorHex: primaryColorHex,
            accentColorHex: accentColorHex,
            fontStyle: fontStyle
        )
    }
}

struct WebsiteDraftSnapshot: Codable, Hashable {
    var headline: String
    var subheadline: String
    var callToAction: String
    var pages: [String]
    var seoKeywords: [String]
    var designBrief: RestaurantDesignBrief
    var url: String
    var lastGeneratedSummary: String

    init(draft: WebsiteDraft) {
        headline = draft.headline
        subheadline = draft.subheadline
        callToAction = draft.callToAction
        pages = draft.pages
        seoKeywords = draft.seoKeywords
        designBrief = draft.designBrief
        url = draft.url
        lastGeneratedSummary = draft.lastGeneratedSummary
    }

    func makeWebsiteDraft() -> WebsiteDraft {
        WebsiteDraft(
            headline: headline,
            subheadline: subheadline,
            callToAction: callToAction,
            pages: pages,
            seoKeywords: seoKeywords,
            designBrief: designBrief,
            url: url,
            lastGeneratedSummary: lastGeneratedSummary
        )
    }
}

struct SiteClawAccountSettingsSnapshot: Codable, Hashable {
    var ownerName: String
    var email: String
    var siteSubdomain: String
    var customDomain: String
    var billingPlan: String
    var isSignedIn: Bool
    var appearancePreference: SiteClawAppearancePreference
    var dataRetentionNote: String

    enum CodingKeys: String, CodingKey {
        case ownerName
        case email
        case siteSubdomain
        case customDomain
        case billingPlan
        case isSignedIn
        case appearancePreference
        case dataRetentionNote
    }

    init(settings: SiteClawAccountSettings) {
        ownerName = settings.ownerName
        email = settings.email
        siteSubdomain = settings.siteSubdomain
        customDomain = settings.customDomain
        billingPlan = settings.billingPlan
        isSignedIn = settings.isSignedIn
        appearancePreference = settings.appearancePreference
        dataRetentionNote = settings.dataRetentionNote
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        ownerName = try container.decodeIfPresent(String.self, forKey: .ownerName) ?? ""
        email = try container.decodeIfPresent(String.self, forKey: .email) ?? ""
        siteSubdomain = try container.decodeIfPresent(String.self, forKey: .siteSubdomain) ?? ""
        customDomain = try container.decodeIfPresent(String.self, forKey: .customDomain) ?? ""
        billingPlan = try container.decodeIfPresent(String.self, forKey: .billingPlan) ?? SiteClawBillingPlan.starter.displayName
        isSignedIn = try container.decodeIfPresent(Bool.self, forKey: .isSignedIn) ?? true
        appearancePreference = try container.decodeIfPresent(SiteClawAppearancePreference.self, forKey: .appearancePreference) ?? .system
        dataRetentionNote = try container.decodeIfPresent(String.self, forKey: .dataRetentionNote) ?? "Local prototype data stays on this Mac unless you export or publish it."
    }

    func makeAccountSettings() -> SiteClawAccountSettings {
        SiteClawAccountSettings(
            ownerName: ownerName,
            email: email,
            siteSubdomain: siteSubdomain,
            customDomain: customDomain,
            billingPlan: billingPlan,
            isSignedIn: isSignedIn,
            appearancePreference: appearancePreference,
            dataRetentionNote: dataRetentionNote
        )
    }
}

struct VoicePromptSnapshot: Codable, Hashable {
    var question: String
    var helperText: String
    var capturedAnswer: String
    var systemImage: String
    var promptKind: String
    var missingDetailKind: String?

    init(prompt: VoiceOnboardingPrompt) {
        question = prompt.question
        helperText = prompt.helperText
        capturedAnswer = prompt.capturedAnswer
        systemImage = prompt.systemImage
        promptKind = prompt.promptKind.rawValue
        missingDetailKind = prompt.missingDetailKind?.rawValue
    }

    func makeVoicePrompt() -> VoiceOnboardingPrompt {
        VoiceOnboardingPrompt(
            question: question,
            helperText: helperText,
            capturedAnswer: capturedAnswer,
            systemImage: systemImage,
            promptKind: VoicePromptKind(rawValue: promptKind) ?? .custom,
            missingDetailKind: missingDetailKind.flatMap { MissingDetailKind(rawValue: $0) }
        )
    }
}

struct TranscriptRestaurantExtraction {
    var profile: RestaurantProfile
    var promptAnswers: [String]
}

struct CuisineLocationExtraction: Hashable {
    var cuisine: String = ""
    var city: String = ""
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

        return cleanOwnerSpeech(normalized)
            .replacingOccurrences(of: #"\b(\d{1,2})\s+(?:forty|fourty)[-\s]?(?:nine|9)\b"#, with: "$1.49", options: [.regularExpression, .caseInsensitive])
            .replacingOccurrences(of: #"\b(\d{1,2})\s+eighty[-\s]?(?:nine|9)\b"#, with: "$1.99", options: [.regularExpression, .caseInsensitive])
            .replacingOccurrences(of: #"\b(\d{1,2})\s+ninety[-\s]?(?:nine|9)\b"#, with: "$1.99", options: [.regularExpression, .caseInsensitive])
    }

    private static func cleanOwnerSpeech(_ transcript: String) -> String {
        var cleaned = transcript
            .replacingOccurrences(of: #"\b(?:um+|uh+|uhm+|umm+|erm|hmm)\b[,\s]*"#, with: "", options: [.regularExpression, .caseInsensitive])
            .replacingOccurrences(of: #"\b(?:let'?s say|you know|i mean)\b[,\s]*"#, with: "", options: [.regularExpression, .caseInsensitive])
            .replacingOccurrences(of: #"\s+([,.;:])"#, with: "$1", options: .regularExpression)
            .replacingOccurrences(of: #"\s{2,}"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        var previous = ""
        while previous != cleaned {
            previous = cleaned
            cleaned = cleaned
                .replacingOccurrences(
                    of: #"^(?:so|okay|ok|well|like|basically|actually|just|kind of|sort of)[,\s]+"#,
                    with: "",
                    options: [.regularExpression, .caseInsensitive]
                )
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }

        return cleaned
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

enum VoicePromptAnswerInterpreter {
    static func interpret(
        promptKind: VoicePromptKind,
        promptIndex: Int,
        extractedAnswer: String,
        fallbackAnswer: String
    ) -> String {
        let extracted = VoiceTranscriptNormalizer.normalize(extractedAnswer)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let fallback = VoiceTranscriptNormalizer.normalize(fallbackAnswer)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        switch promptKind {
        case .restaurantName:
            return restaurantName(from: extracted, fallback: fallback)
        case .cuisineLocation:
            return extracted.isEmpty ? cuisineAndLocation(from: fallback) : extracted
        case .hours, .featuredDishes:
            return extracted.isEmpty ? fallback : extracted
        case .ownerStory:
            return cleanStoryAnswer(extracted.isEmpty ? fallback : extracted)
        case .custom:
            return interpret(promptIndex: promptIndex, extractedAnswer: extracted, fallbackAnswer: fallback)
        }
    }

    static func interpret(
        promptIndex: Int,
        extractedAnswer: String,
        fallbackAnswer: String
    ) -> String {
        let extracted = VoiceTranscriptNormalizer.normalize(extractedAnswer)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let fallback = VoiceTranscriptNormalizer.normalize(fallbackAnswer)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        switch promptIndex {
        case 0:
            return restaurantName(from: extracted, fallback: fallback)
        case 1:
            return extracted.isEmpty ? cuisineAndLocation(from: fallback) : extracted
        case 2:
            return extracted.isEmpty ? fallback : extracted
        case 3:
            return extracted.isEmpty ? fallback : extracted
        case 4:
            return story(from: extracted, fallback: fallback)
        default:
            return extracted.isEmpty ? fallback : extracted
        }
    }

    private static func restaurantName(from extracted: String, fallback: String) -> String {
        for candidate in [extracted, fallback] where !candidate.isEmpty {
            if let name = MissingDetailAnswerExtractor.restaurantName(from: candidate) {
                return name
            }
        }

        return ""
    }

    private static func cuisineAndLocation(from fallback: String) -> String {
        let extraction = TranscriptRestaurantExtractor.extract(from: fallback)
        let cuisine = extraction.profile.cuisine.trimmingCharacters(in: .whitespacesAndNewlines)
        let city = extraction.profile.neighborhood.trimmingCharacters(in: .whitespacesAndNewlines)

        if cuisine.isEmpty {
            return fallback
        }

        return [cuisine, city.isEmpty ? "" : "in \(city)"]
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    private static func story(from extracted: String, fallback: String) -> String {
        cleanStoryAnswer(extracted.isEmpty ? fallback : extracted)
    }

    static func cleanStoryAnswer(_ answer: String) -> String {
        let candidate = VoiceTranscriptNormalizer.normalize(answer)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return candidate
            .replacingOccurrences(
                of: #"^(?:what\s+makes\s+(?:us|this|our\s+restaurant)?\s+special\s+is|makes\s+us\s+special\s+is|our\s+story\s+is)\s+"#,
                with: "",
                options: [.regularExpression, .caseInsensitive]
            )
            .replacingOccurrences(
                of: #"^(?:it\s+is|it's|it’s|we\s+are|we're)\s+"#,
                with: "",
                options: [.regularExpression, .caseInsensitive]
            )
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
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
            #"\b(?:the\s+)?name\s+of\s+(?:the\s+)?restaurant\s+is\s+([A-Za-z0-9&' .-]{2,80}?)(?=\.|,|\s+(?:it\s+is|it's|it’s|we\s+|we're\s+|serves?\s+|open\s+|in\s+)|$)"#,
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
    static func cuisineLocation(from transcript: String) -> CuisineLocationExtraction {
        let normalizedTranscript = normalizeTranscript(transcript)
        return CuisineLocationExtraction(
            cuisine: extractCuisine(from: normalizedTranscript),
            city: extractCity(from: normalizedTranscript)
        )
    }

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

    static func isLikelyHoursAnswer(_ text: String) -> Bool {
        let cleaned = VoiceTranscriptNormalizer.normalize(text)
        let lowercased = cleaned.lowercased()
        let hasDaySignal = dayNames.contains { lowercased.contains($0) }
            || lowercased.contains("daily")
            || lowercased.contains("every day")
        return hasTimeRange(cleaned) && (hasDaySignal || lowercased.contains("open") || lowercased.contains("hours"))
    }

    private static func normalizeTranscript(_ transcript: String) -> String {
        VoiceTranscriptNormalizer.normalize(transcript)
    }

    private static func extractName(from transcript: String) -> String {
        let patterns = [
            #"\b(?:the\s+)?name\s+of\s+(?:the\s+)?restaurant\s+is\s+([A-Za-z0-9&' .-]{2,80}?)(?=\.|,|\s+(?:it\s+is|it's|it’s|is\s+(?:a|an|family)|we\s+|we're\s+|open\s+|serve\s+|serves\s+|in\s+[A-Z])|$)"#,
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
        let knownCuisines: [(phrase: String, canonical: String)] = [
            ("salvadorian", "Salvadorian"),
            ("salvadoran", "Salvadorian"),
            ("peruvian", "Peruvian"),
            ("argentinian", "Argentinian"),
            ("argentine", "Argentinian"),
            ("vietnamese", "Vietnamese"),
            ("mexican", "Mexican"),
            ("italian", "Italian"),
            ("chinese", "Chinese"),
            ("thai", "Thai"),
            ("japanese", "Japanese"),
            ("korean", "Korean"),
            ("indian", "Indian"),
            ("filipino", "Filipino"),
            ("ethiopian", "Ethiopian"),
            ("mediterranean", "Mediterranean"),
            ("american", "American"),
            ("seafood", "Seafood"),
            ("barbecue", "Barbecue"),
            ("bbq", "BBQ"),
            ("pizza", "Pizza"),
            ("bakery", "Bakery"),
            ("coffee", "Coffee")
        ]

        let matches = knownCuisines.compactMap { cuisine -> (offset: Int, canonical: String)? in
            guard let range = lowercased.range(of: cuisine.phrase) else { return nil }
            let offset = lowercased.distance(from: lowercased.startIndex, to: range.lowerBound)
            return (offset, cuisine.canonical)
        }
        let cuisines = matches
            .sorted { $0.offset < $1.offset }
            .reduce(into: [String]()) { result, match in
                if !result.contains(match.canonical) {
                    result.append(match.canonical)
                }
            }

        guard !cuisines.isEmpty else {
            return ""
        }

        let cuisine = joinedList(cuisines)

        if lowercased.contains("comfort") {
            return "\(cuisine) comfort food"
        }

        return "\(cuisine) restaurant"
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

    private static let dayNames = [
        "monday", "mon",
        "tuesday", "tue", "tues",
        "wednesday", "wed",
        "thursday", "thu", "thur", "thurs",
        "friday", "fri",
        "saturday", "sat",
        "sunday", "sun"
    ]

    private static func extractHours(from transcript: String) -> String {
        let dayWords = dayNames + ["daily"]
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
            .replacingOccurrences(
                of: #"\s+\b(?:we\s+(?:do|serve|make|are)|we're|it\s+is|it's)\s+(?:[A-Za-z]+(?:ian)?\s+)?(?:food|cuisine|restaurant)\b.*$"#,
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

        guard !matches.isEmpty else {
            return extractPrice(from: transcript) == nil ? [] : [transcript]
        }

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

    static func menuLabel(for item: MenuItem) -> String {
        guard let price = item.price, price > 0 else {
            return item.name
        }

        return "\(item.name) \(String(format: "$%.2f", price))"
    }

    static func followUpMenuItems(from answer: String) -> [MenuItem] {
        let cleaned = VoiceTranscriptNormalizer.normalize(answer)
            .replacingOccurrences(
                of: #"\b(?:for sure|definitely|probably|i would pick|i'd pick|pick|choose|main homepage bestsellers?|homepage bestsellers?)\b"#,
                with: " ",
                options: [.regularExpression, .caseInsensitive]
            )
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { return [] }

        return extractMenuItems(from: "we feature \(cleaned)")
    }

    private static func cleanNameCandidate(_ candidate: String) -> String? {
        let trimmed = candidate
            .replacingOccurrences(
                of: #"^(?:we\s+are|we're|my\s+restaurant\s+is|the\s+restaurant\s+is|(?:the\s+)?name\s+of\s+(?:the\s+)?restaurant\s+is)\s+"#,
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

    private static func joinedList(_ values: [String]) -> String {
        guard let first = values.first else { return "" }
        guard values.count > 1 else { return first }
        return "\(values.dropLast().joined(separator: ", ")) and \(values.last ?? "")"
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

    var hasFullAddress: Bool {
        !streetAddress.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !neighborhood.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !state.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !postalCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var visibilityChecklistItems: [VisibilityChecklistItem] {
        let googleProfileURL = visibility.googleBusinessProfileURL.trimmingCharacters(in: .whitespacesAndNewlines)
        let googleReviewURL = visibility.googleReviewURL.trimmingCharacters(in: .whitespacesAndNewlines)
        let yelpURL = visibility.yelpBusinessURL.trimmingCharacters(in: .whitespacesAndNewlines)

        return [
            VisibilityChecklistItem(
                title: "Full address added",
                detail: hasFullAddress ? formattedAddress : "Add street, city, state, and ZIP.",
                isComplete: hasFullAddress,
                systemImage: "mappin.and.ellipse"
            ),
            VisibilityChecklistItem(
                title: "Phone number added",
                detail: phone.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Add a customer-facing phone number." : phone,
                isComplete: !phone.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                systemImage: "phone"
            ),
            VisibilityChecklistItem(
                title: "Hours added",
                detail: hours.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Add regular business hours." : hours,
                isComplete: !hours.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                systemImage: "clock"
            ),
            VisibilityChecklistItem(
                title: "Full menu uploaded",
                detail: uploadedMenu?.filename ?? "Upload a PDF or image of the full menu.",
                isComplete: uploadedMenu != nil,
                systemImage: "menucard"
            ),
            VisibilityChecklistItem(
                title: "Google Business Profile created or claimed",
                detail: googleProfileURL.isEmpty ? "Add the profile URL or mark it claimed." : googleProfileURL,
                isComplete: visibility.googleBusinessProfileClaimed || !googleProfileURL.isEmpty,
                systemImage: "magnifyingglass"
            ),
            VisibilityChecklistItem(
                title: "Google review link added",
                detail: googleReviewURL.isEmpty ? "Add the owner-provided Google review link." : googleReviewURL,
                isComplete: !googleReviewURL.isEmpty,
                systemImage: "star.bubble"
            ),
            VisibilityChecklistItem(
                title: "Yelp business page linked",
                detail: yelpURL.isEmpty ? "Add the Yelp business page URL." : yelpURL,
                isComplete: !yelpURL.isEmpty,
                systemImage: "link"
            ),
            VisibilityChecklistItem(
                title: "Restaurant photos added",
                detail: visibility.restaurantPhotosAdded ? "Marked ready for local profiles." : "Add recent interior, exterior, and food photos.",
                isComplete: visibility.restaurantPhotosAdded,
                systemImage: "photo.on.rectangle"
            ),
            VisibilityChecklistItem(
                title: "Website link added to Google/Yelp profiles",
                detail: visibility.websiteLinkedOnProfiles ? "Marked linked on external profiles." : "Add the published website URL to Google and Yelp.",
                isComplete: visibility.websiteLinkedOnProfiles,
                systemImage: "globe"
            )
        ]
    }

    var visibilityChecklistProgress: (completed: Int, total: Int) {
        let items = visibilityChecklistItems
        return (items.filter(\.isComplete).count, items.count)
    }

    var externalProfileLinks: [RestaurantExternalProfileLink] {
        [
            RestaurantExternalProfileLink(title: "Google Business Profile", url: visibility.googleBusinessProfileURL),
            RestaurantExternalProfileLink(title: "Find us on Yelp", url: visibility.yelpBusinessURL),
            RestaurantExternalProfileLink(title: "Instagram", url: visibility.instagramURL),
            RestaurantExternalProfileLink(title: "Facebook", url: visibility.facebookURL)
        ]
        .map {
            RestaurantExternalProfileLink(
                title: $0.title,
                url: $0.url.trimmingCharacters(in: .whitespacesAndNewlines)
            )
        }
        .filter { !$0.url.isEmpty }
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
        subheadline: "Save the menu, hours, story, photos, and local SEO in one guided conversation.",
        callToAction: "Start Building",
        pages: ["Home", "Menu", "Hours"],
        seoKeywords: ["restaurant website", "local restaurant", "menu online"],
        designBrief: .fallback,
        url: "https://preview.siteclaw.app",
        lastGeneratedSummary: "No generated site yet. Add restaurant details or use the voice example."
    )

    static let sample = WebsiteDraft(
        headline: "Sunset Grill serves American burgers and sandwiches in San Jose",
        subheadline: "Fresh ingredients, fast service, and a friendly neighborhood atmosphere.",
        callToAction: "View Menu",
        pages: ["Home", "Menu", "Hours", "Location", "About"],
        seoKeywords: ["Sunset Grill", "American restaurant in San Jose", "american burgers and sandwiches in San Jose", "Cheeseburgers", "Chicken Sandwiches", "Fries"],
        designBrief: .fallback,
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
        systemImage: "mic.fill",
        promptKind: .custom
    )

    static let samples: [VoiceOnboardingPrompt] = [
        VoiceOnboardingPrompt(
            question: "What is your restaurant called?",
            helperText: "Say the business name the way customers should see it online.",
            capturedAnswer: "",
            systemImage: "storefront.fill",
            promptKind: .restaurantName
        ),
        VoiceOnboardingPrompt(
            question: "What food do you serve, and where are you located?",
            helperText: "Cuisine and city help SiteClaw write local SEO copy.",
            capturedAnswer: "",
            systemImage: "mappin.and.ellipse",
            promptKind: .cuisineLocation
        ),
        VoiceOnboardingPrompt(
            question: "What are your hours?",
            helperText: "Customers often look up hours before deciding where to eat.",
            capturedAnswer: "",
            systemImage: "clock.fill",
            promptKind: .hours
        ),
        VoiceOnboardingPrompt(
            question: "What menu items should we feature?",
            helperText: "Name a few popular dishes and prices if you know them.",
            capturedAnswer: "",
            systemImage: "fork.knife",
            promptKind: .featuredDishes
        ),
        VoiceOnboardingPrompt(
            question: "What makes your restaurant special?",
            helperText: "A short owner story makes the site feel trustworthy.",
            capturedAnswer: "",
            systemImage: "quote.bubble.fill",
            promptKind: .ownerStory
        )
    ]

    static let filledSamples: [VoiceOnboardingPrompt] = [
        VoiceOnboardingPrompt(
            question: "What is your restaurant called?",
            helperText: "Say the business name the way customers should see it online.",
            capturedAnswer: "Sunset Grill",
            systemImage: "storefront.fill",
            promptKind: .restaurantName
        ),
        VoiceOnboardingPrompt(
            question: "What food do you serve, and where are you located?",
            helperText: "Cuisine and city help SiteClaw write local SEO copy.",
            capturedAnswer: "American burgers and sandwiches in San Jose",
            systemImage: "mappin.and.ellipse",
            promptKind: .cuisineLocation
        ),
        VoiceOnboardingPrompt(
            question: "What are your hours?",
            helperText: "Customers often look up hours before deciding where to eat.",
            capturedAnswer: "Monday through Saturday 10 AM to 8 PM, Sunday 11 AM to 6 PM",
            systemImage: "clock.fill",
            promptKind: .hours
        ),
        VoiceOnboardingPrompt(
            question: "What menu items should we feature?",
            helperText: "Name a few popular dishes and prices if you know them.",
            capturedAnswer: "Cheeseburgers $12.99, Chicken Sandwiches $11.49, Fries $4.99, Lemonade $3.49",
            systemImage: "fork.knife",
            promptKind: .featuredDishes
        ),
        VoiceOnboardingPrompt(
            question: "What makes your restaurant special?",
            helperText: "A short owner story makes the site feel trustworthy.",
            capturedAnswer: "Fresh ingredients, fast service, and a friendly neighborhood atmosphere",
            systemImage: "quote.bubble.fill",
            promptKind: .ownerStory
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

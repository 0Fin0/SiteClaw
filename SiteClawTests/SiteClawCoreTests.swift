//
//  SiteClawCoreTests.swift
//  SiteClawTests
//

import XCTest
@testable import SiteClaw

final class SiteClawCoreTests: XCTestCase {
    func testBackendHealthResponseDecodesBackendContract() throws {
        let data = """
        {
          "ok": true,
          "service": "siteclaw-backend",
          "realtime_model": "gpt-realtime",
          "realtime_transcription_model": "gpt-realtime-whisper",
          "generation_model": "gpt-5.4-mini"
        }
        """.data(using: .utf8)!

        let health = try JSONDecoder().decode(BackendHealthResponse.self, from: data)

        XCTAssertTrue(health.ok)
        XCTAssertEqual(health.service, "siteclaw-backend")
        XCTAssertEqual(health.realtimeModel, "gpt-realtime")
        XCTAssertEqual(health.realtimeTranscriptionModel, "gpt-realtime-whisper")
        XCTAssertEqual(health.generationModel, "gpt-5.4-mini")
    }

    func testVoiceTranscriptNormalizerFixesCommonSpeechArtifacts() {
        let transcript = "phone lotus serves faux rice bowls for fourteen dollars at eleven a.m."

        let normalized = VoiceTranscriptNormalizer.normalize(transcript)

        XCTAssertTrue(normalized.contains("Pho Lotus"))
        XCTAssertTrue(normalized.contains("pho, rice bowls"))
        XCTAssertTrue(normalized.contains("14"))
        XCTAssertTrue(normalized.contains("11 AM"))
    }

    func testVoiceTranscriptNormalizerFixesFeatureMenuMishearing() {
        let transcript = "Eat your cheeseburgers for twelve ninety-nine. Chicken sandwiches for eleven forty-nine."

        let normalized = VoiceTranscriptNormalizer.normalize(transcript)

        XCTAssertTrue(normalized.contains("Feature cheeseburgers"))
        XCTAssertTrue(normalized.contains("12.99"))
        XCTAssertTrue(normalized.contains("11.49"))
        XCTAssertFalse(normalized.localizedCaseInsensitiveContains("Eat your cheeseburgers"))
    }

    func testTranscriptExtractorCapturesSampleRestaurantProfile() {
        let extraction = TranscriptRestaurantExtractor.extract(from: VoiceOnboardingPrompt.sampleTranscript)
        let profile = extraction.profile

        XCTAssertEqual(profile.name, "Sunset Grill")
        XCTAssertEqual(profile.cuisine, "American restaurant")
        XCTAssertEqual(profile.neighborhood, "San Jose")
        XCTAssertTrue(profile.hours.contains("Monday through Saturday"))
        XCTAssertTrue(profile.hours.contains("Sunday"))
        XCTAssertFalse(profile.hours.hasSuffix("Our"))
        XCTAssertEqual(profile.story, "Fresh ingredients, fast service, and a friendly neighborhood atmosphere")
        XCTAssertEqual(profile.menuItems.map(\.name), ["Cheeseburgers", "Chicken Sandwiches", "Fries", "Lemonade"])
        XCTAssertEqual(profile.menuItems.map(\.price), [12.99, 11.49, 4.99, 3.49])
    }

    func testTranscriptExtractorHandlesRealtimeSentenceBreaksAndSpokenAddress() {
        let transcript = """
        My restaurant is called Pho Lotus Kitchen. It is a family-owned Vietnamese restaurant in San Jose. \
        We serve pho. Rice bowls, Spring rolls, and iced coffee. We are open Monday through Saturday from 11 AM to 9 PM. \
        What makes us special is our family recipes and friendly neighborhood service. \
        The restaurant street address is street address 1 2 3 Main Street, San Jose, California, 95112.
        """

        let extraction = TranscriptRestaurantExtractor.extract(from: transcript)
        let profile = extraction.profile

        XCTAssertEqual(profile.menuItems.map(\.name), ["Pho", "Rice Bowls", "Spring Rolls", "Iced Coffee"])
        XCTAssertEqual(profile.streetAddress, "123 Main Street")
        XCTAssertEqual(profile.neighborhood, "San Jose")
        XCTAssertEqual(profile.state, "CA")
        XCTAssertEqual(profile.postalCode, "95112")
        XCTAssertFalse(profile.streetAddress.contains("11 AM"))
        XCTAssertFalse(profile.streetAddress.contains("special"))
    }

    func testTranscriptExtractorHandlesRealtimeMenuMishearingsWithoutPollutingHours() {
        let transcript = """
        My restaurant is called Pho Lotus Kitchen. We serve Vietnamese comfort food in San Jose. \
        We are open Monday through Saturday from 11 AM to 9 PM and Sunday from 11 AM to 7 PM. \
        We feature FAUSPA for $14.99 Rice bowls for 13 forty-9. \
        Spring rolls for $8.99. and iced coffee for $5.49. \
        What makes this special is our family recipes, slow simmered broth, fresh herbs, and friendly neighborhood service.
        """

        let extraction = TranscriptRestaurantExtractor.extract(from: transcript)
        let profile = extraction.profile

        XCTAssertEqual(profile.menuItems.map(\.name), ["House Pho", "Rice Bowls", "Spring Rolls", "Iced Coffee"])
        XCTAssertEqual(profile.menuItems.map(\.price), [14.99, 13.49, 8.99, 5.49])
        XCTAssertFalse(profile.menuItems.map(\.name).contains("Vietnamese Comfort Food In San Jose"))
        XCTAssertTrue(profile.hours.contains("Monday through Saturday"))
        XCTAssertTrue(profile.hours.contains("Sunday"))
        XCTAssertFalse(profile.hours.localizedCaseInsensitiveContains("feature"))
        XCTAssertFalse(profile.hours.localizedCaseInsensitiveContains("FAUSPA"))
    }

    func testTranscriptExtractorHandlesLatestVoiceDemoArtifacts() {
        let transcript = """
        My restaurant is called Buddha Lotus Kitchen. We serve Vietnamese comfort food in San Jose. \
        We are open Monday through Saturday from 11am to 9pm and Sunday from 11am to 7pm. \
        Feature house of 14 eighty-9 Rice bowls for 13.90 13.99. \
        Spring rolls for 8.99. And iced coffee for 5.49 What makes us special is our family recipes, \
        slow simmered broth, fresh herbs, and friendly neighborhood service.
        """

        let extraction = TranscriptRestaurantExtractor.extract(from: transcript)
        let profile = extraction.profile

        XCTAssertEqual(profile.name, "Pho Lotus Kitchen")
        XCTAssertEqual(profile.menuItems.map(\.name), ["House Pho", "Rice Bowls", "Spring Rolls", "Iced Coffee"])
        XCTAssertEqual(profile.menuItems.map(\.price), [14.99, 13.49, 8.99, 5.49])
        XCTAssertEqual(profile.story, "Our family recipes, slow simmered broth, fresh herbs, and friendly neighborhood service")
    }

    func testTranscriptExtractorPrefersFeaturedMenuOverCuisineSentence() {
        let transcript = """
        My restaurant is called Sunset Grill. We serve American burgers and sandwiches in San Jose. \
        We are open Monday through Saturday from 10 AM to 8 PM and Sunday from 11 AM to 6 PM. \
        Feature cheeseburgers for $12.99. Chicken sandwiches for $11.49. \
        Prized for $4.99. and lemonade for $3.49. \
        What makes this special is our fresh ingredients, fast service, and friendly neighborhood atmosphere.
        """

        let extraction = TranscriptRestaurantExtractor.extract(from: transcript)
        let profile = extraction.profile

        XCTAssertEqual(profile.name, "Sunset Grill")
        XCTAssertEqual(profile.cuisine, "American restaurant")
        XCTAssertEqual(profile.hours, "Monday through Saturday 10 AM to 8 PM and Sunday 11 AM to 6 PM")
        XCTAssertEqual(profile.menuItems.map(\.name), ["Cheeseburgers", "Chicken Sandwiches", "Fries", "Lemonade"])
        XCTAssertEqual(profile.menuItems.map(\.price), [12.99, 11.49, 4.99, 3.49])
        XCTAssertFalse(profile.menuItems.map(\.name).contains("American Burgers"))
    }

    func testTranscriptExtractorHandlesNaturalMenuItemsArePhrase() {
        let transcript = """
        My restaurant is called Sunset Grill. We serve American burgers and sandwiches in San Jose. \
        We are open Monday through Saturday from 10 AM to 8 PM and Sunday from 11 AM to 6 PM. \
        Our menu items are cheeseburgers for $12.99, chicken sandwiches for $11.49, fries for $4.99, and lemonade for $3.49. \
        What makes us special is fresh ingredients, fast service, and friendly neighborhood atmosphere.
        """

        let extraction = TranscriptRestaurantExtractor.extract(from: transcript)
        let profile = extraction.profile

        XCTAssertEqual(profile.cuisine, "American restaurant")
        XCTAssertEqual(profile.menuItems.map(\.name), ["Cheeseburgers", "Chicken Sandwiches", "Fries", "Lemonade"])
        XCTAssertEqual(profile.menuItems.map(\.price), [12.99, 11.49, 4.99, 3.49])
        XCTAssertFalse(profile.menuItems.map(\.name).contains("American Burgers"))
    }

    func testTranscriptExtractorHandlesPlainPricedMenuAnswerWithoutTrigger() {
        let transcript = """
        My restaurant is called Sunset Grill. We serve American burgers and sandwiches in San Jose. \
        We are open Monday through Saturday from 10 AM to 8 PM and Sunday from 11 AM to 6 PM. \
        Cheeseburgers for $12.99 Chicken sandwiches for 11.49. prize for $4.99 And lemonade for $3.49. \
        What makes us special is fresh ingredients, fast service, and friendly neighborhood atmosphere.
        """

        let extraction = TranscriptRestaurantExtractor.extract(from: transcript)
        let profile = extraction.profile

        XCTAssertEqual(profile.menuItems.map(\.name), ["Cheeseburgers", "Chicken Sandwiches", "Fries", "Lemonade"])
        XCTAssertEqual(profile.menuItems.map(\.price), [12.99, 11.49, 4.99, 3.49])
    }

    func testTranscriptExtractorRepairsDemoHoursWhenSundayIsMisheardAsSaturday() {
        let transcript = """
        My restaurant is called Sunset Grill. We serve American burgers and sandwiches in San Jose. \
        We are open Monday through Saturday from 10 AM to 8 PM And Saturday from 11 AM to 6 PM \
        Cheeseburgers for $12.99. Chicken sandwiches for $11.49. fries for 4.99. and lemonade for 3.49. \
        What makes us special is fresh ingredients, fast service, and a friendly neighborhood atmosphere.
        """

        let extraction = TranscriptRestaurantExtractor.extract(from: transcript)
        let profile = extraction.profile
        let json = RestaurantJSONExporter.makeRestaurantJSON(from: profile, draft: .placeholder)

        XCTAssertTrue(profile.hours.contains("Monday through Saturday"))
        XCTAssertTrue(profile.hours.contains("Sunday"))
        XCTAssertFalse(profile.hours.localizedCaseInsensitiveContains("Cheeseburgers"))
        XCTAssertEqual(json.hours.sunday.first?.open, "11:00")
        XCTAssertEqual(json.hours.sunday.first?.close, "18:00")
    }

    func testMenuStepCaptureAdvancesEvenWhenAnswerNeedsLaterParsing() {
        let studio = SiteClawStudio(
            restaurant: RestaurantProfile(
                name: "Sunset Grill",
                cuisine: "American restaurant",
                neighborhood: "San Jose",
                ownerName: "",
                phone: "",
                hours: "Monday through Saturday 10 AM to 8 PM and Sunday 11 AM to 6 PM",
                story: "",
                menuItems: []
            ),
            draft: .placeholder,
            messages: [],
            updates: [],
            metrics: [],
            voiceTranscript: "",
            pendingVoiceAnswer: "Cheeseburgers for $12.99 Chicken sandwiches for 11.49. prize for $4.99 And lemonade for $3.49.",
            activeVoicePromptIndex: 3,
            isDraftGenerated: false
        )

        studio.captureCurrentVoicePrompt()

        XCTAssertEqual(studio.activeVoicePromptIndex, 4)
        XCTAssertEqual(studio.voicePrompts[3].capturedAnswer, "Cheeseburgers $12.99, Chicken Sandwiches $11.49, Fries $4.99, Lemonade $3.49")
        XCTAssertEqual(studio.restaurant.menuItems.map(\.name), ["Cheeseburgers", "Chicken Sandwiches", "Fries", "Lemonade"])
        XCTAssertEqual(studio.restaurant.menuItems.map(\.price), [12.99, 11.49, 4.99, 3.49])
    }

    func testTranscriptExtractorDoesNotPromoteCuisineSentenceToMenu() {
        let transcript = """
        My restaurant is called Sunset Grill. We serve American burgers and sandwiches in San Jose. \
        We are open Monday through Saturday from 10 AM to 8 PM and Sunday from 11 AM to 6 PM. \
        What makes us special is fresh ingredients, fast service, and friendly neighborhood atmosphere.
        """

        let extraction = TranscriptRestaurantExtractor.extract(from: transcript)

        XCTAssertEqual(extraction.profile.cuisine, "American restaurant")
        XCTAssertTrue(extraction.profile.menuItems.isEmpty)
    }

    func testRealtimeTranscriptWaitsForManualCaptureBeforeAdvancingPrompt() {
        let studio = SiteClawStudio(
            restaurant: .empty,
            draft: .placeholder,
            messages: [],
            updates: [],
            metrics: [],
            voiceTranscript: "",
            isDraftGenerated: false
        )

        studio.handleRealtimeStreamEvent(.inputTranscriptCompleted("My restaurant is called Pho Lotus Kitchen."))

        XCTAssertEqual(studio.activeVoicePromptIndex, 0)
        XCTAssertEqual(studio.pendingVoiceAnswer, "My restaurant is called Pho Lotus Kitchen.")
        XCTAssertTrue(studio.voicePrompts[0].capturedAnswer.isEmpty)

        studio.captureCurrentVoicePrompt()

        XCTAssertEqual(studio.restaurant.name, "Pho Lotus Kitchen")
        XCTAssertEqual(studio.voicePrompts[0].capturedAnswer, "Pho Lotus Kitchen")
        XCTAssertEqual(studio.activeVoicePromptIndex, 1)
        XCTAssertTrue(studio.pendingVoiceAnswer.isEmpty)
    }

    func testMissingDetailAnswerExtractorAppliesMenuPricesAndDescriptions() {
        var items = [
            MenuItem(name: "House Pho", description: "", price: nil),
            MenuItem(name: "Spring Rolls", description: "", price: nil)
        ]

        XCTAssertTrue(
            MissingDetailAnswerExtractor.applyMenuPrices(
                from: "House pho is 14.99 and spring rolls are 8.99.",
                to: &items
            )
        )
        XCTAssertEqual(items[0].price, 14.99)
        XCTAssertEqual(items[1].price, 8.99)

        XCTAssertTrue(
            MissingDetailAnswerExtractor.applyMenuDescriptions(
                from: "House Pho is slow-simmered beef broth with herbs. Spring Rolls are fresh herbs and peanut sauce.",
                to: &items
            )
        )
        XCTAssertEqual(items[0].description, "Slow-simmered beef broth with herbs.")
        XCTAssertEqual(items[1].description, "Fresh herbs and peanut sauce.")
    }

    func testRestaurantJSONExporterMapsSampleData() {
        let json = RestaurantJSONExporter.makeRestaurantJSON(from: .sample, draft: .sample)

        XCTAssertEqual(json.basics.name, "Sunset Grill")
        XCTAssertEqual(json.basics.cuisineType, ["American restaurant"])
        XCTAssertEqual(json.hours.monday.first?.open, "10:00")
        XCTAssertEqual(json.hours.monday.first?.close, "20:00")
        XCTAssertEqual(json.hours.sunday.first?.open, "11:00")
        XCTAssertEqual(json.hours.sunday.first?.close, "18:00")
        XCTAssertEqual(json.menu.categories.first?.items.first?.name, "Cheeseburgers")
        XCTAssertEqual(json.menu.categories.first?.items.first?.price, 12.99)
    }

    func testGenerateDraftPolishesSunsetGrillForDemoReadiness() {
        let profile = RestaurantProfile(
            name: "Sunset Grill",
            cuisine: "American",
            neighborhood: "San Jose",
            ownerName: "",
            phone: "",
            hours: "Monday through Saturday 10 AM to 8 PM and Sunday 11 AM to 6 PM",
            story: "Fresh ingredients, fast service, and a friendly neighborhood atmosphere",
            menuItems: [
                MenuItem(name: "Cheeseburgers", description: "", price: 12.99),
                MenuItem(name: "Chicken Sandwiches", description: "", price: 11.49),
                MenuItem(name: "Fries", description: "", price: 4.99),
                MenuItem(name: "Lemonade", description: "", price: 3.49)
            ]
        )
        let studio = SiteClawStudio(
            restaurant: profile,
            draft: .placeholder,
            messages: [],
            updates: [],
            metrics: [],
            isDraftGenerated: false
        )

        studio.generateDraft()

        XCTAssertEqual(studio.restaurant.cuisine, "American restaurant")
        XCTAssertEqual(studio.draft.headline, "Sunset Grill serves American burgers and sandwiches in San Jose")
        XCTAssertFalse(studio.draft.headline.localizedCaseInsensitiveContains("brings american"))
        XCTAssertTrue(studio.restaurant.menuItems.allSatisfy { !$0.description.isEmpty })
        XCTAssertNil(studio.missingDetails.first { $0.kind == .dishDescriptions })
        XCTAssertEqual(studio.restaurantJSON.basics.cuisineType, ["American restaurant"])
        XCTAssertFalse(studio.restaurantJSON.menu.categories.first?.items.contains { $0.description.isEmpty } ?? true)
    }

    func testGenerateDraftCoalescesDuplicateDashboardActivity() {
        let studio = SiteClawStudio(
            restaurant: .sample,
            draft: .placeholder,
            messages: [],
            updates: [
                SiteUpdate(
                    type: .announcement,
                    title: "Website draft generated",
                    detail: "AI created a first version of the site from the owner conversation.",
                    timeLabel: "Just now"
                )
            ],
            metrics: [],
            isDraftGenerated: false
        )

        studio.generateDraft()
        studio.generateDraft()

        let generatedDraftUpdates = studio.updates.filter { $0.title == "Website draft generated" }
        XCTAssertEqual(generatedDraftUpdates.count, 1)
    }

    func testGenerateDraftReplacesWeakKnownMenuDescriptions() {
        let profile = RestaurantProfile(
            name: "Sunset Grill",
            cuisine: "American restaurant",
            neighborhood: "San Jose",
            ownerName: "",
            phone: "",
            hours: "Monday through Saturday 10 AM to 8 PM and Sunday 11 AM to 6 PM",
            story: "Fresh ingredients, fast service, and a friendly neighborhood atmosphere",
            menuItems: [
                MenuItem(
                    name: "Fries",
                    description: "A customer favorite from the american restaurant lineup at Sunset Grill.",
                    price: 4.99
                )
            ]
        )
        let studio = SiteClawStudio(
            restaurant: profile,
            draft: .placeholder,
            messages: [],
            updates: [],
            metrics: [],
            isDraftGenerated: false
        )

        studio.generateDraft()

        XCTAssertEqual(
            studio.restaurant.menuItems.first?.description,
            "Crisp fries that pair naturally with burgers, sandwiches, and cold drinks."
        )
    }

    func testGenerateDraftRepairsTruncatedSunsetGrillFriesPrice() {
        let profile = RestaurantProfile(
            name: "Sunset Grill",
            cuisine: "American restaurant",
            neighborhood: "San Jose",
            ownerName: "",
            phone: "",
            hours: "Monday through Saturday 10 AM to 8 PM and Sunday 11 AM to 6 PM",
            story: "Fresh ingredients, fast service, and a friendly neighborhood atmosphere",
            menuItems: [
                MenuItem(name: "Cheeseburgers", description: "", price: 12.99),
                MenuItem(name: "Chicken Sandwiches", description: "", price: 11.49),
                MenuItem(name: "Fries", description: "", price: 4),
                MenuItem(name: "Lemonade", description: "", price: 3.49)
            ]
        )
        let studio = SiteClawStudio(
            restaurant: profile,
            draft: .placeholder,
            messages: [],
            updates: [],
            metrics: [],
            isDraftGenerated: false
        )

        studio.generateDraft()

        XCTAssertEqual(studio.restaurant.menuItems.first { $0.name == "Fries" }?.price, 4.99)
        XCTAssertEqual(studio.restaurantJSON.menu.categories.first?.items.first { $0.name == "Fries" }?.price, 4.99)
    }

    func testGenerateDraftAvoidsRestaurantAsOfferWhenMenuIsMissing() {
        let profile = RestaurantProfile(
            name: "Sunset Grill",
            cuisine: "American restaurant",
            neighborhood: "San Jose",
            ownerName: "",
            phone: "",
            hours: "Monday through Saturday 10 AM to 8 PM and Sunday 11 AM to 6 PM",
            story: "Fresh ingredients, fast service, and friendly neighborhood atmosphere",
            menuItems: []
        )
        let studio = SiteClawStudio(
            restaurant: profile,
            draft: .placeholder,
            messages: [],
            updates: [],
            metrics: [],
            isDraftGenerated: false
        )

        studio.generateDraft()

        XCTAssertEqual(studio.draft.headline, "Sunset Grill serves American food in San Jose")
        XCTAssertFalse(studio.draft.headline.localizedCaseInsensitiveContains("serves American restaurant"))
    }

    func testGeneratedSiteExportContainsRestaurantSiteEssentials() {
        let json = RestaurantJSONExporter.makeRestaurantJSON(from: .sample, draft: .sample)

        let export = GeneratedSiteRenderer.makeExport(from: json, draft: .sample)

        XCTAssertEqual(export.slug, "sunset-grill")
        XCTAssertEqual(export.defaultFilename, "sunset-grill-index")
        XCTAssertTrue(export.html.contains("<title>Sunset Grill | American restaurant in San Jose</title>"))
        XCTAssertTrue(export.html.contains("Cheeseburgers"))
        XCTAssertTrue(export.html.contains("$12.99"))
        XCTAssertTrue(export.html.contains(##"<a href="#home">Home</a>"##))
        XCTAssertTrue(export.html.contains(##"<a href="#menu">Menu</a>"##))
        XCTAssertTrue(export.html.contains(##"<a href="#hours">Hours</a>"##))
        XCTAssertTrue(export.html.contains(##"<a href="#location">Location</a>"##))
        XCTAssertTrue(export.html.contains("Mon-Sat 10 AM to 8 PM; Sun 11 AM to 6 PM"))
        XCTAssertTrue(export.html.contains("Popular picks include Cheeseburgers, Chicken Sandwiches, Fries, Lemonade."))
        XCTAssertTrue(export.html.contains("Plan your visit"))
        XCTAssertTrue(export.html.contains("Visit Sunset Grill in San Jose"))
        XCTAssertTrue(export.html.contains("Stop by for burgers, sandwiches, fries, lemonade, and a friendly neighborhood meal in San Jose."))
        XCTAssertTrue(export.html.contains("Hours &amp; Location"))
        XCTAssertTrue(export.html.contains("application/ld+json"))
        XCTAssertFalse(export.html.contains("Phone not provided yet"))
        XCTAssertFalse(export.html.contains("Stop by for Cheeseburgers, Chicken Sandwiches, Fries and"))
        XCTAssertFalse(export.html.contains("owner-provided"))
        XCTAssertFalse(export.html.contains("Owner-approved menu detail."))
        XCTAssertFalse(export.html.contains("Draft detail needed before publishing."))
        XCTAssertFalse(export.html.contains("Ready for owner review"))
        XCTAssertFalse(export.html.contains("This website draft is ready to refine."))
        XCTAssertFalse(export.html.contains("Generated by SiteClaw"))
    }

    func testGeneratedSiteExportCleansAwkwardStoryLeadIn() {
        var json = RestaurantJSONExporter.makeRestaurantJSON(from: .sample, draft: .sample)
        json.basics.description = "Its fresh ingredients, fast service, and friendly neighborhood atmosphere"
        json.seo.description = "Its fresh ingredients, fast service, and friendly neighborhood atmosphere"

        let export = GeneratedSiteRenderer.makeExport(from: json, draft: .sample)

        XCTAssertTrue(export.html.contains("Fresh ingredients, fast service, and friendly neighborhood atmosphere"))
        XCTAssertFalse(export.html.contains("Its fresh ingredients"))
    }
}

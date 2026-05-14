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

    func testVoiceTranscriptNormalizerRemovesFillerSpeech() {
        let transcript = "Um, let's say Tuesday through Saturday from ten AM to five PM, uh, and Sunday from eleven AM to three PM."

        let normalized = VoiceTranscriptNormalizer.normalize(transcript)

        XCTAssertFalse(normalized.localizedCaseInsensitiveContains("um"))
        XCTAssertFalse(normalized.localizedCaseInsensitiveContains("uh"))
        XCTAssertFalse(normalized.localizedCaseInsensitiveContains("let's say"))
        XCTAssertTrue(normalized.contains("Tuesday through Saturday"))
        XCTAssertTrue(normalized.contains("10 AM to 5 PM"))
    }

    func testVoicePromptInterpreterCleansShortRestaurantNameAnswer() {
        let answer = VoicePromptAnswerInterpreter.interpret(
            promptIndex: 0,
            extractedAnswer: "",
            fallbackAnswer: "Um, Thai Palace."
        )

        XCTAssertEqual(answer, "Thai Palace")
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

    func testTranscriptExtractorKeepsArgentinianCuisineOutOfHours() {
        let transcript = """
        My restaurant is called Pampas Table. Um we serve Argentinian food in San Jose. \
        Let's say Tuesday through Saturday from 10 AM to 5 PM, special hours on Sunday from 11 AM to 3 PM. \
        We do Argentinian food with empanadas and grilled sandwiches.
        """

        let extraction = TranscriptRestaurantExtractor.extract(from: transcript)
        let profile = extraction.profile
        let json = RestaurantJSONExporter.makeRestaurantJSON(from: profile, draft: .placeholder)

        XCTAssertEqual(profile.cuisine, "Argentinian restaurant")
        XCTAssertTrue(profile.hours.contains("Tuesday through Saturday"))
        XCTAssertTrue(profile.hours.contains("Sunday"))
        XCTAssertFalse(profile.hours.localizedCaseInsensitiveContains("Argentinian"))
        XCTAssertTrue(json.hours.monday.isEmpty)
        XCTAssertEqual(json.hours.tuesday.first?.open, "10:00")
        XCTAssertEqual(json.hours.saturday.first?.close, "17:00")
        XCTAssertEqual(json.hours.sunday.first?.open, "11:00")
        XCTAssertEqual(json.hours.sunday.first?.close, "15:00")
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

    func testPromptCaptureInfersRestaurantNameFromMessyShortSpeech() {
        let studio = SiteClawStudio(
            restaurant: .empty,
            draft: .placeholder,
            messages: [],
            updates: [],
            metrics: [],
            voiceTranscript: "",
            pendingVoiceAnswer: "Um, the restaurant is called Thai Palace.",
            activeVoicePromptIndex: 0,
            isDraftGenerated: false
        )

        studio.captureCurrentVoicePrompt()

        XCTAssertEqual(studio.restaurant.name, "Thai Palace")
        XCTAssertEqual(studio.voicePrompts[0].capturedAnswer, "Thai Palace")
        XCTAssertEqual(studio.activeVoicePromptIndex, 1)
        XCTAssertTrue(studio.pendingVoiceAnswer.isEmpty)
    }

    func testPromptCaptureUsesShortNameAnswerWhenOwnerOnlySaysTheName() {
        let studio = SiteClawStudio(
            restaurant: .empty,
            draft: .placeholder,
            messages: [],
            updates: [],
            metrics: [],
            voiceTranscript: "",
            pendingVoiceAnswer: "like um Thai Palace",
            activeVoicePromptIndex: 0,
            isDraftGenerated: false
        )

        studio.captureCurrentVoicePrompt()

        XCTAssertEqual(studio.restaurant.name, "Thai Palace")
        XCTAssertEqual(studio.voicePrompts[0].capturedAnswer, "Thai Palace")
    }

    func testTranscriptExtractorCapturesRestaurantNameFromNaturalSentence() {
        let extraction = TranscriptRestaurantExtractor.extract(from: "The name of the restaurant is Plata.")

        XCTAssertEqual(extraction.profile.name, "Plata")
        XCTAssertEqual(extraction.promptAnswers[0], "Plata")
    }

    func testTranscriptExtractorHandlesSalvadorianAndPeruvianCuisineLocation() {
        let extraction = TranscriptRestaurantExtractor.extract(from: "It does Salvadorian and Peruvian food in San Jose.")

        XCTAssertEqual(extraction.profile.cuisine, "Salvadorian and Peruvian restaurant")
        XCTAssertEqual(extraction.profile.neighborhood, "San Jose")
        XCTAssertEqual(extraction.promptAnswers[1], "Salvadorian and Peruvian restaurant in San Jose")
    }

    func testGuidedVoiceCaptureFillsBuildBasicsAndOverwritesStaleDefaults() {
        var staleProfile = RestaurantProfile.sample
        staleProfile.name = "Old Name"
        staleProfile.cuisine = "American restaurant"
        staleProfile.neighborhood = "Oakland"
        staleProfile.hours = "Old hours"
        staleProfile.story = "Old story"

        let studio = SiteClawStudio(
            restaurant: staleProfile,
            draft: .placeholder,
            messages: [],
            updates: [],
            metrics: [],
            voiceTranscript: "",
            activeVoicePromptIndex: 0,
            isDraftGenerated: false
        )

        studio.pendingVoiceAnswer = "The restaurant is called Plata Catering."
        studio.captureCurrentVoicePrompt()
        studio.pendingVoiceAnswer = "It does Salvadorian and Peruvian food in San Jose."
        studio.captureCurrentVoicePrompt()
        studio.pendingVoiceAnswer = "Hours of operation are like 11 to 6 and that's Monday through Saturday."
        studio.captureCurrentVoicePrompt()
        studio.pendingVoiceAnswer = "Pupusas for $12.99, ceviche for $18, lomo saltado for $19, and tamales for $8."
        studio.captureCurrentVoicePrompt()
        studio.pendingVoiceAnswer = "Family recipes from El Salvador and Peru make the restaurant feel welcoming."
        studio.captureCurrentVoicePrompt()

        XCTAssertEqual(studio.restaurant.name, "Plata Catering")
        XCTAssertEqual(studio.restaurant.cuisine, "Salvadorian and Peruvian restaurant")
        XCTAssertEqual(studio.restaurant.neighborhood, "San Jose")
        XCTAssertTrue(studio.restaurant.hours.contains("Monday through Saturday"))
        XCTAssertTrue(studio.restaurant.hours.contains("11 to 6"))
        XCTAssertEqual(studio.restaurant.menuItems.map(\.name), ["Pupusas", "Ceviche", "Lomo Saltado", "Tamales"])
        XCTAssertEqual(studio.restaurant.menuItems.map(\.price), [12.99, 18, 19, 8])
        XCTAssertEqual(studio.restaurant.story, "Family recipes from El Salvador and Peru make the restaurant feel welcoming")
        XCTAssertFalse(studio.restaurant.story.localizedCaseInsensitiveContains("hours"))
        XCTAssertFalse(studio.restaurant.story.localizedCaseInsensitiveContains("Plata Catering"))
    }

    func testApplyEditedCuisineLocationUpdatesBothFields() {
        var profile = RestaurantProfile.sample
        profile.cuisine = "American restaurant"
        profile.neighborhood = "Oakland"
        let studio = SiteClawStudio(
            restaurant: profile,
            draft: .placeholder,
            messages: [],
            updates: [],
            metrics: [],
            voiceTranscript: "",
            activeVoicePromptIndex: 1,
            isDraftGenerated: false
        )
        studio.voicePrompts[1].capturedAnswer = "We do Salvadorian and Peruvian food in San Jose."

        studio.applyEditedVoicePromptAnswer()

        XCTAssertEqual(studio.restaurant.cuisine, "Salvadorian and Peruvian restaurant")
        XCTAssertEqual(studio.restaurant.neighborhood, "San Jose")
        XCTAssertEqual(studio.voicePrompts[1].capturedAnswer, "Salvadorian and Peruvian restaurant in San Jose")
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

    func testRestaurantJSONExporterIncludesVisibilityLinksAndFullContact() {
        var profile = RestaurantProfile.sample
        profile.streetAddress = "1234 Sunset Avenue"
        profile.state = "CA"
        profile.postalCode = "95112"
        profile.phone = "(408) 555-0147"
        profile.visibility.googleBusinessProfileURL = "https://business.google.com/sunset-grill"
        profile.visibility.googleReviewURL = "https://g.page/r/sunset-grill/review"
        profile.visibility.yelpBusinessURL = "https://www.yelp.com/biz/sunset-grill-san-jose"
        profile.visibility.instagramURL = "https://instagram.com/sunsetgrill"
        profile.visibility.googleBusinessProfileClaimed = true
        profile.visibility.restaurantPhotosAdded = true

        let json = RestaurantJSONExporter.makeRestaurantJSON(from: profile, draft: .sample)

        XCTAssertEqual(json.contact.phone, "(408) 555-0147")
        XCTAssertEqual(json.contact.address.street, "1234 Sunset Avenue")
        XCTAssertEqual(json.contact.address.city, "San Jose")
        XCTAssertEqual(json.contact.address.state, "CA")
        XCTAssertEqual(json.contact.address.zip, "95112")
        XCTAssertEqual(json.visibility.googleBusinessProfileURL, "https://business.google.com/sunset-grill")
        XCTAssertEqual(json.visibility.googleReviewURL, "https://g.page/r/sunset-grill/review")
        XCTAssertEqual(json.visibility.yelpBusinessURL, "https://www.yelp.com/biz/sunset-grill-san-jose")
        XCTAssertTrue(json.visibility.googleBusinessProfileClaimed)
        XCTAssertTrue(json.visibility.restaurantPhotosAdded)
    }

    func testRestaurantJSONExporterIncludesUploadedMenuAsset() {
        var profile = RestaurantProfile.sample
        let data = Data("sample menu pdf".utf8)
        profile.uploadedMenu = UploadedMenuAsset.make(
            filename: "pampas-menu.pdf",
            mediaType: "application/pdf",
            kind: .pdf,
            data: data
        )

        let json = RestaurantJSONExporter.makeRestaurantJSON(from: profile, draft: .sample)

        XCTAssertEqual(json.menu.uploadedAsset?.filename, "pampas-menu.pdf")
        XCTAssertEqual(json.menu.uploadedAsset?.mediaType, "application/pdf")
        XCTAssertEqual(json.menu.uploadedAsset?.kind, "pdf")
        XCTAssertTrue(json.menu.uploadedAsset?.dataURL.contains("data:application/pdf;base64,") ?? false)
    }

    func testDemoUploadedMenuAssetUsesSunsetGrillMenuImage() {
        let asset = UploadedMenuAsset.sunsetGrillDemo
        let base64 = asset.dataURL.components(separatedBy: "base64,").last ?? ""
        let decoded = Data(base64Encoded: base64) ?? Data()

        XCTAssertEqual(asset.filename, "sunset-grill-demo-menu.png")
        XCTAssertEqual(asset.mediaType, "image/png")
        XCTAssertEqual(asset.kind, .image)
        XCTAssertTrue(asset.dataURL.hasPrefix("data:image/png;base64,"))
        XCTAssertEqual(decoded.prefix(8), Data([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]))
        XCTAssertEqual(pngDimension(in: decoded, byteOffset: 16), 1103)
        XCTAssertEqual(pngDimension(in: decoded, byteOffset: 20), 1426)
        XCTAssertGreaterThan(asset.byteCount, 2_000_000)
    }

    func testDemoUploadedMenuExtractorReturnsFeaturedBurgerItems() {
        let result = UploadedMenuItemExtractor.extractItems(from: .sunsetGrillDemo)

        XCTAssertTrue(result.didExtractItems)
        XCTAssertEqual(result.items.map(\.name), [
            "Sunset Smash Burger",
            "BBQ Bacon Cheeseburger",
            "Crispy Chicken Sandwich",
            "Grilled Mahi Sandwich"
        ])
        XCTAssertEqual(result.items.map(\.price), [17, 18, 16, 18])
        XCTAssertTrue(result.items.allSatisfy { !$0.description.isEmpty })
        XCTAssertEqual(
            result.items.first?.description,
            "A signature smash burger with crisp edges, melty cheese, and casual grill flavor."
        )
    }

    func testApplyingDemoUploadedMenuToProfileReplacesFeaturedMenuItems() {
        var profile = RestaurantProfile.sample

        let result = profile.applyUploadedMenuAsset(.sunsetGrillDemo)

        XCTAssertTrue(result.didExtractItems)
        XCTAssertEqual(profile.uploadedMenu?.filename, "sunset-grill-demo-menu.png")
        XCTAssertEqual(profile.menuItems.map(\.name), [
            "Sunset Smash Burger",
            "BBQ Bacon Cheeseburger",
            "Crispy Chicken Sandwich",
            "Grilled Mahi Sandwich"
        ])
        XCTAssertEqual(profile.menuItems.map(\.price), [17, 18, 16, 18])
    }

    func testApplyingNonExtractableUploadedMenuToProfilePreservesFeaturedMenuItems() {
        var profile = RestaurantProfile.sample
        let originalItems = profile.menuItems
        let asset = UploadedMenuAsset.make(
            filename: "owner-menu.pdf",
            mediaType: "application/pdf",
            kind: .pdf,
            data: Data("pdf bytes".utf8)
        )

        let result = profile.applyUploadedMenuAsset(asset)

        XCTAssertFalse(result.didExtractItems)
        XCTAssertEqual(result.statusMessage, "Menu uploaded; structured extraction coming soon.")
        XCTAssertEqual(profile.uploadedMenu?.filename, "owner-menu.pdf")
        XCTAssertEqual(profile.menuItems, originalItems)
    }

    func testRestaurantJSONExporterUsesBrandCustomization() {
        var profile = RestaurantProfile.sample
        profile.branding = SiteBrandingSettings(
            primaryColorHex: "#0E3B2E",
            accentColorHex: "#F4B942",
            fontStyle: "Classic"
        )

        let json = RestaurantJSONExporter.makeRestaurantJSON(from: profile, draft: .sample)

        XCTAssertEqual(json.branding.primaryColor, "#0E3B2E")
        XCTAssertEqual(json.branding.accentColor, "#F4B942")
        XCTAssertEqual(json.branding.fontStyle, "Classic")
    }

    func testRestaurantJSONExporterIncludesDesignBriefAndConversionLinks() {
        var profile = RestaurantProfile.sample
        profile.features.onlineOrderingURL = "https://order.example.com/sunset"
        profile.features.reservationURL = "https://resy.com/cities/sj/sunset-grill"
        var draft = WebsiteDraft.sample
        draft.callToAction = "Order Online"
        draft.designBrief = RestaurantDesignBrief(archetype: .fastCasualOrderFirst)

        let json = RestaurantJSONExporter.makeRestaurantJSON(from: profile, draft: draft)

        XCTAssertEqual(json.designBrief.archetype, "fast_casual_order_first")
        XCTAssertEqual(json.designBrief.primaryCTA, "Order Online")
        XCTAssertEqual(json.features.onlineOrderingURL, "https://order.example.com/sunset")
        XCTAssertEqual(json.features.reservationURL, "https://resy.com/cities/sj/sunset-grill")
    }

    func testRestaurantJSONExporterIncludesCateringEmail() {
        var profile = RestaurantProfile.sample
        profile.cateringEmail = "catering@example.com"

        let json = RestaurantJSONExporter.makeRestaurantJSON(from: profile, draft: .sample)

        XCTAssertEqual(json.contact.cateringEmail, "catering@example.com")
    }

    func testRestaurantJSONDecodesMissingDesignBriefWithNeighborhoodFallback() throws {
        let json = RestaurantJSONExporter.makeRestaurantJSON(from: .sample, draft: .sample)
        let encoded = try JSONEncoder().encode(json)
        var object = try XCTUnwrap(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
        object.removeValue(forKey: "design_brief")
        object.removeValue(forKey: "features")
        let legacyData = try JSONSerialization.data(withJSONObject: object)

        let decoded = try JSONDecoder().decode(RestaurantJSON.self, from: legacyData)

        XCTAssertEqual(decoded.designBrief.archetype, "neighborhood_utility")
        XCTAssertEqual(decoded.designBrief.primaryCTA, "View Menu")
        XCTAssertEqual(decoded.features, .empty)
    }

    func testProfileExtractionResponseDecodesPatchAndSuggestedArchetype() throws {
        let data = """
        {
          "reply": "Polished the captured profile.",
          "restaurant_patch": {
            "name": "Plata Catering",
            "cuisine": "Salvadorian and Peruvian restaurant",
            "neighborhood": "San Jose",
            "hours": "Monday through Saturday 11 AM to 6 PM",
            "story": "Family recipes make the restaurant feel welcoming.",
            "menu_items": [
              { "name": "Pupusas", "description": "A signature dish.", "price": 12.99 }
            ]
          },
          "suggested_archetype": "cultural_heritage"
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(ProfileExtractionResponse.self, from: data)

        XCTAssertEqual(response.restaurantPatch.name, "Plata Catering")
        XCTAssertEqual(response.restaurantPatch.menuItems.first?.price, 12.99)
        XCTAssertEqual(response.suggestedArchetype, .culturalHeritage)
    }

    func testProfileExtractionRequestEncodesCapturedPromptKinds() throws {
        let studio = SiteClawStudio(
            restaurant: .sample,
            draft: .sample,
            messages: [],
            updates: [],
            metrics: []
        )
        studio.voicePrompts[1].capturedAnswer = "Salvadorian and Peruvian restaurant in San Jose"

        let data = try JSONEncoder().encode(ProfileExtractionRequest(studio: studio))
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        let capturedAnswers = try XCTUnwrap(object["captured_answers"] as? [[String: Any]])

        XCTAssertEqual(capturedAnswers[1]["prompt_kind"] as? String, "cuisine_location")
        XCTAssertEqual(capturedAnswers[1]["answer"] as? String, "Salvadorian and Peruvian restaurant in San Jose")
    }

    func testVoiceCoachRequestEncodesTurnContext() throws {
        let studio = SiteClawStudio(
            restaurant: .sample,
            draft: .sample,
            messages: [],
            updates: [],
            metrics: []
        )
        studio.pendingVoiceAnswer = "The restaurant is called Plata Catering."
        let request = try XCTUnwrap(studio.captureCurrentVoicePrompt())

        let data = try JSONEncoder().encode(request)
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])

        XCTAssertEqual(object["prompt_kind"] as? String, "restaurant_name")
        XCTAssertEqual(object["cleaned_answer"] as? String, "Plata Catering")
        XCTAssertEqual(studio.restaurant.name, "Plata Catering")
        XCTAssertNotNil(object["restaurant"] as? [String: Any])
        XCTAssertNotNil(object["design_brief"] as? [String: Any])
    }

    func testVoiceCoachResponseAppliesSafePatchAndDesignNotes() {
        let studio = SiteClawStudio(
            restaurant: .sample,
            draft: .sample,
            messages: [],
            updates: [],
            metrics: []
        )
        let request = VoiceCoachRequest(
            studio: studio,
            prompt: studio.voicePrompts[1],
            rawAnswer: "It does Salvadorian and Peruvian food in San Jose.",
            cleanedAnswer: "Salvadorian and Peruvian restaurant in San Jose"
        )
        let response = VoiceCoachResponse(
            cleanedAnswer: "Salvadorian and Peruvian restaurant in San Jose",
            restaurantPatch: ProfileRestaurantPatch(
                name: "Plata Catering",
                cuisine: "Salvadorian and Peruvian restaurant",
                neighborhood: "San Jose",
                hours: "",
                story: "Family recipes from El Salvador and Peru make the restaurant feel welcoming.",
                menuItems: []
            ),
            confidence: .high,
            missingDetails: ["Add exact hours"],
            suggestedFollowUp: "What family recipe or signature dish should the story mention?",
            archetypeHint: .culturalHeritage,
            designNotes: ["Heritage story section because the owner mentioned Salvadorian and Peruvian roots."],
            statusMessage: "Cleaned cuisine, location, and heritage direction."
        )

        studio.applyVoiceCoachResponse(response, for: request)

        XCTAssertEqual(studio.restaurant.name, "Plata Catering")
        XCTAssertEqual(studio.restaurant.features, .empty)
        XCTAssertEqual(studio.draft.designBrief.resolvedArchetype, .culturalHeritage)
        XCTAssertTrue(studio.aiDesignDecisionSummary.contains { $0.localizedCaseInsensitiveContains("Heritage story section") })
        XCTAssertEqual(studio.activeSuggestedFollowUp, "What family recipe or signature dish should the story mention?")
    }

    func testAIDesignStrategyExportsToRestaurantJSONAndGenerationRequest() throws {
        let studio = SiteClawStudio(
            restaurant: .sample,
            draft: .sample,
            messages: [],
            updates: [],
            metrics: []
        )
        let request = VoiceCoachRequest(
            studio: studio,
            prompt: studio.voicePrompts[4],
            rawAnswer: "My grandparents started the recipe.",
            cleanedAnswer: "My grandparents started the recipe."
        )
        let response = VoiceCoachResponse(
            cleanedAnswer: "My grandparents started the recipe.",
            restaurantPatch: ProfileRestaurantPatch(name: "", cuisine: "", neighborhood: "", hours: "", story: "My grandparents started the recipe.", menuItems: []),
            confidence: .high,
            missingDetails: [],
            suggestedFollowUp: "",
            archetypeHint: .culturalHeritage,
            designNotes: ["Heritage story section because the owner mentioned grandparents and a recipe."],
            statusMessage: "Added a stronger heritage story cue."
        )

        studio.applyVoiceCoachResponse(response, for: request)

        XCTAssertTrue(studio.restaurantJSON.designBrief.designDecisions.contains { $0.localizedCaseInsensitiveContains("grandparents") })

        let data = try JSONEncoder().encode(SiteGenerationRequest(studio: studio))
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        let strategy = try XCTUnwrap(object["site_strategy"] as? [String: Any])
        let decisions = try XCTUnwrap(strategy["design_decisions"] as? [String])

        XCTAssertTrue(decisions.contains { $0.localizedCaseInsensitiveContains("grandparents") })
    }

    func testVoiceCoachFailurePreservesLocalCapture() {
        let studio = SiteClawStudio(
            restaurant: .sample,
            draft: .sample,
            messages: [],
            updates: [],
            metrics: []
        )
        studio.pendingVoiceAnswer = "The restaurant is called Thai Palace."
        let request = studio.captureCurrentVoicePrompt()

        studio.failVoiceCoachTurn(NSError(domain: "SiteClawTests", code: 1), for: try! XCTUnwrap(request))

        XCTAssertEqual(studio.restaurant.name, "Thai Palace")
        XCTAssertEqual(studio.voiceCoachTurns.count, 0)
        XCTAssertEqual(studio.voiceCoachStatus, "AI coach unavailable. Local capture is still saved.")
    }

    func testLowConfidenceVoiceCoachShowsMissingDetailsWithoutBlockingBuild() {
        let studio = SiteClawStudio(
            restaurant: .sample,
            draft: .sample,
            messages: [],
            updates: [],
            metrics: []
        )
        let request = VoiceCoachRequest(
            studio: studio,
            prompt: studio.voicePrompts[2],
            rawAnswer: "Usually afternoons.",
            cleanedAnswer: "Usually afternoons."
        )
        let response = VoiceCoachResponse(
            cleanedAnswer: "Usually afternoons.",
            restaurantPatch: ProfileRestaurantPatch(name: "", cuisine: "", neighborhood: "", hours: "", story: "", menuItems: []),
            confidence: .low,
            missingDetails: ["Ask for exact days and hours."],
            suggestedFollowUp: "Which days are you open, and what time do you open and close?",
            archetypeHint: .neighborhoodUtility,
            designNotes: [],
            statusMessage: "The hours answer needs a clearer follow-up."
        )

        studio.applyVoiceCoachResponse(response, for: request)

        XCTAssertEqual(studio.latestVoiceCoachTurn?.confidence, .low)
        XCTAssertEqual(studio.latestVoiceCoachTurn?.missingDetails, ["Ask for exact days and hours."])
        XCTAssertTrue(studio.canPublishSite)
        XCTAssertEqual(studio.activeSuggestedFollowUp, "Which days are you open, and what time do you open and close?")
    }

    func testVoiceCoachFollowUpImprovesStoryWithoutDumpingAllAnswers() {
        var profile = RestaurantProfile.sample
        profile.story = ""
        let studio = SiteClawStudio(
            restaurant: profile,
            draft: .sample,
            messages: [],
            updates: [],
            metrics: []
        )
        studio.activeSuggestedFollowUp = "What family recipe should the story mention?"

        let request = studio.applyVoiceCoachFollowUpAnswer("Our family pupusa recipe comes from my grandmother.")

        XCTAssertNotNil(request)
        XCTAssertTrue(studio.voiceTranscript.contains("family pupusa recipe"))
        XCTAssertFalse(studio.restaurant.story.contains("Sunset Grill is an American burger"))
    }

    func testVoiceCoachMenuFollowUpNarrowsFeaturedDishesWithoutAppendingToActiveStep() {
        var profile = RestaurantProfile.sample
        profile.menuItems = [
            MenuItem(name: "Arepas", description: "Corn cakes with savory fillings.", price: nil),
            MenuItem(name: "Tostones", description: "Crispy plantains.", price: nil),
            MenuItem(name: "Empanadas", description: "Hand pies with seasoned fillings.", price: nil)
        ]
        let studio = SiteClawStudio(
            restaurant: profile,
            draft: .sample,
            messages: [],
            updates: [],
            metrics: []
        )
        let featuredIndex = try! XCTUnwrap(studio.voicePrompts.firstIndex { $0.promptKind == .featuredDishes })
        studio.activeVoicePromptIndex = featuredIndex
        studio.voicePrompts[featuredIndex].capturedAnswer = "Arepas, Tostones, Empanadas"
        studio.pendingVoiceAnswer = "Arepas, Tostones, Empanadas"
        studio.activeSuggestedFollowUp = "Which 1-2 items should be the main homepage best sellers?"
        studio.voiceCoachTurns = [
            VoiceCoachTurn(
                promptKind: .featuredDishes,
                question: studio.voicePrompts[featuredIndex].question,
                rawAnswer: "Arepas, tostones, empanadas",
                cleanedAnswer: "Arepas, Tostones, Empanadas",
                confidence: .medium,
                missingDetails: [],
                suggestedFollowUp: studio.activeSuggestedFollowUp,
                archetypeHint: nil,
                designNotes: [],
                statusMessage: "Pick one or two."
            )
        ]

        let request = studio.applyVoiceCoachFollowUpAnswer("Arepas and empanadas for sure")

        XCTAssertEqual(request?.promptKind, VoicePromptKind.featuredDishes.rawValue)
        XCTAssertEqual(studio.restaurant.menuItems.map(\.name), ["Arepas", "Empanadas"])
        XCTAssertEqual(studio.voicePrompts[featuredIndex].capturedAnswer, "Arepas, Empanadas")
        XCTAssertEqual(studio.pendingVoiceAnswer, "")
        XCTAssertTrue(studio.voiceTranscript.contains("Follow-up:"))
        XCTAssertFalse(studio.voicePrompts[featuredIndex].capturedAnswer.localizedCaseInsensitiveContains("tostones"))
    }

    func testApplyingProfileExtractionCannotInventConversionLinks() {
        let response = ProfileExtractionResponse(
            reply: "Polished profile.",
            restaurantPatch: ProfileRestaurantPatch(
                name: "Plata Catering",
                cuisine: "Salvadorian and Peruvian restaurant",
                neighborhood: "San Jose",
                hours: "Monday through Saturday 11 AM to 6 PM",
                story: "Family recipes make the restaurant feel welcoming.",
                menuItems: []
            ),
            suggestedArchetype: .culturalHeritage
        )
        let studio = SiteClawStudio(
            restaurant: .sample,
            draft: .sample,
            messages: [],
            updates: [],
            metrics: []
        )

        studio.applyProfileExtraction(response)

        XCTAssertEqual(studio.restaurant.name, "Plata Catering")
        XCTAssertEqual(studio.restaurant.features, .empty)
        XCTAssertEqual(studio.draft.designBrief.resolvedArchetype, .culturalHeritage)
    }

    func testRestaurantArchetypePreviewSpecsDriveVisibleNativePreviewDifferences() {
        let orderFirst = RestaurantArchetypePreviewSpec.spec(for: .fastCasualOrderFirst)
        let fineDining = RestaurantArchetypePreviewSpec.spec(for: .fineDiningReservationFirst)
        let heritage = RestaurantArchetypePreviewSpec.spec(for: .culturalHeritage)

        XCTAssertEqual(orderFirst.menuHeading, "Best Sellers")
        XCTAssertEqual(orderFirst.primaryCTA, "Order Online")
        XCTAssertEqual(orderFirst.sectionOrder.first, .menu)
        XCTAssertEqual(fineDining.storyHeading, "The Experience")
        XCTAssertEqual(fineDining.primaryCTA, "Reserve a Table")
        XCTAssertEqual(fineDining.sectionOrder, [.story, .visit, .menu])
        XCTAssertEqual(heritage.menuHeading, "Signature Dishes")
        XCTAssertEqual(heritage.heroKicker, "Rooted in tradition")
    }

    func testBillingPlanOptionsExposePlanChoices() {
        XCTAssertEqual(SiteClawBillingPlan.options.map(\.name), ["Starter", "Growth", "Pro"])
        XCTAssertEqual(SiteClawBillingPlan.options[1].displayName, "Growth - $49/mo")
        XCTAssertEqual(SiteClawBillingPlan.options[2].features.count, 3)

        let studio = SiteClawStudio(
            restaurant: .sample,
            draft: .sample,
            messages: [],
            updates: [],
            metrics: [],
            monthlyPrice: 19
        )
        XCTAssertFalse(studio.hasGrowthToolkitAccess)
        studio.selectBillingPlan(SiteClawBillingPlan.options[1])
        XCTAssertTrue(studio.hasGrowthToolkitAccess)
    }

    func testFillDemoVisitDetailsPopulatesContactAndMarksExportStale() {
        let studio = SiteClawStudio(
            restaurant: .sample,
            draft: .sample,
            messages: [],
            updates: [],
            metrics: [],
            siteExportStatus: "sunset-grill-index.html is ready to save or share.",
            lastSiteExportedAt: Date()
        )

        studio.fillDemoVisitDetails()

        XCTAssertEqual(studio.restaurant.streetAddress, "1234 Sunset Avenue")
        XCTAssertEqual(studio.restaurant.neighborhood, "San Jose")
        XCTAssertEqual(studio.restaurant.state, "CA")
        XCTAssertEqual(studio.restaurant.postalCode, "95112")
        XCTAssertEqual(studio.restaurant.phone, "(408) 555-0147")
        XCTAssertEqual(studio.restaurant.cateringEmail, "catering@example.com")
        XCTAssertNil(studio.lastSiteExportedAt)
        XCTAssertEqual(studio.siteExportStatus, "Demo visit details added. Refresh the site export when ready.")
    }

    func testUpdatingRestaurantBasicsMarksExportStale() {
        let studio = SiteClawStudio(
            restaurant: .sample,
            draft: .sample,
            messages: [],
            updates: [],
            metrics: [],
            siteExportStatus: "sunset-grill-index.html is ready to save or share.",
            lastSiteExportedAt: Date(),
            publishStage: .preview
        )

        studio.updateRestaurantBasic(\.story, to: "The atmosphere, the hospitality, the smell in the air")

        XCTAssertEqual(studio.restaurant.story, "The atmosphere, the hospitality, the smell in the air")
        XCTAssertNil(studio.lastSiteExportedAt)
        XCTAssertTrue(studio.isSiteExportStale)
        XCTAssertEqual(studio.siteExportStatus, "Restaurant details changed. Refresh the site export when ready.")
        XCTAssertEqual(studio.publishStage, .draft)
    }

    func testFillDemoConversionLinksPopulatesAllFeatureURLs() {
        let studio = SiteClawStudio(
            restaurant: .sample,
            draft: .sample,
            messages: [],
            updates: [],
            metrics: [],
            siteExportStatus: "sunset-grill-index.html is ready to save or share.",
            lastSiteExportedAt: Date()
        )

        studio.fillDemoConversionLinks()

        XCTAssertEqual(studio.restaurant.features, .sunsetGrillDemo)
        XCTAssertEqual(studio.restaurant.features.onlineOrderingURL, "https://example.com/sunset-grill/order")
        XCTAssertEqual(studio.restaurant.features.reservationURL, "https://example.com/sunset-grill/reservations")
        XCTAssertEqual(studio.restaurant.features.giftCardURL, "https://example.com/sunset-grill/gift-cards")
        XCTAssertEqual(studio.restaurant.features.cateringURL, "https://example.com/sunset-grill/catering")
        XCTAssertEqual(studio.restaurant.features.privateDiningURL, "https://example.com/sunset-grill/private-dining")
        XCTAssertNil(studio.lastSiteExportedAt)
        XCTAssertEqual(studio.siteExportStatus, "Demo conversion links added. Refresh the site export when ready.")
    }

    func testFillDemoVisibilityDetailsPopulatesChecklistFields() {
        let studio = SiteClawStudio(
            restaurant: .sample,
            draft: .sample,
            messages: [],
            updates: [],
            metrics: [],
            siteExportStatus: "sunset-grill-index.html is ready to save or share.",
            lastSiteExportedAt: Date()
        )

        studio.fillDemoVisibilityDetails()

        XCTAssertEqual(studio.restaurant.visibility, .sunsetGrillDemo)
        XCTAssertEqual(studio.restaurant.visibility.googleBusinessProfileURL, "https://example.com/sunset-grill/google-business-profile")
        XCTAssertEqual(studio.restaurant.visibility.googleReviewURL, "https://example.com/sunset-grill/google-review")
        XCTAssertEqual(studio.restaurant.visibility.yelpBusinessURL, "https://example.com/sunset-grill/yelp")
        XCTAssertEqual(studio.restaurant.visibility.instagramURL, "https://example.com/sunset-grill/instagram")
        XCTAssertEqual(studio.restaurant.visibility.facebookURL, "https://example.com/sunset-grill/facebook")
        XCTAssertTrue(studio.restaurant.visibility.googleBusinessProfileClaimed)
        XCTAssertTrue(studio.restaurant.visibility.restaurantPhotosAdded)
        XCTAssertTrue(studio.restaurant.visibility.websiteLinkedOnProfiles)
        XCTAssertNil(studio.lastSiteExportedAt)
        XCTAssertEqual(studio.siteExportStatus, "Demo visibility details added. Refresh the site export when ready.")
    }

    func testFillDemoGrowthToolsEnablesFullToolkitAndMarksExportStale() {
        let studio = SiteClawStudio(
            restaurant: .sample,
            draft: .sample,
            messages: [],
            updates: [],
            metrics: [],
            siteExportStatus: "sunset-grill-index.html is ready to save or share.",
            lastSiteExportedAt: Date()
        )

        studio.fillDemoGrowthTools()

        XCTAssertEqual(studio.restaurant.growthTools, .fullyLoadedDemo)
        XCTAssertEqual(studio.restaurant.growthTools.enabledLabels.count, 8)
        XCTAssertNil(studio.lastSiteExportedAt)
        XCTAssertEqual(studio.publishStage, .draft)
    }

    func testWorkspaceStoreRoundTripsPortableRestaurantPackage() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("siteclaw-tests-\(UUID().uuidString)", isDirectory: true)
        defer {
            try? FileManager.default.removeItem(at: root)
        }
        let store = SiteClawWorkspaceStore(rootDirectory: root)
        var profile = RestaurantProfile.sample
        profile.cateringEmail = "catering@example.com"
        profile.growthTools = .fullyLoadedDemo
        profile.menuItems[0].image = MenuItemImageAsset.make(
            filename: "burger.png",
            mediaType: "image/png",
            data: Data("image".utf8)
        )
        let studio = SiteClawStudio(
            restaurant: profile,
            draft: .sample,
            messages: [],
            updates: [],
            metrics: [],
            publishStage: .needsRepublish
        )

        XCTAssertTrue(studio.autosaveWorkspace(store: store))

        let restored = SiteClawStudio(
            restaurant: .empty,
            draft: .placeholder,
            messages: [],
            updates: [],
            metrics: []
        )
        XCTAssertTrue(restored.loadSavedWorkspaceIfAvailable(store: store))
        XCTAssertEqual(restored.restaurant.name, "Sunset Grill")
        XCTAssertEqual(restored.restaurant.cateringEmail, "catering@example.com")
        XCTAssertEqual(restored.restaurant.growthTools, .fullyLoadedDemo)
        XCTAssertEqual(restored.restaurant.menuItems.first?.image?.dataURL, profile.menuItems.first?.image?.dataURL)
        XCTAssertEqual(restored.publishStage, .needsRepublish)
    }

    func testQualityAuditBlocksInvalidConversionLinksButAllowsWarnings() {
        var profile = RestaurantProfile.sample
        profile.features.onlineOrderingURL = "not-a-url"
        profile.cateringEmail = "catering@example.com"
        let studio = SiteClawStudio(
            restaurant: profile,
            draft: .sample,
            messages: [],
            updates: [],
            metrics: []
        )

        XCTAssertFalse(studio.canPublishSite)
        XCTAssertTrue(studio.blockingQualityIssues.contains { $0.title == "Conversion Links" })

        studio.restaurant.features.onlineOrderingURL = "https://example.com/order"
        studio.restaurant.streetAddress = ""

        XCTAssertTrue(studio.canPublishSite)
        XCTAssertTrue(studio.siteQualityAuditItems.contains { $0.title == "Address" && $0.severity == .warning })
    }

    func testVoiceCaptureReviewItemsExposeStructuredProfileConfidence() {
        let studio = SiteClawStudio(
            restaurant: .sample,
            draft: .sample,
            messages: [],
            updates: [],
            metrics: []
        )

        let reviewItems = studio.voiceCaptureReviewItems

        XCTAssertEqual(reviewItems.map(\.title), ["Restaurant Name", "Cuisine", "Location", "Hours", "Featured Dishes", "Owner Story"])
        XCTAssertTrue(reviewItems.first { $0.title == "Restaurant Name" }?.isReady ?? false)
        XCTAssertTrue(reviewItems.first { $0.title == "Featured Dishes" }?.isReady ?? false)
    }

    func testPreviewDeviceModesHaveDistinctResponsiveFrames() {
        XCTAssertLessThan(PreviewDeviceMode.phone.previewWidth, PreviewDeviceMode.tablet.previewWidth)
        XCTAssertLessThan(PreviewDeviceMode.tablet.previewWidth, PreviewDeviceMode.desktop.previewWidth)
        XCTAssertEqual(PreviewDeviceMode.allCases.map(\.title), ["Phone", "Tablet", "Desktop"])
    }

    func testVisibilityChecklistProgressUpdatesFromLocalFields() {
        var profile = RestaurantProfile.sample
        XCTAssertLessThan(profile.visibilityChecklistProgress.completed, profile.visibilityChecklistProgress.total)

        profile.streetAddress = "1234 Sunset Avenue"
        profile.state = "CA"
        profile.postalCode = "95112"
        profile.phone = "(408) 555-0147"
        profile.uploadedMenu = .sunsetGrillDemo
        profile.visibility.googleBusinessProfileURL = "https://business.google.com/sunset-grill"
        profile.visibility.googleReviewURL = "https://g.page/r/sunset-grill/review"
        profile.visibility.yelpBusinessURL = "https://www.yelp.com/biz/sunset-grill-san-jose"
        profile.visibility.restaurantPhotosAdded = true
        profile.visibility.websiteLinkedOnProfiles = true

        let progress = profile.visibilityChecklistProgress
        XCTAssertEqual(progress.completed, 9)
        XCTAssertEqual(progress.total, 9)
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
        XCTAssertTrue(export.html.contains("<li><span>Monday</span><strong>10 AM to 8 PM</strong></li>"))
        XCTAssertTrue(export.html.contains("<li><span>Sunday</span><strong>11 AM to 6 PM</strong></li>"))
        XCTAssertTrue(export.html.contains("Popular picks include Cheeseburgers, Chicken Sandwiches, Fries, Lemonade."))
        XCTAssertTrue(export.html.contains("Plan your visit"))
        XCTAssertTrue(export.html.contains("Visit Sunset Grill in San Jose"))
        XCTAssertTrue(export.html.contains("Stop by for burgers, sandwiches, fries, lemonade, and a friendly neighborhood meal in San Jose."))
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

    func testGeneratedSiteExportUsesCurrentRestaurantStoryOverStaleSunsetDraft() {
        var profile = RestaurantProfile.sample
        profile.name = "Plata Catering"
        profile.cuisine = "Venezuelan food"
        profile.neighborhood = "San Diego"
        profile.story = "The atmosphere, the hospitality, the smell in the air"

        let json = RestaurantJSONExporter.makeRestaurantJSON(from: profile, draft: .sample)
        let export = GeneratedSiteRenderer.makeExport(from: json, draft: .sample)

        XCTAssertEqual(json.basics.name, "Plata Catering")
        XCTAssertEqual(json.basics.description, "The atmosphere, the hospitality, the smell in the air")
        XCTAssertEqual(json.seo.description, "The atmosphere, the hospitality, the smell in the air")
        XCTAssertEqual(json.basics.tagline, "Plata Catering serves Venezuelan food in San Diego")
        XCTAssertTrue(export.html.contains("The atmosphere, the hospitality, the smell in the air"))
        XCTAssertTrue(export.html.contains("Plata Catering serves Venezuelan food in San Diego"))
        XCTAssertFalse(export.html.contains("Sunset Grill serves American burgers"))
    }

    func testGeneratedSiteExportEmbedsUploadedMenuAsset() {
        var profile = RestaurantProfile.sample
        profile.uploadedMenu = UploadedMenuAsset.make(
            filename: "sunset-menu.pdf",
            mediaType: "application/pdf",
            kind: .pdf,
            data: Data("pdf bytes".utf8)
        )
        let json = RestaurantJSONExporter.makeRestaurantJSON(from: profile, draft: .sample)

        let export = GeneratedSiteRenderer.makeExport(from: json, draft: .sample)

        XCTAssertTrue(export.html.contains(##"<a href="#menu">Menu</a>"##))
        XCTAssertTrue(export.html.contains("Full Menu"))
        XCTAssertTrue(export.html.contains("View Full Menu"))
        XCTAssertTrue(export.html.contains(#"id="full-menu""#))
        XCTAssertTrue(export.html.contains("uploaded-menu-frame"))
        XCTAssertTrue(export.html.contains("data:application/pdf;base64,"))
    }

    func testGeneratedSiteExportEmbedsDemoMenuAsImageBlock() {
        var profile = RestaurantProfile.sample
        profile.uploadedMenu = .sunsetGrillDemo
        let json = RestaurantJSONExporter.makeRestaurantJSON(from: profile, draft: .sample)

        let export = GeneratedSiteRenderer.makeExport(from: json, draft: .sample)

        XCTAssertTrue(export.html.contains(#"id="full-menu""#))
        XCTAssertTrue(export.html.contains("uploaded-menu-image"))
        XCTAssertTrue(export.html.contains("data:image/png;base64,"))
        XCTAssertFalse(export.html.contains(#"<object class="uploaded-menu-frame""#))
    }

    func testRestaurantJSONExporterIncludesDishImageDataURL() {
        var profile = RestaurantProfile.sample
        profile.menuItems[0].image = MenuItemImageAsset.make(
            filename: "cheeseburger.png",
            mediaType: "image/png",
            data: Data("dish image".utf8)
        )

        let json = RestaurantJSONExporter.makeRestaurantJSON(from: profile, draft: .sample)

        XCTAssertEqual(json.menu.categories.first?.name, "Featured Dishes")
        XCTAssertEqual(
            json.menu.categories.first?.items.first?.imageURL,
            "data:image/png;base64,ZGlzaCBpbWFnZQ=="
        )
    }

    func testGeneratedSiteExportRendersDishImageCardsWhenProvided() {
        var profile = RestaurantProfile.sample
        profile.menuItems[0].image = MenuItemImageAsset.make(
            filename: "cheeseburger.png",
            mediaType: "image/png",
            data: Data("dish image".utf8)
        )
        let json = RestaurantJSONExporter.makeRestaurantJSON(from: profile, draft: .sample)

        let export = GeneratedSiteRenderer.makeExport(from: json, draft: .sample)

        XCTAssertTrue(export.html.contains("Featured Dishes"))
        XCTAssertTrue(export.html.contains(#"<img class="dish-image" src="data:image/png;base64,ZGlzaCBpbWFnZQ==""#))
        XCTAssertTrue(export.html.contains(#"alt="Cheeseburgers""#))
    }

    func testGeneratedSiteExportKeepsDishCardsCleanWithoutImages() {
        let json = RestaurantJSONExporter.makeRestaurantJSON(from: .sample, draft: .sample)

        let export = GeneratedSiteRenderer.makeExport(from: json, draft: .sample)

        XCTAssertTrue(export.html.contains("Featured Dishes"))
        XCTAssertFalse(export.html.contains("Featured Menu"))
        XCTAssertFalse(export.html.contains(#"<img class="dish-image""#))
    }

    func testGeneratedSiteExportUsesFullAddressContactActionsAndSameAsLinks() {
        var profile = RestaurantProfile.sample
        profile.streetAddress = "1234 Sunset Avenue"
        profile.state = "CA"
        profile.postalCode = "95112"
        profile.phone = "(408) 555-0147"
        profile.visibility.googleBusinessProfileURL = "https://business.google.com/sunset-grill"
        profile.visibility.googleReviewURL = "https://g.page/r/sunset-grill/review"
        profile.visibility.yelpBusinessURL = "https://www.yelp.com/biz/sunset-grill-san-jose"
        profile.visibility.instagramURL = "https://instagram.com/sunsetgrill"
        let json = RestaurantJSONExporter.makeRestaurantJSON(from: profile, draft: .sample)

        let export = GeneratedSiteRenderer.makeExport(from: json, draft: .sample)

        XCTAssertTrue(export.html.contains("1234 Sunset Avenue, San Jose, CA 95112"))
        XCTAssertTrue(export.html.contains(#"href="tel:4085550147""#))
        XCTAssertTrue(export.html.contains("Call (408) 555-0147"))
        XCTAssertTrue(export.html.contains("Get Directions"))
        XCTAssertTrue(export.html.contains("https://www.google.com/maps/search/?api=1&amp;query=1234%20Sunset%20Avenue"))
        XCTAssertTrue(export.html.contains("Find us on Yelp"))
        XCTAssertTrue(export.html.contains("Google Business Profile"))
        XCTAssertTrue(export.html.contains("Google Reviews"))
        XCTAssertTrue(export.html.contains(#""sameAs""#))
        XCTAssertTrue(export.html.contains("https://www.yelp.com/biz/sunset-grill-san-jose"))
        XCTAssertFalse(export.html.contains("Review us on Yelp"))
    }

    func testGeneratedSiteRendersCateringContactEmailWhenProvided() {
        var profile = RestaurantProfile.sample
        profile.cateringEmail = "catering@example.com"
        let json = RestaurantJSONExporter.makeRestaurantJSON(from: profile, draft: .sample)

        let export = GeneratedSiteRenderer.makeExport(from: json, draft: .sample)

        XCTAssertTrue(export.html.contains("Catering Contact"))
        XCTAssertTrue(export.html.contains(#"href="mailto:catering@example.com""#))
        XCTAssertTrue(export.html.contains(#""email" : "catering@example.com""#))
    }

    func testGeneratedSiteOmitsCateringContactEmailWhenEmpty() {
        let json = RestaurantJSONExporter.makeRestaurantJSON(from: .sample, draft: .sample)

        let export = GeneratedSiteRenderer.makeExport(from: json, draft: .sample)

        XCTAssertFalse(export.html.contains("Catering Contact"))
        XCTAssertFalse(export.html.contains("mailto:"))
    }

    func testFastCasualGeneratedSitePrioritizesOrderURLWhenProvided() {
        var profile = RestaurantProfile.sample
        profile.features.onlineOrderingURL = "https://order.example.com/sunset"
        var draft = WebsiteDraft.sample
        draft.callToAction = "Order Online"
        draft.designBrief = RestaurantDesignBrief(archetype: .fastCasualOrderFirst)
        let json = RestaurantJSONExporter.makeRestaurantJSON(from: profile, draft: draft)

        let export = GeneratedSiteRenderer.makeExport(from: json, draft: draft)

        XCTAssertTrue(export.html.contains(#"<body class="archetype-fast_casual_order_first">"#))
        XCTAssertTrue(export.html.contains(#"href="https://order.example.com/sunset" target="_blank" rel="noopener">Order Online</a>"#))
        XCTAssertTrue(export.html.contains("Best Sellers"))
        XCTAssertTrue(export.html.contains("Order ahead"))
    }

    func testGeneratedSiteRendersDemoConversionLinksWhenPopulated() {
        var profile = RestaurantProfile.sample
        profile.features = .sunsetGrillDemo
        profile.growthTools = .fullyLoadedDemo
        let json = RestaurantJSONExporter.makeRestaurantJSON(from: profile, draft: .sample)

        let export = GeneratedSiteRenderer.makeExport(from: json, draft: .sample)

        XCTAssertEqual(json.growthTools, .fullyLoadedDemo)
        XCTAssertTrue(export.html.contains(#"href="https://example.com/sunset-grill/order""#))
        XCTAssertTrue(export.html.contains(#"href="https://example.com/sunset-grill/reservations""#))
        XCTAssertTrue(export.html.contains(#"href="https://example.com/sunset-grill/gift-cards""#))
        XCTAssertTrue(export.html.contains(#"href="https://example.com/sunset-grill/catering""#))
        XCTAssertTrue(export.html.contains(#"href="https://example.com/sunset-grill/private-dining""#))
        XCTAssertTrue(export.html.contains("Restaurant Tools"))
        XCTAssertTrue(export.html.contains("QR Menu"))
    }

    func testGeneratedSiteFiltersInvalidVisibilityLinks() {
        var profile = RestaurantProfile.sample
        profile.visibility.instagramURL = "javascript:alert(1)"
        profile.visibility.facebookURL = "https://example.com/facebook"
        let json = RestaurantJSONExporter.makeRestaurantJSON(from: profile, draft: .sample)

        let export = GeneratedSiteRenderer.makeExport(from: json, draft: .sample)

        XCTAssertFalse(export.html.contains("javascript:alert"))
        XCTAssertTrue(export.html.contains("https://example.com/facebook"))
    }

    func testFineDiningGeneratedSitePrioritizesReservationURLWhenProvided() {
        var profile = RestaurantProfile.sample
        profile.features.reservationURL = "https://resy.com/cities/sj/sunset-grill"
        var draft = WebsiteDraft.sample
        draft.callToAction = "Reserve a Table"
        draft.designBrief = RestaurantDesignBrief(archetype: .fineDiningReservationFirst)
        let json = RestaurantJSONExporter.makeRestaurantJSON(from: profile, draft: draft)

        let export = GeneratedSiteRenderer.makeExport(from: json, draft: draft)

        XCTAssertTrue(export.html.contains(#"<body class="archetype-fine_dining_reservation_first">"#))
        XCTAssertTrue(export.html.contains(#"href="https://resy.com/cities/sj/sunset-grill" target="_blank" rel="noopener">Reserve a Table</a>"#))
        XCTAssertTrue(export.html.contains("The Experience"))
        XCTAssertTrue(export.html.contains("Reservations"))
    }

    func testGeneratedSiteIgnoresInvalidConversionURLsAndFallsBackToMenuCTA() {
        var profile = RestaurantProfile.sample
        profile.features.onlineOrderingURL = "not-a-real-order-link"
        profile.features.giftCardURL = "ftp://gift-cards.example.com"
        var draft = WebsiteDraft.sample
        draft.callToAction = "Order Online"
        draft.designBrief = RestaurantDesignBrief(archetype: .fastCasualOrderFirst)
        let json = RestaurantJSONExporter.makeRestaurantJSON(from: profile, draft: draft)

        let export = GeneratedSiteRenderer.makeExport(from: json, draft: draft)

        XCTAssertFalse(export.html.contains("not-a-real-order-link"))
        XCTAssertFalse(export.html.contains("ftp://gift-cards.example.com"))
        XCTAssertFalse(export.html.contains(">Order Online</a>"))
        XCTAssertTrue(export.html.contains(##"<a class="button" href="#menu">View Menu</a>"##))
    }

    func testGeneratedSiteExportCleansAwkwardStoryLeadIn() {
        var json = RestaurantJSONExporter.makeRestaurantJSON(from: .sample, draft: .sample)
        json.basics.description = "Its fresh ingredients, fast service, and friendly neighborhood atmosphere"
        json.seo.description = "Its fresh ingredients, fast service, and friendly neighborhood atmosphere"

        let export = GeneratedSiteRenderer.makeExport(from: json, draft: .sample)

        XCTAssertTrue(export.html.contains("Fresh ingredients, fast service, and friendly neighborhood atmosphere"))
        XCTAssertFalse(export.html.contains("Its fresh ingredients"))
    }

    private func pngDimension(in data: Data, byteOffset: Int) -> Int {
        guard data.count >= byteOffset + 4 else { return -1 }

        return data[byteOffset..<byteOffset + 4].reduce(0) { partial, byte in
            (partial << 8) | Int(byte)
        }
    }
}

# Agent 05 AI Voice Pipeline Evals

This is the first eval pack for Agent 05. Each eval should exist as an automated test when possible and as a prompt/backend contract case when the behavior requires the production AI endpoint.

## Eval Contract

Every voice pipeline eval should preserve:

- Raw transcript
- Cleaned answer
- Extracted fields
- Confidence
- Missing details
- Suggested follow-up

Recommended response shape:

```json
{
  "raw_transcript": "string",
  "cleaned_answer": "string",
  "fields": {},
  "confidence": "high|medium|low",
  "needs_review": false,
  "missing_details": [],
  "suggested_follow_up": "string or null"
}
```

## Automated Eval Cases Added

These cases are covered in `SiteClawTests/SiteClawCoreTests.swift`.

### Restaurant Name Cleanup

Inputs:

- `Um, the name of the restaurant is Thai Palace.`
- `So it is called La Cocina de Maria, you know.`
- `My restaurant name Plata Catering.`

Expected:

- Filler words are removed.
- Only the restaurant name is saved.
- Natural and imperfect phrasing still extracts the name.

### Cuisine Versus Hours Separation

Input:

```text
My restaurant name is Plata Catering. We do Venezuelan food in San Diego.
Hours are Tue-Sat 10 AM to 5 PM, special Sunday 11 AM to 3 PM.
We do Venezuelan food with arepas and empanadas.
```

Expected:

- Cuisine: `Venezuelan restaurant`
- Location: `San Diego`
- Hours contain `Tue-Sat` and `Sunday`
- Hours do not contain `Venezuelan`
- `restaurant.json` exports Tuesday through Saturday 10:00-17:00 and Sunday 11:00-15:00

### No-Price Featured Dish List

Input:

```text
Arepas tostones and empanadas
```

Expected:

- Featured dishes become `Arepas`, `Tostones`, and `Empanadas`
- No fake prices are invented
- Captured answer is owner-ready: `Arepas, Tostones, Empanadas`

### Menu Items And Prices

Input:

```text
We feature arepas for $12, empanadas for $14.50, and tostones for $8.
```

Expected:

- Menu items become `Arepas`, `Empanadas`, and `Tostones`
- Prices become `12`, `14.50`, and `8`
- No cuisine/location/hour text becomes a menu item

### Sunday/Saturday Mishearing

Input:

```text
My restaurant is called Plata Catering. We do Venezuelan food in San Diego.
We are open Tuesday through Saturday from 10 AM to 5 PM and Saturday from 11 AM to 3 PM.
```

Expected:

- Primary range remains Tuesday through Saturday 10:00-17:00
- Second `Saturday` is repaired to Sunday 11:00-15:00
- Hours do not leak cuisine or menu phrases

### Cross-Field Leakage

Input:

```text
My restaurant is called Plata Catering. We do Venezuelan food in San Diego.
We are open Tuesday through Saturday from 10 AM to 5 PM and Sunday from 11 AM to 3 PM.
We feature arepas for $12 and empanadas for $14.
What makes us special is the atmosphere, hospitality, and the smell in the air.
```

Expected:

- Name, cuisine, location, hours, menu, and story each land in the correct field
- Hours do not contain cuisine, menu, or story text
- Menu does not contain cuisine/location text
- Story does not contain hours or menu text

### Follow-Up Behavior

Setup:

```text
Original captured answer: Arepas, Tostones, Empanadas
Suggested follow-up: Which 1-2 should be the main homepage best sellers?
Follow-up answer: Arepas and empanadas for sure
```

Expected:

- Featured dishes narrow to `Arepas` and `Empanadas`
- The original captured answer is replaced, not appended to
- The phrase `for sure` is not saved as website/menu copy

### Owner Story Cleanup

Input:

```text
Um what makes us special is the atmosphere, the hospitality, the smell in the air.
```

Expected:

- Filler words are removed.
- Prompt scaffolding is removed.
- Website-ready story is saved as `The atmosphere, the hospitality, the smell in the air.`

### Imperfect English Profile Sentence

Input:

```text
My restaurant name Plata Catering. It does Venezuelan food in San Diego.
```

Expected:

- Name: `Plata Catering`
- Cuisine: `Venezuelan restaurant`
- Location: `San Diego`

## Existing Eval Coverage To Preserve

The test suite already covers:

- Argentinian cuisine staying out of hours
- Tuesday-Saturday and special Sunday hours
- Common transcript mishearings
- Menu prices and descriptions
- Follow-up answers narrowing featured dishes without duplicating active step text
- Low-confidence voice coach state
- Voice coach design notes flowing into generation requests

## Backend Contract Needs

The production AI endpoint should eventually return these fields for every guided prompt answer:

- `cleaned_answer`
- `restaurant_patch`
- `confidence`
- `missing_details`
- `suggested_follow_up`
- `design_notes`
- `status_message`

The iOS app should be able to save the local deterministic fallback immediately, then apply the AI response as a safe patch when it arrives.

## Next Eval Recommendations

- Spanish-influenced English answers
- Code-switching between English and Spanish
- Split hours such as lunch/dinner service
- Holiday or seasonal hours
- Menu answers with categories but no prices
- Corrections like `actually not Sunday, I meant Saturday`
- Owners giving multiple restaurants or catering and restaurant names in one answer

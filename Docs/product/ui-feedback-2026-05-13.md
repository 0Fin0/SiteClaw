# SiteClaw UI Feedback - May 13, 2026

## Context

Live UI review notes for the SiteClaw app. The current strongest path is still Talk -> Build -> Preview, and the generated site looked good overall, but several owner-facing workflow gaps showed up during review.

## Bugs And Friction

### View Menu And Menu Buttons Do Not Respond

- The generated site shows a featured menu section, which is good.
- Tapping View Menu does not appear to do anything.
- A few menu-related buttons behave like dead controls.
- There is no clear option to switch from the featured menu into another menu view or menu source.

Suggested acceptance criteria:

- View Menu reliably scrolls or navigates to the menu section.
- Every visible menu button either performs an action or is removed/disabled with clear state.
- If multiple menu sections/sources exist, the owner can switch between them from Build or Preview.

### Talk Flow Needs Clean Structured Extraction

- Voice capture appears to preserve raw speech artifacts instead of cleaning owner answers.
- Filler phrases such as "let's say" and "um" were included in the captured business fields.
- The LLM/agent layer should rewrite spoken answers into clean owner-facing structured data before filling Build fields.

Example target behavior:

- Raw speech can include hesitation and restarts.
- Saved hours should become something like: "Tuesday through Saturday, 10 AM to 5 PM. Special Sunday hours: [provided Sunday hours]."
- Saved text should not include filler words, false starts, or interviewer-style phrasing.

### Hours Parsing Was Confused

- When asked for hours, the app misunderstood the intended day range.
- The captured result became something like 10 to 5, Tuesday through Thursday, when the owner intended Tuesday through Saturday plus special Sunday hours.
- Hours need stronger normalization for day ranges, time ranges, and exceptions.

Suggested acceptance criteria:

- Day ranges such as Tuesday through Saturday remain intact.
- Special Sunday hours are captured as Sunday-specific hours, not merged into weekday hours.
- The Build field shows a concise, readable summary the owner can quickly verify.

### Cuisine Leaked Into Hours

- The owner said the restaurant serves Argentinian food.
- The app placed or conflated that restaurant type/cuisine answer into the hours area.
- Extraction should keep cuisine, hours, menu, and location as separate fields even when speech-to-text output is imperfect.

Suggested acceptance criteria:

- Cuisine terms such as "Argentinian food" populate restaurant type/cuisine, never operating hours.
- Hours extraction rejects phrases that do not include a day/time signal.
- Build highlights uncertain fields for review instead of silently saving them in the wrong place.

## Product Improvements

### Menu Upload From PDF Or Photo

- Build already has a plus button for featured menu items, and it does add more items.
- Add an option for owners to upload their existing physical/digital menu as a PDF or photo.
- The uploaded menu could be displayed directly on the generated website, or processed into structured menu items later.
- This would help owners update menu prices quickly when their printed menu changes.

Suggested acceptance criteria:

- Owner can upload a PDF menu.
- Owner can upload or capture a photo of a physical menu.
- Preview can show the uploaded menu on the website without requiring manual item entry first.
- Future OCR/LLM parsing can extract items and prices, but direct display should work as the first useful version.

### Account And Settings Entry Point

- There is no obvious place to manage account settings.
- The app should expose a clear settings/account path for owner profile, restaurant profile, billing/subscription, site/domain settings, and logout.
- Because the top-level demo tabs are Talk, Build, and Preview, settings could live in a toolbar gear or under Preview > Review & Export.

Suggested acceptance criteria:

- A visible Settings or Account entry point exists from the main app shell.
- Owner can find account settings without leaving the golden Talk -> Build -> Preview workflow.
- Settings separates account details from restaurant/site settings.

## Priority Backlog

1. Fix dead View Menu and menu buttons.
2. Add LLM/agent cleanup before Talk answers populate Build fields.
3. Harden hours parsing for day ranges and special-day exceptions.
4. Prevent cuisine/restaurant type from leaking into hours.
5. Add menu PDF/photo upload and direct website display.
6. Add a clear Account/Settings entry point.

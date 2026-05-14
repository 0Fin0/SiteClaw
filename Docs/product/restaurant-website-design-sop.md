# SiteClaw Restaurant Website Design SOP

## Summary

This SOP turns restaurant website inspiration into repeatable SiteClaw design guidance. The goal is to help SiteClaw generate restaurant sites that feel like the dining experience before the guest ever walks in, while still making the practical actions easy: reserve, order, view menu, call, get directions, buy gift cards, book private dining, or explore the story.

Use this as a product and design reference for future SiteClaw prompts, renderer templates, owner intake, and acceptance checks.

## Core Principle

A restaurant website should not only display food information. It should answer three visitor questions quickly:

1. What does this place feel like?
2. Can I get what I need right now?
3. Do I trust this restaurant enough to book, order, visit, or share it?

Every generated SiteClaw restaurant website should balance atmosphere, utility, and conversion.

## How SiteClaw Should Use This

This document should inform:

- Voice and text onboarding questions
- Generated website copy
- `restaurant.json` schema additions
- Visual style presets
- Static site renderer templates
- QA checks before a generated site is shown to an owner

Do not copy the named reference sites directly. Borrow patterns, not layouts, assets, animation, copy, or brand systems.

## Minimum Website Standard

Every generated restaurant site should include:

- Atmosphere-first hero with the restaurant name as a first-viewport signal
- Primary CTA above the fold
- Menu section with prices when provided
- Hours, location, phone, and directions
- Mobile-first navigation
- Clear path to ordering or reservations when available
- Owner story or positioning section
- Local SEO metadata and restaurant structured data

## Pattern Library

### Atmosphere-First Hero

Reference pull: Amici, Restaurant GEM, The Jane Antwerp, Tastavents

Use when:

- The restaurant experience, room, plating, view, or mood is a selling point
- The owner has strong photography or a clear visual identity
- The restaurant needs to feel more premium than a basic menu page

Implementation guidance:

- Open with the restaurant name, cuisine, and emotional promise.
- Use food, interior, chef, fire, bar, table, or dining-room imagery when available.
- Keep the primary action visible in the hero.
- Avoid generic stock-like hero images when real restaurant assets exist.

Useful CTA pairings:

- Reserve a Table + View Menu
- Order Online + View Menu
- Plan Your Visit + Get Directions

### Reservation Or Order Above The Fold

Reference pull: Amrit Palace, Tacos My Guey, Tripletta Pizza, Gelato La Boca

Use when:

- The restaurant depends on immediate conversion
- Online ordering, pickup, delivery, reservations, or phone orders are central
- The audience is mobile-heavy

Implementation guidance:

- Put the primary CTA in the hero and repeat it in a sticky mobile position when possible.
- If both order and reservation exist, ask the owner which one is primary.
- If no booking or ordering URL exists, use phone, directions, or contact as the fallback CTA.
- Do not invent ordering platforms, reservation links, delivery partners, or booking tools.

Suggested CTA priority:

1. Order Online
2. Reserve a Table
3. Call Now
4. Get Directions
5. View Menu

### Visual Menu Browsing

Reference pull: Flavori Restaurant, Amrit Palace, Mister Pio

Use when:

- Dishes are visually appealing or easy to sell from photos
- Menu items have prices, descriptions, dietary notes, or categories
- The restaurant is casual, fast casual, dessert, bakery, cafe, or highly product-led

Implementation guidance:

- Display dish name, short description, price, and tags.
- Use category filters only if enough menu data exists.
- Feature best sellers or signature dishes near the homepage.
- Add "Order This", "Customize", "Request Catering", or "View Full Menu" only when those actions are real.

Data needs:

- menu categories
- item name
- item description
- price or price note
- image URL
- dietary notes
- featured flag

### Story As Experience

Reference pull: Mugaritz, CAIN, Tastavents, SingleThread, Blue Hill at Stone Barns

Use when:

- The restaurant has a chef story, farm story, cultural story, regional identity, or destination experience
- Ingredients, sourcing, seasonality, or the room are part of the value
- The website should prepare guests for an experience, not just a transaction

Implementation guidance:

- Organize the site like a journey: place, food, people, menu, visit.
- Keep copy sensory and specific, but grounded in owner-provided facts.
- Add sections for chef, farm, wine, events, inn, market, or private dining only when true.
- Make the reservation CTA feel woven into the story, not detached from it.

### Playful Brand Personality

Reference pull: Tigermilk, Tripletta Pizza, Tacos My Guey, sketch London

Use when:

- The restaurant is social, colorful, fast casual, nightlife-driven, youth-oriented, or highly branded
- The owner wants memorability and energy
- The brand can support humor, bold type, illustration, or motion

Implementation guidance:

- Use larger typography, punchier section labels, playful microcopy, and energetic CTAs.
- Use animation only where it helps navigation or delight.
- Keep ordering, location, and menu actions obvious.
- Avoid letting motion or novelty hide core information.

### Luxury Restraint

Reference pull: Restaurant GEM, Gucci Osteria, Atomix, Eleven Madison Park, KOL London

Use when:

- The restaurant is fine dining, tasting-menu, chef-driven, private dining, or premium hospitality
- Scarcity, precision, and calm are more important than visual noise
- Reservations are the primary conversion

Implementation guidance:

- Use fewer sections, stronger typography, restrained color, precise spacing, and deliberate imagery.
- Avoid loud badges, excessive cards, and heavy promotion.
- Make reservation, menu, address, and contact details extremely clear.
- Use editorial copy, but keep it short.

Suggested section order:

1. Hero
2. Reservations
3. Menu or Experience
4. Chef or Story
5. Private Dining or Events
6. Visit

### Retail, Gift Card, And Experience Integration

Reference pull: Gucci Osteria, Amrit Palace, The Jane Antwerp, SingleThread, KOL London

Use when:

- The restaurant sells gift cards, vouchers, merchandise, packaged goods, chef experiences, events, classes, or private dining
- The site needs more than one conversion path

Implementation guidance:

- Treat retail and experiences as secondary CTAs, not hidden footer links.
- Use clear labels: Gift Cards, Private Dining, Events, Catering, Shop, Newsletter.
- Do not add purchase flows unless the owner provides real URLs or business rules.

### Location Clarity

Reference pull: Tigermilk, Tripletta Pizza, Amrit Palace

Use when:

- The restaurant has multiple locations
- The owner operates a concept with delivery, takeout, or city-specific pages
- Different locations have different hours, menus, ordering links, or phone numbers

Implementation guidance:

- Make location selection a core UX element.
- Avoid mixing hours, menus, and links across locations.
- If the current `restaurant.json` supports only one location, generate one location clearly and flag multi-location as a future data requirement.

## Owner Intake Questions

SiteClaw should ask a few design-relevant questions after the basics are captured:

- What is the main action you want visitors to take: order, reserve, call, get directions, buy a gift card, or view the menu?
- How should the restaurant feel online: casual, lively, elegant, cozy, rustic, playful, modern, cultural, premium, experimental, or family-friendly?
- Is your website mainly for dine-in, takeout, delivery, catering, private dining, events, or a mix?
- Do you have online ordering, reservations, gift cards, catering, or private dining links?
- Do you have real photos of food, the dining room, the bar, the chef, or the exterior?
- Do you have multiple locations?
- Are there safety, food-contact, alcohol, allergy, or trademark constraints we should avoid claiming?

## Suggested `design_brief` Layer

Long-term, SiteClaw should generate a small design brief alongside or inside `restaurant.json`.

```json
{
  "design_brief": {
    "archetype": "fine_dining_reservation_first",
    "atmosphere": ["intimate", "elegant", "chef-driven"],
    "primary_cta": "Reserve a Table",
    "secondary_ctas": ["View Menu", "Gift Cards"],
    "site_sections": ["Hero", "Reservations", "Menu", "Story", "Private Dining", "Visit"],
    "menu_presentation": "curated_featured_items",
    "visual_direction": {
      "palette": "dark_luxury",
      "typography": "elegant_serif",
      "motion": "subtle"
    },
    "content_warnings": [
      "Do not invent awards, booking URLs, delivery partners, or chef credentials."
    ]
  }
}
```

## Prompt Guidance

When generating copy or layouts, the model should:

- Choose a restaurant archetype from known data.
- Make the primary CTA match the actual business goal.
- Use owner-provided facts first.
- Prefer concise, specific copy over generic restaurant adjectives.
- Keep public-site wording customer-facing.
- Avoid owner-review language such as "draft", "captured", "missing", or "please confirm".
- Avoid fake facts, fake reviews, fake photos, fake locations, fake awards, fake ordering links, and fake reservation links.

## Renderer Guidance

The renderer should eventually support:

- CTA-aware hero variants
- Menu card variants
- Story-first page variant
- Fine-dining restrained variant
- Fast-casual order-first variant
- Multi-location selector
- Gift card, catering, events, and private dining blocks
- Optional sticky mobile CTA
- Photo-driven gallery sections

For the current Swift prototype, the safest near-term improvements are:

- Add a `primary_cta_type` concept in the draft or future schema.
- Add optional links for order, reservation, gift card, catering, and private dining.
- Expand the current font style and color presets into named restaurant style presets.
- Keep the static export simple, fast, and mobile readable.

## Acceptance Checks For Build

- A mobile visitor can reach the primary action in under 3 taps.
- The first viewport communicates restaurant name, cuisine, mood, and primary action.
- Menu items include prices when provided and never invent prices.
- Hours, address, phone, and directions are easy to find.
- If reservation or ordering is shown, the link is owner-provided.
- No private owner notes or internal review language appears on the public site.
- The site does not imply official licensing, awards, chef credentials, delivery partners, or sustainability claims unless confirmed.
- The site works for a restaurant with no photos, but improves when real photos are provided.
- The visual direction matches the restaurant type and audience.
- The generated site feels original, not copied from any reference site.

## Practical Rollout

### Phase 1: Documentation And Prompting

- Keep this SOP in product docs.
- Add archetype language to backend generation prompts.
- Add owner intake questions for CTA priority and vibe.

### Phase 2: Data Contract

- Add optional `features` fields for order, reservations, gift cards, catering, private dining, events, and newsletter.
- Add optional `design_brief` or `site_strategy` field.
- Add gallery image roles: hero, food, interior, chef, exterior, event.

### Phase 3: Renderer Variants

- Add 4 to 6 template variants tied to archetypes.
- Make CTA placement and section ordering data-driven.
- Keep each template mobile-first and static-export friendly.

### Phase 4: Owner Review

- Show the owner why SiteClaw selected a direction.
- Let the owner switch style preset without regenerating all business data.
- Keep edits partial and reversible.

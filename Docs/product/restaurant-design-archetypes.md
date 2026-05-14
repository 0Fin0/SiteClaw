# SiteClaw Restaurant Design Archetypes

## Summary

This document converts restaurant website references into practical SiteClaw archetypes. Archetypes help SiteClaw choose site structure, CTA priority, content emphasis, visual tone, and renderer behavior from owner-provided restaurant data.

Use these archetypes as a companion to `restaurant-website-design-sop.md`.

## How To Choose An Archetype

Choose based on business model first, then vibe:

- Is the main conversion ordering, reservations, calls, directions, gift cards, or private dining?
- Is the restaurant casual, premium, cultural, experimental, farm-led, nightlife-led, or multi-location?
- Does the owner have strong photos, menu data, links, or story material?
- Does the visitor need utility quickly, or should the website slow down and build desire?

If uncertain, default to `neighborhood_utility` because it gives the broadest local restaurant coverage.

## Archetype 1: Neighborhood Utility

Best for:

- Local restaurants, diners, cafes, family restaurants, grills, taquerias, small independent operators

Reference pull:

- Amrit Palace, Gelato La Boca, KOL London

Primary goal:

- Help customers quickly view menu, call, order, get directions, and check hours.

Hero:

- Restaurant name, cuisine, location cue, short value statement, primary CTA.

Recommended sections:

- Hero
- Featured Menu
- Order or Call
- Hours and Location
- Story
- Reviews or Social Links

Menu treatment:

- Practical cards with name, description, price, and featured tags.

Visual direction:

- Warm, clear, approachable, medium-density layout.

Pitfalls:

- Do not over-design a simple local restaurant into a luxury editorial site.
- Do not hide phone, address, or hours below atmospheric storytelling.

Sample `design_brief`:

```json
{
  "archetype": "neighborhood_utility",
  "primary_cta": "Call Now",
  "secondary_ctas": ["View Menu", "Get Directions"],
  "site_sections": ["Hero", "Featured Menu", "Visit", "Story"],
  "menu_presentation": "practical_cards",
  "visual_direction": {
    "density": "medium",
    "tone": "warm_local",
    "motion": "minimal"
  }
}
```

## Archetype 2: Fast Casual Order First

Best for:

- Tacos, burgers, pizza, bowls, sandwiches, dessert shops, coffee, bakeries, ice cream, takeout-first restaurants

Reference pull:

- Tacos My Guey, Tripletta Pizza, Gelato La Boca, Flavori Restaurant

Primary goal:

- Drive online orders, pickup, delivery, or phone orders.

Hero:

- Punchy food-forward headline, best-selling product, visible Order Now CTA.

Recommended sections:

- Hero
- Best Sellers
- Order Options
- Menu Categories
- Offers or Specials
- Locations
- Hours

Menu treatment:

- Visual shoppable cards with short flavor descriptions and prices.

Visual direction:

- Bold, colorful, energetic, high-clarity CTAs.

Pitfalls:

- Do not create dead "Order Now" buttons.
- Do not bury delivery or pickup options.
- Do not use excessive motion that slows mobile ordering.

Sample `design_brief`:

```json
{
  "archetype": "fast_casual_order_first",
  "primary_cta": "Order Online",
  "secondary_ctas": ["View Menu", "Find Location"],
  "site_sections": ["Hero", "Best Sellers", "Menu", "Offers", "Visit"],
  "menu_presentation": "visual_product_cards",
  "visual_direction": {
    "density": "high",
    "tone": "playful_direct",
    "motion": "light_playful"
  }
}
```

## Archetype 3: Fine Dining Reservation First

Best for:

- Chef-driven restaurants, tasting menus, date-night restaurants, premium dining rooms, small-seat-count concepts

Reference pull:

- Restaurant GEM, Atomix, Eleven Madison Park, Gucci Osteria, KOL London

Primary goal:

- Drive reservations while building trust, desire, and premium positioning.

Hero:

- Restaurant name, concise positioning, controlled image or dark editorial mood, Reserve CTA.

Recommended sections:

- Hero
- Reservations
- Menu or Experience
- Chef or Story
- Private Dining
- Visit

Menu treatment:

- Curated, minimal, restrained. Show sample menu or experience structure when exact dishes change often.

Visual direction:

- Elegant, calm, restrained, precise.

Pitfalls:

- Do not overfill the homepage with casual product cards.
- Do not invent awards, chef background, tasting-menu prices, or reservation availability.
- Do not let atmosphere hide the booking path.

Sample `design_brief`:

```json
{
  "archetype": "fine_dining_reservation_first",
  "primary_cta": "Reserve a Table",
  "secondary_ctas": ["View Menu", "Private Dining"],
  "site_sections": ["Hero", "Reservations", "Experience", "Story", "Visit"],
  "menu_presentation": "curated_minimal",
  "visual_direction": {
    "density": "low",
    "tone": "quiet_luxury",
    "motion": "subtle"
  }
}
```

## Archetype 4: Cultural Heritage

Best for:

- Restaurants with strong regional, family, cultural, or single-product identity

Reference pull:

- Mister Pio, CAIN, Tigermilk

Primary goal:

- Make the restaurant feel specific, rooted, and memorable while keeping menu and booking visible.

Hero:

- Cultural or regional positioning, signature dish or cooking method, clear CTA.

Recommended sections:

- Hero
- Signature Dishes
- Heritage Story
- Menu
- Ingredients or Method
- Visit

Menu treatment:

- Featured items with descriptions that explain ingredients, tradition, or use case.

Visual direction:

- Expressive patterns, stamps, warm textures, cultural color cues, but used with respect.

Pitfalls:

- Do not stereotype or flatten the cuisine.
- Do not use fake cultural symbols or claims.
- Do not make story so dominant that menu and visit details are hard to find.

Sample `design_brief`:

```json
{
  "archetype": "cultural_heritage",
  "primary_cta": "View Menu",
  "secondary_ctas": ["Order Online", "Visit Us"],
  "site_sections": ["Hero", "Signature Dishes", "Story", "Menu", "Visit"],
  "menu_presentation": "featured_with_story_notes",
  "visual_direction": {
    "density": "medium",
    "tone": "rooted_expressive",
    "motion": "minimal"
  }
}
```

## Archetype 5: Farm And Ingredient Led

Best for:

- Farm-to-table, seasonal, sustainability-led, countryside, wood-fire, wine-country, education-driven restaurants

Reference pull:

- Blue Hill at Stone Barns, SingleThread, CAIN, Tastavents

Primary goal:

- Sell the place, sourcing, seasonality, and experience.

Hero:

- Place-first or ingredient-first headline with strong environmental or process imagery.

Recommended sections:

- Hero
- Experience
- Farm or Sourcing
- Menu
- Events
- Market or Newsletter
- Reservations

Menu treatment:

- Seasonal, flexible, and story-led. Avoid implying fixed availability unless confirmed.

Visual direction:

- Earthy but not muddy, spacious, textural, calm.

Pitfalls:

- Do not make sustainability claims unless confirmed.
- Do not imply farm ownership, local sourcing, or organic certification without owner confirmation.
- Do not let long storytelling bury reservations.

Sample `design_brief`:

```json
{
  "archetype": "farm_ingredient_led",
  "primary_cta": "Reserve a Table",
  "secondary_ctas": ["Explore Menu", "Join Newsletter"],
  "site_sections": ["Hero", "Experience", "Sourcing", "Menu", "Events", "Visit"],
  "menu_presentation": "seasonal_story",
  "visual_direction": {
    "density": "medium",
    "tone": "seasonal_grounded",
    "motion": "subtle"
  }
}
```

## Archetype 6: Hospitality Ecosystem

Best for:

- Restaurants with lodging, farm stays, wine programs, events, market, retail, classes, newsletter, chef experiences, or gift cards

Reference pull:

- SingleThread, Gucci Osteria, The Jane Antwerp, Blue Hill at Stone Barns

Primary goal:

- Connect multiple business lines without making the site confusing.

Hero:

- Brand or destination-first hero with clear paths into dining, stay, shop, events, or gift cards.

Recommended sections:

- Hero
- Dining
- Stay or Experience
- Events
- Shop or Gift Cards
- Story
- Newsletter
- Visit

Menu treatment:

- Can be secondary to the broader experience, but should still be easy to access.

Visual direction:

- Editorial, systemized, polished, elevated.

Pitfalls:

- Do not overwhelm visitors with equal-weight CTAs.
- Do not create retail or booking paths without real links.
- Do not mix unrelated businesses unless the owner confirms they are connected.

Sample `design_brief`:

```json
{
  "archetype": "hospitality_ecosystem",
  "primary_cta": "Reserve Dining",
  "secondary_ctas": ["Gift Cards", "Events", "Newsletter"],
  "site_sections": ["Hero", "Dining", "Experiences", "Gift Cards", "Story", "Visit"],
  "menu_presentation": "curated_secondary",
  "visual_direction": {
    "density": "medium",
    "tone": "editorial_hospitality",
    "motion": "subtle"
  }
}
```

## Archetype 7: Art And Nightlife Experience

Best for:

- Cocktail bars, art restaurants, multi-room concepts, nightlife venues, immersive restaurants, music or event-led spaces

Reference pull:

- sketch London, The Jane Antwerp, Tigermilk

Primary goal:

- Make the website feel like part of the experience while still routing guests to bookings, menus, events, and rooms.

Hero:

- Immersive photo or motion-led room/experience signal with direct CTA.

Recommended sections:

- Hero
- Rooms or Experiences
- Menus
- Events or Happenings
- Reservations
- Visit

Menu treatment:

- Organized by room, service, or time of day if relevant.

Visual direction:

- Expressive, artful, high-contrast, sensory, but still legible.

Pitfalls:

- Do not sacrifice usability for novelty.
- Do not let interactions block mobile visitors from booking.
- Do not imply events, sound, rooms, or programming unless confirmed.

Sample `design_brief`:

```json
{
  "archetype": "art_nightlife_experience",
  "primary_cta": "Book a Table",
  "secondary_ctas": ["View Menus", "See Events"],
  "site_sections": ["Hero", "Experiences", "Menus", "Events", "Reservations", "Visit"],
  "menu_presentation": "experience_grouped",
  "visual_direction": {
    "density": "medium",
    "tone": "immersive_playful",
    "motion": "expressive_but_light"
  }
}
```

## Archetype 8: Multi-Location Brand

Best for:

- Restaurant groups, local chains, pizza shops, taco shops, cafes, dessert brands, franchises, city-based concepts

Reference pull:

- Tripletta Pizza, Tigermilk, Amrit Palace

Primary goal:

- Help customers pick the right location, then order, reserve, call, or navigate.

Hero:

- Brand-first hero with location selector or "Find Your Location" CTA.

Recommended sections:

- Hero
- Location Selector
- Popular Items
- Order or Reserve
- Brand Story
- Hours by Location

Menu treatment:

- Shared menu with location-specific exceptions, or location-specific menus when provided.

Visual direction:

- Consistent brand system, repeatable cards, practical navigation.

Pitfalls:

- Do not show one location's hours as if they apply everywhere.
- Do not merge ordering links across locations.
- Do not build this archetype on the current single-location schema without flagging data needs.

Sample `design_brief`:

```json
{
  "archetype": "multi_location_brand",
  "primary_cta": "Find a Location",
  "secondary_ctas": ["Order Online", "View Menu"],
  "site_sections": ["Hero", "Locations", "Popular Items", "Menu", "Story"],
  "menu_presentation": "shared_menu_with_location_context",
  "visual_direction": {
    "density": "high",
    "tone": "brand_system",
    "motion": "minimal"
  }
}
```

## Reference Pattern Map

| Reference | Borrowed Pattern | SiteClaw Use |
| --- | --- | --- |
| Amici | Warm Mediterranean visual journey | Atmosphere-first hero and social dining mood |
| Tigermilk | Bold personality and location browsing | Playful fast casual or multi-location energy |
| Restaurant GEM | Dark luxury restraint | Fine dining reservation-first template |
| Tastavents | Sensory journey structure | Story-first restaurant experiences |
| Gucci Osteria | Luxury brand plus retail/experience | Gift cards, shop, experience integration |
| Flavori Restaurant | Visual dish cards | Menu browsing and shoppable food cards |
| Amrit Palace | Practical conversion homepage | Local utility, orders, reviews, catering, hours |
| Tripletta Pizza | Casual multi-location UX | Location selector and dine-in/takeaway paths |
| Tacos My Guey | Direct order energy | Order-first hero and best-seller sections |
| Gelato La Boca | Specialty shop flow | Dessert, cafe, bakery, flavor browsing |
| CAIN | Rustic cultural storytelling | Fire, tradition, ingredients, reservation CTA |
| Mugaritz | Experimental experience tone | Avant-garde or tasting-menu preparation |
| Mister Pio | Expressive heritage branding | Cultural identity and signature product story |
| The Jane Antwerp | Total experience positioning | Art, design, room, cuisine, and craft alignment |
| Atomix | Intimate tasting-menu precision | Small-seat-count fine dining clarity |
| SingleThread | Restaurant plus hospitality ecosystem | Dining, inn, farm, wine, newsletter, reservations |
| Eleven Madison Park | Minimal luxury flow | Polished restrained booking path |
| sketch London | Immersive art restaurant | Multi-room, nightlife, happenings, playful interaction |
| Blue Hill at Stone Barns | Farm/experience organization | Dining, events, market, agricultural story |
| KOL London | Rich identity with clear utility | Refined chef-driven brand with reservations and vouchers |

## Archetype Selection Hints

- If the owner says "we mostly do takeout", choose `fast_casual_order_first`.
- If the owner says "reservations", "chef's counter", "tasting menu", or "private dining", choose `fine_dining_reservation_first`.
- If the owner emphasizes family recipes, culture, tradition, region, or one signature product, choose `cultural_heritage`.
- If the owner emphasizes farm, seasonal, local ingredients, wine, garden, fire, or countryside, choose `farm_ingredient_led`.
- If the owner has gift cards, events, classes, stays, shop, or wine club, choose `hospitality_ecosystem`.
- If the owner has multiple rooms, cocktails, DJs, art, events, or nightlife, choose `art_nightlife_experience`.
- If the owner has multiple locations, choose `multi_location_brand`.
- If none of the above is clear, choose `neighborhood_utility`.

## Build Acceptance Checks By Archetype

- `neighborhood_utility`: phone, hours, address, menu, and directions are visible without hunting.
- `fast_casual_order_first`: order CTA appears above the fold and best sellers are easy to browse.
- `fine_dining_reservation_first`: reservation CTA is clear, design is restrained, and facts are not invented.
- `cultural_heritage`: story is specific and respectful, with menu visibility preserved.
- `farm_ingredient_led`: sourcing claims are confirmed and seasonal availability is handled carefully.
- `hospitality_ecosystem`: multiple business paths are clear but not visually equal.
- `art_nightlife_experience`: immersive elements do not block usability.
- `multi_location_brand`: location-specific details do not bleed across locations.

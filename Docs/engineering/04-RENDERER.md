# SiteClaw — Renderer Service Specification

## Service Overview

The Renderer is an Astro 4.x static site generator that reads `restaurant.json` from Supabase Storage and outputs a complete, production-ready HTML website. It runs as a Cloudflare Pages project — each build fetches the restaurant data, generates static HTML/CSS/JS, and deploys to the Cloudflare CDN.

## Tech Stack

| Layer | Technology | Notes |
|-------|-----------|-------|
| Framework | Astro 4.x | Static Site Generation (SSG) mode |
| Styling | Tailwind CSS 3.x | |
| Hosting | Cloudflare Pages | Global CDN, zero server costs |
| Image optimization | Astro Image (`astro:assets`) + Cloudflare Images | |
| Maps | Google Maps Embed API (free tier) | Embedded map on contact section |

## Project Structure

```
siteclaw-renderer/
├── src/
│   ├── data/
│   │   └── restaurant.json              # Fetched at build time from Supabase Storage
│   ├── layouts/
│   │   └── BaseLayout.astro             # HTML head, meta tags, font loading, footer
│   ├── pages/
│   │   ├── index.astro                  # Homepage (hero, featured items, hours, CTA)
│   │   ├── menu.astro                   # Full menu page
│   │   └── contact.astro                # Contact info, map, hours
│   ├── components/
│   │   ├── Hero.astro                   # Hero section with image, name, tagline
│   │   ├── MenuCategory.astro           # Menu category with items
│   │   ├── MenuItem.astro               # Individual menu item card
│   │   ├── HoursTable.astro             # Operating hours display
│   │   ├── ContactInfo.astro            # Phone, email, address
│   │   ├── MapEmbed.astro               # Google Maps iframe
│   │   ├── Gallery.astro                # Photo gallery grid
│   │   ├── Testimonials.astro           # Customer testimonials
│   │   ├── Specials.astro               # Current specials/events banner
│   │   ├── SocialLinks.astro            # Social media icon links
│   │   ├── OrderButton.astro            # CTA for online ordering
│   │   ├── ReservationButton.astro      # CTA for reservations
│   │   ├── Footer.astro                 # Footer with hours, contact, social, "Powered by SiteClaw"
│   │   └── SEOHead.astro                # Meta tags, Open Graph, JSON-LD structured data
│   ├── styles/
│   │   ├── global.css                   # Tailwind imports + custom base styles
│   │   └── fonts.ts                     # Font pairing definitions by font_style
│   └── utils/
│       ├── load-data.ts                 # Reads and types restaurant.json
│       ├── format.ts                    # Price formatting, hour formatting
│       └── schema-check.ts             # Build-time schema version check
├── scripts/
│   └── fetch-data.ts                    # Pre-build script: downloads restaurant.json from Supabase
├── public/
│   ├── favicon.ico                      # Generated or default
│   └── robots.txt
├── astro.config.mjs
├── tailwind.config.mjs
├── tsconfig.json
├── package.json
└── wrangler.toml                        # Cloudflare Pages config
```

## Build Process

The build is triggered by the Dashboard's `/api/publish` endpoint, which calls the Cloudflare Pages deploy hook.

```
1. Cloudflare Pages triggers build
2. Build environment receives RESTAURANT_ID env var
3. Pre-build script (fetch-data.ts) runs:
   a. Connects to Supabase with service role key
   b. Downloads {RESTAURANT_ID}/restaurant.json from Storage
   c. Validates schema_version
   d. Writes to src/data/restaurant.json
4. Astro builds static HTML from the data
5. Cloudflare deploys to {subdomain}.siteclaw.com
```

**Pre-build script (`scripts/fetch-data.ts`):**
```typescript
import { createClient } from '@supabase/supabase-js';
import { writeFileSync, mkdirSync } from 'fs';
import { join } from 'path';

const supabase = createClient(
  process.env.SUPABASE_URL!,
  process.env.SUPABASE_SERVICE_ROLE_KEY!
);

async function fetchRestaurantData() {
  const restaurantId = process.env.RESTAURANT_ID;
  if (!restaurantId) throw new Error('RESTAURANT_ID env var required');

  const { data, error } = await supabase.storage
    .from('restaurant-data')
    .download(`${restaurantId}/restaurant.json`);

  if (error) throw new Error(`Failed to fetch restaurant data: ${error.message}`);

  const json = JSON.parse(await data.text());

  // Validate schema version
  if (json.schema_version !== '1.0') {
    throw new Error(`Unsupported schema version: ${json.schema_version}`);
  }

  const outDir = join(process.cwd(), 'src', 'data');
  mkdirSync(outDir, { recursive: true });
  writeFileSync(join(outDir, 'restaurant.json'), JSON.stringify(json, null, 2));

  console.log(`✅ Fetched restaurant data for ${json.basics?.name || restaurantId}`);
}

fetchRestaurantData().catch(err => {
  console.error('❌ Build failed:', err.message);
  process.exit(1);
});
```

## Data Loading

```typescript
// src/utils/load-data.ts
import data from '../data/restaurant.json';
import type { RestaurantData } from 'siteclaw-shared'; // or inline type

export function getRestaurant(): RestaurantData {
  return data as RestaurantData;
}
```

All Astro components import from this utility. They never read the JSON file directly.

## Font Pairings

The `font_style` field in `branding` maps to predefined Google Font pairings:

```typescript
// src/styles/fonts.ts
export const fontPairings = {
  classic: {
    heading: 'Playfair Display',
    body: 'Lora',
    google: 'family=Playfair+Display:wght@400;700&family=Lora:wght@400;600'
  },
  modern: {
    heading: 'Inter',
    body: 'Inter',
    google: 'family=Inter:wght@400;600;700'
  },
  rustic: {
    heading: 'Merriweather',
    body: 'Source Sans 3',
    google: 'family=Merriweather:wght@400;700&family=Source+Sans+3:wght@400;600'
  },
  elegant: {
    heading: 'Cormorant Garamond',
    body: 'Proza Libre',
    google: 'family=Cormorant+Garamond:wght@400;600&family=Proza+Libre:wght@400;600'
  },
  playful: {
    heading: 'Fredoka',
    body: 'Nunito',
    google: 'family=Fredoka:wght@400;600&family=Nunito:wght@400;600'
  }
};
```

## Page Specifications

### Homepage (`pages/index.astro`)

Sections rendered in order (skip any section with missing data):

1. **Hero** — `branding.hero_image_url` as background, `basics.name` as heading, `basics.tagline` as subheading, CTA buttons for ordering/reservations if URLs exist
2. **About** — `basics.description` (skip if empty)
3. **Featured Items** — Menu items where `featured: true` (skip if none)
4. **Specials** — `specials` array (skip if empty)
5. **Hours** — `hours` object formatted as a table
6. **Testimonials** — `features.testimonials` (skip if `show_reviews` is false or no testimonials)
7. **Gallery** — `gallery` array in a responsive grid (skip if empty)
8. **Contact** — `contact` info + map (if `features.show_map` is true)
9. **Footer** — Hours summary, phone, address, social links, "Powered by SiteClaw"

### Menu Page (`pages/menu.astro`)

1. Page title: "Menu"
2. Menu notes at top if `menu.notes` exists
3. Each category rendered as a section:
   - Category name as heading
   - Category description if exists
   - Items in a 1 or 2 column grid (responsive)
   - Each item shows: name, price (or price_note), description, dietary badges, availability
4. Dietary legend at bottom

### Contact Page (`pages/contact.astro`)

1. Contact info block: phone (tel: link), email (mailto: link), address
2. Hours table
3. Google Maps embed (if coordinates exist)
4. Social media links

## SEO & Structured Data

The `SEOHead.astro` component generates:

1. `<title>` from `seo.title` (fallback: `basics.name`)
2. `<meta name="description">` from `seo.description`
3. Open Graph tags (`og:title`, `og:description`, `og:image`, `og:type=restaurant`)
4. Twitter Card tags
5. JSON-LD structured data for `Restaurant` schema:

```json
{
  "@context": "https://schema.org",
  "@type": "Restaurant",
  "name": "{basics.name}",
  "description": "{basics.description}",
  "telephone": "{contact.phone}",
  "address": {
    "@type": "PostalAddress",
    "streetAddress": "{contact.address.street}",
    "addressLocality": "{contact.address.city}",
    "addressRegion": "{contact.address.state}",
    "postalCode": "{contact.address.zip}"
  },
  "servesCuisine": "{basics.cuisine_type}",
  "priceRange": "{basics.price_range}",
  "openingHoursSpecification": [...]
}
```

## Responsive Design

All pages must be mobile-first and responsive:

- **Mobile** (< 640px): Single column, stacked sections, hamburger menu
- **Tablet** (640px–1024px): Two-column menu grid, side-by-side contact + map
- **Desktop** (> 1024px): Full layout with max-width container (1200px)

Restaurant owners often check their site on their phone first. Mobile must look polished.

## Color Theming

The Renderer applies colors from `branding` as CSS custom properties:

```css
:root {
  --color-primary: {branding.primary_color || '#1a1a2e'};
  --color-secondary: {branding.secondary_color || '#e2e2e2'};
  --color-accent: {branding.accent_color || '#e94560'};
}
```

If no branding colors are provided, use sensible defaults based on `cuisine_type`:

| Cuisine | Primary | Secondary | Accent |
|---------|---------|-----------|--------|
| Italian | #2C1810 | #D4A574 | #8B0000 |
| Mexican | #1B4332 | #F5E6CC | #D4380D |
| Japanese | #1A1A2E | #F5F0E8 | #C41E3A |
| American | #1C2541 | #F0F0F0 | #E63946 |
| Default | #1a1a2e | #e2e2e2 | #e94560 |

## Cloudflare Pages Configuration

**`wrangler.toml`:**
```toml
name = "siteclaw-sites"
compatibility_date = "2026-05-01"
pages_build_output_dir = "./dist"

[vars]
SUPABASE_URL = ""
SUPABASE_SERVICE_ROLE_KEY = ""
```

**`astro.config.mjs`:**
```javascript
import { defineConfig } from 'astro/config';
import tailwind from '@astrojs/tailwind';
import cloudflare from '@astrojs/cloudflare';

export default defineConfig({
  output: 'static',
  integrations: [tailwind()],
  adapter: cloudflare(),
});
```

**`package.json` build script:**
```json
{
  "scripts": {
    "prebuild": "tsx scripts/fetch-data.ts",
    "build": "astro build",
    "preview": "astro preview"
  }
}
```

## Multi-Tenant Deployment Strategy

Each restaurant gets its own subdomain: `{slug}.siteclaw.com`.

**Option A (MVP — simpler):** Single Cloudflare Pages project. Each deploy overwrites the site for that restaurant. The `RESTAURANT_ID` env var determines which data to fetch. Use Cloudflare Pages custom domains to assign `{slug}.siteclaw.com` per deployment.

**Option B (Scale — later):** One Cloudflare Pages project per restaurant, managed programmatically via Cloudflare API. Better isolation, independent deploys. Implement when customer count exceeds ~20.

**For MVP, use Option A.** The Dashboard stores the slug in the `restaurants` table and manages the subdomain assignment via Cloudflare DNS API.

## Performance Targets

Since these are static sites on Cloudflare CDN, these targets should be achievable:

- Lighthouse Performance: > 95
- Lighthouse Accessibility: > 90
- First Contentful Paint: < 1.0s
- Total page weight: < 500KB (excluding images)
- Images: lazy-loaded, WebP format where possible

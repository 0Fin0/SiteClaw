# SiteClaw — restaurant.json Schema Specification

## Overview

`restaurant.json` is the single data contract between the Pipeline (AI conversation engine) and the Renderer (Astro static site generator). Every piece of data needed to render a restaurant website lives in this file. If the JSON is valid against this schema, the site builds. Period.

## Storage Location

- **Supabase Storage**: `restaurant-data/{restaurant_id}/restaurant.json`
- **During Astro build**: Fetched from Supabase Storage into `src/data/restaurant.json`

## Versioning

The schema includes a `schema_version` field. The Renderer checks this field and refuses to build if the version is unsupported. Current version: `"1.0"`.

## Complete JSON Schema

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "SiteClaw Restaurant Schema",
  "description": "Data contract for rendering a restaurant website",
  "type": "object",
  "required": [
    "schema_version",
    "restaurant_id",
    "basics",
    "contact",
    "hours"
  ],
  "properties": {
    "schema_version": {
      "type": "string",
      "const": "1.0"
    },
    "restaurant_id": {
      "type": "string",
      "format": "uuid",
      "description": "Matches the restaurant's UUID in Supabase"
    },
    "last_updated": {
      "type": "string",
      "format": "date-time",
      "description": "ISO 8601 timestamp of last Pipeline write"
    },
    "basics": {
      "type": "object",
      "required": ["name"],
      "properties": {
        "name": {
          "type": "string",
          "minLength": 1,
          "maxLength": 120,
          "description": "Restaurant name as it should appear on the site"
        },
        "tagline": {
          "type": "string",
          "maxLength": 200,
          "description": "Short tagline or slogan, e.g. 'Authentic Thai since 1998'"
        },
        "description": {
          "type": "string",
          "maxLength": 2000,
          "description": "About section / story of the restaurant. AI-generated from conversation."
        },
        "cuisine_type": {
          "type": "array",
          "items": { "type": "string" },
          "description": "e.g. ['Italian', 'Pizza', 'Pasta']"
        },
        "price_range": {
          "type": "string",
          "enum": ["$", "$$", "$$$", "$$$$"],
          "description": "Price tier indicator"
        },
        "year_established": {
          "type": "integer",
          "minimum": 1800,
          "maximum": 2030
        }
      }
    },
    "contact": {
      "type": "object",
      "required": ["phone"],
      "properties": {
        "phone": {
          "type": "string",
          "pattern": "^\\+?[0-9\\-\\(\\)\\s]{7,20}$",
          "description": "Primary phone number"
        },
        "email": {
          "type": "string",
          "format": "email"
        },
        "address": {
          "type": "object",
          "properties": {
            "street": { "type": "string" },
            "city": { "type": "string" },
            "state": { "type": "string" },
            "zip": { "type": "string" },
            "country": { "type": "string", "default": "US" }
          },
          "required": ["street", "city", "state", "zip"]
        },
        "coordinates": {
          "type": "object",
          "properties": {
            "lat": { "type": "number", "minimum": -90, "maximum": 90 },
            "lng": { "type": "number", "minimum": -180, "maximum": 180 }
          },
          "description": "For embedded Google Map. Can be geocoded from address."
        }
      }
    },
    "hours": {
      "type": "object",
      "description": "Operating hours by day. Each day is an array of time ranges to support split shifts (e.g. lunch + dinner).",
      "properties": {
        "monday": { "$ref": "#/definitions/day_hours" },
        "tuesday": { "$ref": "#/definitions/day_hours" },
        "wednesday": { "$ref": "#/definitions/day_hours" },
        "thursday": { "$ref": "#/definitions/day_hours" },
        "friday": { "$ref": "#/definitions/day_hours" },
        "saturday": { "$ref": "#/definitions/day_hours" },
        "sunday": { "$ref": "#/definitions/day_hours" }
      },
      "required": ["monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday"]
    },
    "menu": {
      "type": "object",
      "description": "Full menu organized by categories",
      "properties": {
        "categories": {
          "type": "array",
          "items": {
            "type": "object",
            "required": ["name", "items"],
            "properties": {
              "name": {
                "type": "string",
                "description": "Category name, e.g. 'Appetizers', 'Mains', 'Drinks'"
              },
              "description": {
                "type": "string",
                "description": "Optional category description"
              },
              "sort_order": {
                "type": "integer",
                "description": "Display order (0-indexed)"
              },
              "items": {
                "type": "array",
                "items": {
                  "type": "object",
                  "required": ["name", "price"],
                  "properties": {
                    "name": { "type": "string", "maxLength": 120 },
                    "description": {
                      "type": "string",
                      "maxLength": 500,
                      "description": "AI-enhanced description based on owner input"
                    },
                    "price": {
                      "type": "number",
                      "minimum": 0,
                      "description": "Price in USD (float, e.g. 14.99)"
                    },
                    "price_note": {
                      "type": "string",
                      "description": "e.g. 'Market price', 'Starting at'"
                    },
                    "image_url": {
                      "type": "string",
                      "format": "uri",
                      "description": "URL to dish photo in Supabase Storage"
                    },
                    "dietary": {
                      "type": "array",
                      "items": {
                        "type": "string",
                        "enum": ["vegetarian", "vegan", "gluten-free", "dairy-free", "nut-free", "halal", "kosher", "spicy"]
                      }
                    },
                    "featured": {
                      "type": "boolean",
                      "default": false,
                      "description": "If true, displayed prominently on homepage"
                    },
                    "available": {
                      "type": "boolean",
                      "default": true,
                      "description": "If false, shown as temporarily unavailable"
                    }
                  }
                }
              }
            }
          }
        },
        "notes": {
          "type": "string",
          "description": "General menu notes, e.g. 'Prices subject to change' or '18% gratuity added for parties of 6+'"
        }
      }
    },
    "gallery": {
      "type": "array",
      "items": {
        "type": "object",
        "required": ["url"],
        "properties": {
          "url": {
            "type": "string",
            "format": "uri",
            "description": "Image URL in Supabase Storage"
          },
          "alt": {
            "type": "string",
            "description": "Alt text for accessibility and SEO"
          },
          "caption": { "type": "string" },
          "sort_order": { "type": "integer" }
        }
      },
      "maxItems": 20
    },
    "social": {
      "type": "object",
      "properties": {
        "facebook": { "type": "string", "format": "uri" },
        "instagram": { "type": "string", "format": "uri" },
        "twitter": { "type": "string", "format": "uri" },
        "tiktok": { "type": "string", "format": "uri" },
        "yelp": { "type": "string", "format": "uri" },
        "google_maps": { "type": "string", "format": "uri" },
        "doordash": { "type": "string", "format": "uri" },
        "ubereats": { "type": "string", "format": "uri" },
        "grubhub": { "type": "string", "format": "uri" }
      }
    },
    "branding": {
      "type": "object",
      "description": "Visual identity. If not provided, Renderer uses sensible defaults based on cuisine_type.",
      "properties": {
        "logo_url": {
          "type": "string",
          "format": "uri",
          "description": "Logo image in Supabase Storage"
        },
        "primary_color": {
          "type": "string",
          "pattern": "^#[0-9a-fA-F]{6}$",
          "description": "Hex color, e.g. '#1a2b3c'"
        },
        "secondary_color": {
          "type": "string",
          "pattern": "^#[0-9a-fA-F]{6}$"
        },
        "accent_color": {
          "type": "string",
          "pattern": "^#[0-9a-fA-F]{6}$"
        },
        "font_style": {
          "type": "string",
          "enum": ["classic", "modern", "rustic", "elegant", "playful"],
          "description": "Maps to predefined font pairings in the Renderer"
        },
        "hero_image_url": {
          "type": "string",
          "format": "uri",
          "description": "Large banner image for the homepage hero section"
        }
      }
    },
    "seo": {
      "type": "object",
      "description": "AI-generated SEO metadata. Pipeline generates this automatically from restaurant data.",
      "properties": {
        "title": {
          "type": "string",
          "maxLength": 70,
          "description": "Page title tag, e.g. 'Mario's Trattoria | Authentic Italian in Austin, TX'"
        },
        "description": {
          "type": "string",
          "maxLength": 160,
          "description": "Meta description for search engines"
        },
        "keywords": {
          "type": "array",
          "items": { "type": "string" },
          "description": "SEO keywords, e.g. ['italian restaurant austin', 'best pasta austin tx']"
        },
        "og_image_url": {
          "type": "string",
          "format": "uri",
          "description": "Open Graph image for social sharing"
        }
      }
    },
    "features": {
      "type": "object",
      "description": "Optional features the restaurant wants enabled on their site",
      "properties": {
        "online_ordering_url": {
          "type": "string",
          "format": "uri",
          "description": "External link to ordering platform (DoorDash, Toast, etc.)"
        },
        "reservation_url": {
          "type": "string",
          "format": "uri",
          "description": "External link to reservation platform (OpenTable, Resy, etc.)"
        },
        "show_map": {
          "type": "boolean",
          "default": true
        },
        "show_reviews": {
          "type": "boolean",
          "default": false,
          "description": "If true, display curated testimonials"
        },
        "testimonials": {
          "type": "array",
          "items": {
            "type": "object",
            "properties": {
              "quote": { "type": "string", "maxLength": 500 },
              "author": { "type": "string" },
              "source": { "type": "string", "description": "e.g. 'Google', 'Yelp'" },
              "rating": { "type": "integer", "minimum": 1, "maximum": 5 }
            },
            "required": ["quote", "author"]
          },
          "maxItems": 10
        }
      }
    },
    "specials": {
      "type": "array",
      "description": "Current specials, events, or announcements",
      "items": {
        "type": "object",
        "required": ["title"],
        "properties": {
          "title": { "type": "string" },
          "description": { "type": "string" },
          "start_date": { "type": "string", "format": "date" },
          "end_date": { "type": "string", "format": "date" },
          "recurring": {
            "type": "string",
            "description": "e.g. 'Every Tuesday', 'Weekends'"
          },
          "image_url": { "type": "string", "format": "uri" }
        }
      },
      "maxItems": 10
    }
  },
  "definitions": {
    "day_hours": {
      "oneOf": [
        {
          "type": "array",
          "items": {
            "type": "object",
            "required": ["open", "close"],
            "properties": {
              "open": {
                "type": "string",
                "pattern": "^([01]?[0-9]|2[0-3]):[0-5][0-9]$",
                "description": "Opening time in 24h format, e.g. '11:00'"
              },
              "close": {
                "type": "string",
                "pattern": "^([01]?[0-9]|2[0-3]):[0-5][0-9]$",
                "description": "Closing time in 24h format, e.g. '22:00'"
              },
              "label": {
                "type": "string",
                "description": "Optional label, e.g. 'Lunch', 'Dinner'"
              }
            }
          },
          "description": "Array of time ranges for that day"
        },
        {
          "type": "string",
          "const": "closed",
          "description": "Day is closed"
        }
      ]
    }
  }
}
```

## Example: Minimal Valid restaurant.json

```json
{
  "schema_version": "1.0",
  "restaurant_id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
  "last_updated": "2026-05-07T14:30:00Z",
  "basics": {
    "name": "Mario's Trattoria"
  },
  "contact": {
    "phone": "(512) 555-0123"
  },
  "hours": {
    "monday": [{ "open": "11:00", "close": "21:00" }],
    "tuesday": [{ "open": "11:00", "close": "21:00" }],
    "wednesday": [{ "open": "11:00", "close": "21:00" }],
    "thursday": [{ "open": "11:00", "close": "22:00" }],
    "friday": [{ "open": "11:00", "close": "23:00" }],
    "saturday": [{ "open": "12:00", "close": "23:00" }],
    "sunday": "closed"
  }
}
```

## Example: Full restaurant.json

```json
{
  "schema_version": "1.0",
  "restaurant_id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
  "last_updated": "2026-05-07T14:30:00Z",
  "basics": {
    "name": "Mario's Trattoria",
    "tagline": "Authentic Italian since 1998",
    "description": "Family-owned Italian restaurant in the heart of Austin's East Side. Mario brings recipes from his grandmother's kitchen in Naples, using imported ingredients and handmade pasta daily.",
    "cuisine_type": ["Italian", "Pizza", "Pasta"],
    "price_range": "$$",
    "year_established": 1998
  },
  "contact": {
    "phone": "(512) 555-0123",
    "email": "info@mariostrattoria.com",
    "address": {
      "street": "1234 East 6th Street",
      "city": "Austin",
      "state": "TX",
      "zip": "78702",
      "country": "US"
    },
    "coordinates": {
      "lat": 30.2672,
      "lng": -97.7431
    }
  },
  "hours": {
    "monday": [
      { "open": "11:00", "close": "14:30", "label": "Lunch" },
      { "open": "17:00", "close": "21:00", "label": "Dinner" }
    ],
    "tuesday": [
      { "open": "11:00", "close": "14:30", "label": "Lunch" },
      { "open": "17:00", "close": "21:00", "label": "Dinner" }
    ],
    "wednesday": [
      { "open": "11:00", "close": "14:30", "label": "Lunch" },
      { "open": "17:00", "close": "21:00", "label": "Dinner" }
    ],
    "thursday": [
      { "open": "11:00", "close": "14:30", "label": "Lunch" },
      { "open": "17:00", "close": "22:00", "label": "Dinner" }
    ],
    "friday": [
      { "open": "11:00", "close": "23:00" }
    ],
    "saturday": [
      { "open": "12:00", "close": "23:00" }
    ],
    "sunday": "closed"
  },
  "menu": {
    "categories": [
      {
        "name": "Antipasti",
        "sort_order": 0,
        "items": [
          {
            "name": "Bruschetta al Pomodoro",
            "description": "Grilled ciabatta topped with vine-ripened tomatoes, fresh basil, garlic, and extra virgin olive oil from Puglia.",
            "price": 12.00,
            "dietary": ["vegetarian", "vegan"],
            "featured": false,
            "available": true
          },
          {
            "name": "Burrata e Prosciutto",
            "description": "Creamy burrata from Puglia paired with 24-month aged prosciutto di Parma and arugula.",
            "price": 18.00,
            "dietary": ["gluten-free"],
            "featured": true,
            "available": true
          }
        ]
      },
      {
        "name": "Pasta",
        "description": "All pasta is handmade fresh daily",
        "sort_order": 1,
        "items": [
          {
            "name": "Cacio e Pepe",
            "description": "Roman classic — tonnarelli with Pecorino Romano and black pepper. Simple, perfect.",
            "price": 19.00,
            "dietary": ["vegetarian"],
            "featured": true,
            "available": true
          }
        ]
      }
    ],
    "notes": "18% gratuity added for parties of 6 or more. Please inform your server of any allergies."
  },
  "gallery": [
    {
      "url": "https://your-supabase-url.supabase.co/storage/v1/object/public/restaurant-data/a1b2c3d4/images/interior-01.jpg",
      "alt": "Warm dining room with exposed brick and candlelight",
      "sort_order": 0
    }
  ],
  "social": {
    "instagram": "https://instagram.com/mariostrattoria",
    "yelp": "https://yelp.com/biz/marios-trattoria-austin",
    "google_maps": "https://maps.google.com/?cid=1234567890"
  },
  "branding": {
    "primary_color": "#2C1810",
    "secondary_color": "#D4A574",
    "accent_color": "#8B0000",
    "font_style": "classic",
    "hero_image_url": "https://your-supabase-url.supabase.co/storage/v1/object/public/restaurant-data/a1b2c3d4/images/hero.jpg"
  },
  "seo": {
    "title": "Mario's Trattoria | Authentic Italian Restaurant in Austin, TX",
    "description": "Family-owned Italian restaurant on East 6th Street serving handmade pasta, Neapolitan pizza, and imported wines since 1998. Lunch & dinner daily.",
    "keywords": ["italian restaurant austin", "best pasta austin tx", "east 6th street restaurants", "handmade pasta austin"]
  },
  "features": {
    "online_ordering_url": "https://order.toasttab.com/mariostrattoria",
    "reservation_url": "https://resy.com/cities/aus/marios-trattoria",
    "show_map": true,
    "show_reviews": true,
    "testimonials": [
      {
        "quote": "Best Italian food in Austin, hands down. The cacio e pepe is life-changing.",
        "author": "Sarah M.",
        "source": "Google",
        "rating": 5
      }
    ]
  },
  "specials": [
    {
      "title": "Tuesday Pasta Night",
      "description": "All pasta dishes 20% off every Tuesday evening",
      "recurring": "Every Tuesday",
      "start_date": "2026-01-01"
    }
  ]
}
```

## Validation Rules for Pipeline

When the Pipeline writes or updates restaurant.json, it MUST:

1. Validate against the JSON Schema above using `ajv` (npm) or equivalent
2. Ensure `restaurant_id` matches the authenticated user's restaurant
3. Set `last_updated` to the current ISO 8601 timestamp
4. For partial updates: deep-merge the changes into the existing JSON, never replace the entire file
5. If validation fails: return the specific validation errors to the chat so the AI can ask the owner for corrections
6. Never write an invalid restaurant.json to Supabase Storage

## Validation Rules for Renderer

When the Astro Renderer reads restaurant.json, it MUST:

1. Check `schema_version` matches a supported version (currently only `"1.0"`)
2. Gracefully handle missing optional fields (render default/empty sections)
3. Never crash on missing optional data — every field except `required` ones should have a safe fallback
4. Skip rendering sections that have no data (e.g., if `menu` is empty, don't show a menu page)

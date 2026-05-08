# SiteClaw — Database Schema (Supabase)

## Overview

SiteClaw uses Supabase (managed PostgreSQL) for relational data and Supabase Storage for file storage (restaurant.json, images). All tables use Row Level Security (RLS) to ensure owners can only access their own data.

## Tables

### `restaurants`

The core entity. One restaurant per owner (MVP), expandable to many later.

```sql
CREATE TABLE restaurants (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  slug TEXT UNIQUE NOT NULL,  -- Used for {slug}.siteclaw.com
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  
  -- Deployment state
  deploy_status TEXT DEFAULT 'draft' CHECK (deploy_status IN ('draft', 'building', 'live', 'failed')),
  last_deployed TIMESTAMPTZ,
  site_url TEXT,  -- e.g. 'https://marios-trattoria.siteclaw.com'
  custom_domain TEXT,  -- e.g. 'www.mariostrattoria.com' (Pro plan only)
  
  -- Data completeness tracking
  data_progress JSONB DEFAULT '{}'::jsonb,  -- Mirrors progress object from Pipeline
  
  CONSTRAINT unique_owner_restaurant UNIQUE (owner_id)  -- 1 restaurant per owner for MVP
);

-- RLS
ALTER TABLE restaurants ENABLE ROW LEVEL SECURITY;

CREATE POLICY "owners_read_own" ON restaurants
  FOR SELECT USING (auth.uid() = owner_id);

CREATE POLICY "owners_update_own" ON restaurants
  FOR UPDATE USING (auth.uid() = owner_id);

CREATE POLICY "owners_insert_own" ON restaurants
  FOR INSERT WITH CHECK (auth.uid() = owner_id);

-- Service role can do everything (for Pipeline and deploy triggers)
CREATE POLICY "service_role_all" ON restaurants
  FOR ALL USING (auth.role() = 'service_role');

-- Indexes
CREATE INDEX idx_restaurants_owner ON restaurants(owner_id);
CREATE INDEX idx_restaurants_slug ON restaurants(slug);
```

### `subscriptions`

Tracks billing state. Synced from Stripe via webhooks.

```sql
CREATE TABLE subscriptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  restaurant_id UUID NOT NULL REFERENCES restaurants(id) ON DELETE CASCADE UNIQUE,
  
  -- Stripe references
  stripe_customer_id TEXT,
  stripe_subscription_id TEXT,
  
  -- Plan details
  plan TEXT NOT NULL DEFAULT 'founding' CHECK (plan IN ('founding', 'starter', 'pro')),
  status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'past_due', 'cancelled', 'trialing')),
  
  -- Edit tracking
  edit_limit INTEGER NOT NULL DEFAULT -1,  -- -1 = unlimited (founding & pro)
  edits_this_period INTEGER NOT NULL DEFAULT 0,
  
  -- Billing cycle
  current_period_start TIMESTAMPTZ,
  current_period_end TIMESTAMPTZ,
  
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- RLS
ALTER TABLE subscriptions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "owners_read_own" ON subscriptions
  FOR SELECT USING (
    restaurant_id IN (SELECT id FROM restaurants WHERE owner_id = auth.uid())
  );

-- Only service role can write (updated via Stripe webhooks)
CREATE POLICY "service_role_all" ON subscriptions
  FOR ALL USING (auth.role() = 'service_role');

-- Index
CREATE INDEX idx_subscriptions_restaurant ON subscriptions(restaurant_id);
CREATE INDEX idx_subscriptions_stripe_customer ON subscriptions(stripe_customer_id);
```

**Edit limits by plan:**

| Plan | edit_limit | Notes |
|------|-----------|-------|
| `founding` | -1 (unlimited) | First 3 customers, free forever |
| `starter` | 5 | Resets each billing cycle |
| `pro` | -1 (unlimited) | |

### `messages`

Conversation history between owner and the AI.

```sql
CREATE TABLE messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  restaurant_id UUID NOT NULL REFERENCES restaurants(id) ON DELETE CASCADE,
  
  role TEXT NOT NULL CHECK (role IN ('user', 'assistant', 'system')),
  content TEXT NOT NULL,
  
  -- Metadata
  fields_updated TEXT[],  -- Which restaurant.json fields this message changed, if any
  restaurant_updated BOOLEAN DEFAULT false,
  
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- RLS
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;

CREATE POLICY "owners_read_own" ON messages
  FOR SELECT USING (
    restaurant_id IN (SELECT id FROM restaurants WHERE owner_id = auth.uid())
  );

CREATE POLICY "service_role_all" ON messages
  FOR ALL USING (auth.role() = 'service_role');

-- Indexes
CREATE INDEX idx_messages_restaurant ON messages(restaurant_id);
CREATE INDEX idx_messages_created ON messages(restaurant_id, created_at);
```

### `edit_history`

Audit log of all changes to restaurant.json. Useful for debugging and potential "undo" feature.

```sql
CREATE TABLE edit_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  restaurant_id UUID NOT NULL REFERENCES restaurants(id) ON DELETE CASCADE,
  
  -- What changed
  fields_changed TEXT[] NOT NULL,  -- e.g. ['hours', 'menu.categories[0].items']
  change_summary TEXT,  -- Human-readable description, e.g. 'Updated Monday hours to 11am-9pm'
  
  -- Snapshot (optional — for undo)
  previous_data JSONB,  -- The fields BEFORE the change (not full JSON, just changed parts)
  
  -- Who/what triggered it
  triggered_by TEXT NOT NULL CHECK (triggered_by IN ('chat', 'manual', 'system')),
  message_id UUID REFERENCES messages(id),
  
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- RLS
ALTER TABLE edit_history ENABLE ROW LEVEL SECURITY;

CREATE POLICY "owners_read_own" ON edit_history
  FOR SELECT USING (
    restaurant_id IN (SELECT id FROM restaurants WHERE owner_id = auth.uid())
  );

CREATE POLICY "service_role_all" ON edit_history
  FOR ALL USING (auth.role() = 'service_role');

-- Index
CREATE INDEX idx_edit_history_restaurant ON edit_history(restaurant_id, created_at DESC);
```

## Supabase Storage Buckets

### `restaurant-data` (private)

Stores restaurant.json and uploaded images per restaurant.

```sql
-- Create bucket
INSERT INTO storage.buckets (id, name, public) VALUES ('restaurant-data', 'restaurant-data', false);

-- RLS policies for storage
CREATE POLICY "owners_read_own_files" ON storage.objects
  FOR SELECT USING (
    bucket_id = 'restaurant-data' AND
    (storage.foldername(name))[1] IN (
      SELECT id::text FROM restaurants WHERE owner_id = auth.uid()
    )
  );

CREATE POLICY "owners_upload_own_files" ON storage.objects
  FOR INSERT WITH CHECK (
    bucket_id = 'restaurant-data' AND
    (storage.foldername(name))[1] IN (
      SELECT id::text FROM restaurants WHERE owner_id = auth.uid()
    )
  );

-- Service role (Pipeline + Renderer build) can read/write everything
CREATE POLICY "service_role_all_storage" ON storage.objects
  FOR ALL USING (
    bucket_id = 'restaurant-data' AND
    auth.role() = 'service_role'
  );
```

**Path structure:**
```
restaurant-data/
├── {restaurant_id}/
│   ├── restaurant.json
│   └── images/
│       ├── hero.jpg
│       ├── logo.png
│       ├── interior-01.jpg
│       └── menu-item-burrata.jpg
```

## Triggers & Functions

### Auto-update `updated_at`

```sql
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER restaurants_updated_at
  BEFORE UPDATE ON restaurants
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER subscriptions_updated_at
  BEFORE UPDATE ON subscriptions
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();
```

### Auto-create restaurant on signup

When a new user signs up, automatically create a restaurant record so they can start chatting immediately.

```sql
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
  new_restaurant_id UUID;
BEGIN
  -- Create restaurant
  INSERT INTO restaurants (owner_id, name, slug)
  VALUES (NEW.id, '', generate_slug())
  RETURNING id INTO new_restaurant_id;
  
  -- Create founding subscription (first 3 only — check count)
  IF (SELECT COUNT(*) FROM subscriptions WHERE plan = 'founding') < 3 THEN
    INSERT INTO subscriptions (restaurant_id, plan, edit_limit)
    VALUES (new_restaurant_id, 'founding', -1);
  ELSE
    INSERT INTO subscriptions (restaurant_id, plan, edit_limit, status)
    VALUES (new_restaurant_id, 'starter', 5, 'trialing');
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();
```

### Slug generation helper

```sql
CREATE OR REPLACE FUNCTION generate_slug()
RETURNS TEXT AS $$
DECLARE
  new_slug TEXT;
BEGIN
  -- Generate a random 8-character slug
  -- Owners can customize this later in site settings
  new_slug := lower(substr(md5(random()::text), 1, 8));
  
  -- Ensure uniqueness
  WHILE EXISTS (SELECT 1 FROM restaurants WHERE slug = new_slug) LOOP
    new_slug := lower(substr(md5(random()::text), 1, 8));
  END LOOP;
  
  RETURN new_slug;
END;
$$ LANGUAGE plpgsql;
```

## Migration Order

Run these in sequence when setting up a new Supabase project:

1. Create `restaurants` table + RLS + indexes
2. Create `subscriptions` table + RLS + indexes
3. Create `messages` table + RLS + indexes
4. Create `edit_history` table + RLS + indexes
5. Create storage bucket `restaurant-data` + storage policies
6. Create `update_updated_at` function + triggers
7. Create `generate_slug` function
8. Create `handle_new_user` function + trigger

## Notes for Codex

- All Supabase queries from the Dashboard use the **anon key** + RLS (user context from JWT)
- All Supabase queries from the Pipeline use the **service role key** (bypasses RLS, since Pipeline is a trusted backend service)
- The Renderer build also uses the **service role key** to fetch restaurant.json from storage
- Never expose the service role key to the client/browser
- The `handle_new_user` trigger uses `SECURITY DEFINER` because it runs in the auth schema context, not the user's context

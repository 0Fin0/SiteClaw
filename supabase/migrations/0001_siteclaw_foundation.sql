-- SiteClaw production Supabase foundation.
-- Owner: Agent 06 - Data and Supabase Architect.
--
-- Scope:
-- - Authenticated restaurant workspaces
-- - Owner-scoped RLS
-- - Private restaurant JSON and upload storage
-- - Published asset bucket for approved public site artifacts

create extension if not exists pgcrypto;

create or replace function public.set_updated_at()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create or replace function public.siteclaw_slugify(input text)
returns text
language sql
immutable
set search_path = public
as $$
  select coalesce(
    nullif(
      trim(both '-' from regexp_replace(lower(coalesce(input, 'restaurant')), '[^a-z0-9]+', '-', 'g')),
      ''
    ),
    'restaurant'
  );
$$;

create table public.restaurants (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  name text not null default 'Untitled Restaurant',
  slug text not null unique
    check (
      char_length(slug) between 3 and 80
      and slug ~ '^[a-z0-9]+(?:-[a-z0-9]+)*$'
    ),
  status text not null default 'draft'
    check (status in ('draft', 'active', 'archived')),
  publish_status text not null default 'not_published'
    check (publish_status in ('not_published', 'queued', 'building', 'live', 'failed')),
  site_url text,
  custom_domain text,
  data_progress jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.restaurant_profiles (
  restaurant_id uuid primary key references public.restaurants(id) on delete cascade,
  owner_name text not null default '',
  phone text not null default '',
  catering_email text not null default '',
  street_address text not null default '',
  city text not null default '',
  state text not null default '',
  postal_code text not null default '',
  country text not null default 'US',
  timezone text not null default 'America/Los_Angeles',
  cuisine_type text[] not null default array[]::text[],
  price_range text not null default '',
  tagline text not null default '',
  description text not null default '',
  hours jsonb not null default '{}'::jsonb,
  menu jsonb not null default '{"categories":[]}'::jsonb,
  seo jsonb not null default '{}'::jsonb,
  branding jsonb not null default '{}'::jsonb,
  visibility jsonb not null default '{}'::jsonb,
  features jsonb not null default '{}'::jsonb,
  growth_tools jsonb not null default '{}'::jsonb,
  design_brief jsonb not null default '{}'::jsonb,
  restaurant_json jsonb not null default '{}'::jsonb,
  restaurant_json_storage_path text,
  schema_version text not null default '1.0',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.voice_answers (
  id uuid primary key default gen_random_uuid(),
  restaurant_id uuid not null references public.restaurants(id) on delete cascade,
  prompt_kind text not null
    check (prompt_kind in ('restaurant_name', 'cuisine_location', 'hours', 'featured_dishes', 'owner_story', 'custom')),
  visible_question text not null default '',
  raw_transcript text,
  cleaned_answer text,
  confidence numeric(4,3) check (confidence is null or (confidence >= 0 and confidence <= 1)),
  missing_details text[] not null default array[]::text[],
  suggested_follow_up text,
  extracted_patch jsonb not null default '{}'::jsonb,
  status text not null default 'captured'
    check (status in ('captured', 'needs_review', 'approved', 'discarded')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.generated_drafts (
  id uuid primary key default gen_random_uuid(),
  restaurant_id uuid not null references public.restaurants(id) on delete cascade,
  source_voice_answer_id uuid references public.voice_answers(id) on delete set null,
  headline text not null default '',
  subheadline text not null default '',
  site_strategy jsonb not null default '{}'::jsonb,
  draft_data jsonb not null default '{}'::jsonb,
  restaurant_json jsonb not null default '{}'::jsonb,
  storage_bucket text not null default 'restaurant-data'
    check (storage_bucket = 'restaurant-data'),
  storage_path text,
  status text not null default 'draft'
    check (status in ('draft', 'owner_review', 'approved', 'superseded', 'discarded')),
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.uploaded_assets (
  id uuid primary key default gen_random_uuid(),
  restaurant_id uuid not null references public.restaurants(id) on delete cascade,
  owner_id uuid not null references auth.users(id) on delete cascade,
  kind text not null
    check (kind in ('menu_pdf', 'menu_image', 'dish_photo', 'hero_image', 'logo', 'generated_site_asset', 'other')),
  storage_bucket text not null default 'restaurant-uploads'
    check (storage_bucket in ('restaurant-uploads', 'published-assets')),
  storage_path text not null,
  original_filename text not null default '',
  media_type text not null default 'application/octet-stream',
  byte_count bigint not null default 0 check (byte_count >= 0),
  content_sha256 text,
  public_read_enabled boolean not null default false,
  metadata jsonb not null default '{}'::jsonb,
  created_by uuid default auth.uid() references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint uploaded_assets_private_path_scoped
    check (
      (
        storage_bucket = 'restaurant-uploads'
        and storage_path like (owner_id::text || '/' || restaurant_id::text || '/uploads/' || id::text || '%')
        and public_read_enabled is false
      )
      or (
        storage_bucket = 'published-assets'
        and storage_path like '%/published/%'
      )
    )
);

create table public.publish_records (
  id uuid primary key default gen_random_uuid(),
  restaurant_id uuid not null references public.restaurants(id) on delete cascade,
  requested_by uuid references auth.users(id) on delete set null,
  publish_target text not null default 'cloudflare_pages'
    check (publish_target in ('cloudflare_pages', 'local_demo', 'manual_export')),
  status text not null default 'queued'
    check (status in ('queued', 'building', 'live', 'failed', 'cancelled')),
  site_slug text not null,
  site_url text,
  restaurant_json_bucket text not null default 'restaurant-data'
    check (restaurant_json_bucket = 'restaurant-data'),
  restaurant_json_path text,
  published_assets_bucket text not null default 'published-assets'
    check (published_assets_bucket = 'published-assets'),
  published_path_prefix text,
  cloudflare_project_id text,
  cloudflare_deployment_id text,
  error_code text,
  error_message text,
  build_started_at timestamptz,
  published_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.edit_history (
  id uuid primary key default gen_random_uuid(),
  restaurant_id uuid not null references public.restaurants(id) on delete cascade,
  actor_user_id uuid references auth.users(id) on delete set null,
  actor_role text not null default 'owner'
    check (actor_role in ('owner', 'service_role', 'system')),
  source text not null
    check (source in ('voice_answer', 'manual_edit', 'ai_cleanup', 'publish', 'import', 'system')),
  source_id uuid,
  fields_changed text[] not null default array[]::text[],
  change_summary text not null default '',
  previous_data jsonb,
  new_data jsonb,
  created_at timestamptz not null default now()
);

create table public.subscriptions (
  id uuid primary key default gen_random_uuid(),
  restaurant_id uuid not null unique references public.restaurants(id) on delete cascade,
  stripe_customer_id text,
  stripe_subscription_id text,
  plan text not null default 'starter'
    check (plan in ('founding', 'starter', 'growth', 'pro')),
  status text not null default 'trialing'
    check (status in ('active', 'trialing', 'past_due', 'paused', 'cancelled')),
  edit_limit integer not null default 5,
  edits_this_period integer not null default 0 check (edits_this_period >= 0),
  current_period_start timestamptz,
  current_period_end timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index restaurants_owner_id_idx on public.restaurants (owner_id);
create index restaurants_publish_status_idx on public.restaurants (publish_status);
create index restaurants_updated_at_idx on public.restaurants (updated_at desc);

create index voice_answers_restaurant_created_at_idx
  on public.voice_answers (restaurant_id, created_at desc);
create index voice_answers_status_idx on public.voice_answers (status);

create index generated_drafts_restaurant_status_idx
  on public.generated_drafts (restaurant_id, status, created_at desc);

create unique index uploaded_assets_bucket_path_idx
  on public.uploaded_assets (storage_bucket, storage_path);
create index uploaded_assets_owner_restaurant_idx
  on public.uploaded_assets (owner_id, restaurant_id);
create index uploaded_assets_restaurant_kind_idx
  on public.uploaded_assets (restaurant_id, kind, created_at desc);

create index publish_records_restaurant_created_at_idx
  on public.publish_records (restaurant_id, created_at desc);
create index publish_records_status_idx on public.publish_records (status);

create index edit_history_restaurant_created_at_idx
  on public.edit_history (restaurant_id, created_at desc);

create index subscriptions_restaurant_id_idx on public.subscriptions (restaurant_id);
create unique index subscriptions_stripe_customer_id_idx
  on public.subscriptions (stripe_customer_id)
  where stripe_customer_id is not null;
create unique index subscriptions_stripe_subscription_id_idx
  on public.subscriptions (stripe_subscription_id)
  where stripe_subscription_id is not null;

create or replace function public.is_restaurant_owner(target_restaurant_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.restaurants
    where restaurants.id = target_restaurant_id
      and restaurants.owner_id = (select auth.uid())
  );
$$;

create or replace function public.generate_restaurant_slug(seed_name text)
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  base_slug text := public.siteclaw_slugify(seed_name);
  candidate text := base_slug;
  suffix integer := 2;
begin
  while exists (select 1 from public.restaurants where slug = candidate) loop
    candidate := base_slug || '-' || suffix::text;
    suffix := suffix + 1;
  end loop;

  return candidate;
end;
$$;

create or replace function public.bootstrap_restaurant_for_owner(initial_name text default 'Untitled Restaurant')
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  current_owner uuid := (select auth.uid());
  restaurant_name text := coalesce(nullif(btrim(initial_name), ''), 'Untitled Restaurant');
  new_restaurant_id uuid;
begin
  if current_owner is null then
    raise exception 'bootstrap_restaurant_for_owner requires an authenticated user';
  end if;

  insert into public.restaurants (owner_id, name, slug)
  values (current_owner, restaurant_name, public.generate_restaurant_slug(restaurant_name))
  returning id into new_restaurant_id;

  insert into public.restaurant_profiles (
    restaurant_id,
    restaurant_json_storage_path
  )
  values (
    new_restaurant_id,
    current_owner::text || '/' || new_restaurant_id::text || '/restaurant.json'
  );

  insert into public.subscriptions (restaurant_id, plan, edit_limit, status)
  values (new_restaurant_id, 'starter', 5, 'trialing');

  return new_restaurant_id;
end;
$$;

create trigger restaurants_set_updated_at
  before update on public.restaurants
  for each row execute function public.set_updated_at();

create trigger restaurant_profiles_set_updated_at
  before update on public.restaurant_profiles
  for each row execute function public.set_updated_at();

create trigger voice_answers_set_updated_at
  before update on public.voice_answers
  for each row execute function public.set_updated_at();

create trigger generated_drafts_set_updated_at
  before update on public.generated_drafts
  for each row execute function public.set_updated_at();

create trigger uploaded_assets_set_updated_at
  before update on public.uploaded_assets
  for each row execute function public.set_updated_at();

create trigger publish_records_set_updated_at
  before update on public.publish_records
  for each row execute function public.set_updated_at();

create trigger subscriptions_set_updated_at
  before update on public.subscriptions
  for each row execute function public.set_updated_at();

alter table public.restaurants enable row level security;
alter table public.restaurant_profiles enable row level security;
alter table public.voice_answers enable row level security;
alter table public.generated_drafts enable row level security;
alter table public.uploaded_assets enable row level security;
alter table public.publish_records enable row level security;
alter table public.edit_history enable row level security;
alter table public.subscriptions enable row level security;

create policy restaurants_select_own
  on public.restaurants for select
  to authenticated
  using (owner_id = (select auth.uid()));

create policy restaurants_insert_own
  on public.restaurants for insert
  to authenticated
  with check (owner_id = (select auth.uid()));

create policy restaurants_update_own
  on public.restaurants for update
  to authenticated
  using (owner_id = (select auth.uid()))
  with check (owner_id = (select auth.uid()));

create policy restaurant_profiles_select_own
  on public.restaurant_profiles for select
  to authenticated
  using ((select public.is_restaurant_owner(restaurant_id)));

create policy restaurant_profiles_insert_own
  on public.restaurant_profiles for insert
  to authenticated
  with check ((select public.is_restaurant_owner(restaurant_id)));

create policy restaurant_profiles_update_own
  on public.restaurant_profiles for update
  to authenticated
  using ((select public.is_restaurant_owner(restaurant_id)))
  with check ((select public.is_restaurant_owner(restaurant_id)));

create policy voice_answers_select_own
  on public.voice_answers for select
  to authenticated
  using ((select public.is_restaurant_owner(restaurant_id)));

create policy voice_answers_insert_own
  on public.voice_answers for insert
  to authenticated
  with check ((select public.is_restaurant_owner(restaurant_id)));

create policy voice_answers_update_own
  on public.voice_answers for update
  to authenticated
  using ((select public.is_restaurant_owner(restaurant_id)))
  with check ((select public.is_restaurant_owner(restaurant_id)));

create policy generated_drafts_select_own
  on public.generated_drafts for select
  to authenticated
  using ((select public.is_restaurant_owner(restaurant_id)));

create policy uploaded_assets_select_own
  on public.uploaded_assets for select
  to authenticated
  using ((select public.is_restaurant_owner(restaurant_id)));

create policy uploaded_assets_insert_own_private
  on public.uploaded_assets for insert
  to authenticated
  with check (
    owner_id = (select auth.uid())
    and created_by = (select auth.uid())
    and storage_bucket = 'restaurant-uploads'
    and public_read_enabled is false
    and (select public.is_restaurant_owner(restaurant_id))
  );

create policy uploaded_assets_update_own_private
  on public.uploaded_assets for update
  to authenticated
  using (
    owner_id = (select auth.uid())
    and storage_bucket = 'restaurant-uploads'
    and (select public.is_restaurant_owner(restaurant_id))
  )
  with check (
    owner_id = (select auth.uid())
    and storage_bucket = 'restaurant-uploads'
    and public_read_enabled is false
    and (select public.is_restaurant_owner(restaurant_id))
  );

create policy publish_records_select_own
  on public.publish_records for select
  to authenticated
  using ((select public.is_restaurant_owner(restaurant_id)));

create policy edit_history_select_own
  on public.edit_history for select
  to authenticated
  using ((select public.is_restaurant_owner(restaurant_id)));

create policy subscriptions_select_own
  on public.subscriptions for select
  to authenticated
  using ((select public.is_restaurant_owner(restaurant_id)));

grant select, insert, update on public.restaurants to authenticated;
grant select, insert, update on public.restaurant_profiles to authenticated;
grant select, insert, update on public.voice_answers to authenticated;
grant select on public.generated_drafts to authenticated;
grant select, insert, update on public.uploaded_assets to authenticated;
grant select on public.publish_records to authenticated;
grant select on public.edit_history to authenticated;
grant select on public.subscriptions to authenticated;

grant all on table
  public.restaurants,
  public.restaurant_profiles,
  public.voice_answers,
  public.generated_drafts,
  public.uploaded_assets,
  public.publish_records,
  public.edit_history,
  public.subscriptions
to service_role;

grant execute on function public.bootstrap_restaurant_for_owner(text) to authenticated, service_role;
grant execute on function public.generate_restaurant_slug(text) to authenticated, service_role;
grant execute on function public.is_restaurant_owner(uuid) to authenticated, service_role;

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values
  (
    'restaurant-data',
    'restaurant-data',
    false,
    10485760,
    array['application/json']
  ),
  (
    'restaurant-uploads',
    'restaurant-uploads',
    false,
    52428800,
    array[
      'application/pdf',
      'image/jpeg',
      'image/png',
      'image/webp'
    ]
  ),
  (
    'published-assets',
    'published-assets',
    true,
    52428800,
    array[
      'application/json',
      'text/css',
      'text/html',
      'image/jpeg',
      'image/png',
      'image/svg+xml',
      'image/webp',
      'font/woff2'
    ]
  )
on conflict (id) do update
set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

create policy restaurant_data_owner_select
  on storage.objects for select
  to authenticated
  using (
    bucket_id = 'restaurant-data'
    and storage.filename(name) = 'restaurant.json'
    and (storage.foldername(name))[1] = (select auth.uid())::text
    and exists (
      select 1
      from public.restaurants
      where restaurants.owner_id = (select auth.uid())
        and restaurants.id::text = (storage.foldername(name))[2]
    )
  );

create policy restaurant_data_owner_insert
  on storage.objects for insert
  to authenticated
  with check (
    bucket_id = 'restaurant-data'
    and storage.filename(name) = 'restaurant.json'
    and (storage.foldername(name))[1] = (select auth.uid())::text
    and exists (
      select 1
      from public.restaurants
      where restaurants.owner_id = (select auth.uid())
        and restaurants.id::text = (storage.foldername(name))[2]
    )
  );

create policy restaurant_data_owner_update
  on storage.objects for update
  to authenticated
  using (
    bucket_id = 'restaurant-data'
    and storage.filename(name) = 'restaurant.json'
    and (storage.foldername(name))[1] = (select auth.uid())::text
    and exists (
      select 1
      from public.restaurants
      where restaurants.owner_id = (select auth.uid())
        and restaurants.id::text = (storage.foldername(name))[2]
    )
  )
  with check (
    bucket_id = 'restaurant-data'
    and storage.filename(name) = 'restaurant.json'
    and (storage.foldername(name))[1] = (select auth.uid())::text
    and exists (
      select 1
      from public.restaurants
      where restaurants.owner_id = (select auth.uid())
        and restaurants.id::text = (storage.foldername(name))[2]
    )
  );

create policy restaurant_uploads_owner_select
  on storage.objects for select
  to authenticated
  using (
    bucket_id = 'restaurant-uploads'
    and (storage.foldername(name))[1] = (select auth.uid())::text
    and (storage.foldername(name))[3] = 'uploads'
    and exists (
      select 1
      from public.restaurants
      where restaurants.owner_id = (select auth.uid())
        and restaurants.id::text = (storage.foldername(name))[2]
    )
  );

create policy restaurant_uploads_owner_insert
  on storage.objects for insert
  to authenticated
  with check (
    bucket_id = 'restaurant-uploads'
    and (storage.foldername(name))[1] = (select auth.uid())::text
    and (storage.foldername(name))[3] = 'uploads'
    and exists (
      select 1
      from public.restaurants
      where restaurants.owner_id = (select auth.uid())
        and restaurants.id::text = (storage.foldername(name))[2]
    )
  );

create policy restaurant_uploads_owner_update
  on storage.objects for update
  to authenticated
  using (
    bucket_id = 'restaurant-uploads'
    and (storage.foldername(name))[1] = (select auth.uid())::text
    and (storage.foldername(name))[3] = 'uploads'
    and exists (
      select 1
      from public.restaurants
      where restaurants.owner_id = (select auth.uid())
        and restaurants.id::text = (storage.foldername(name))[2]
    )
  )
  with check (
    bucket_id = 'restaurant-uploads'
    and (storage.foldername(name))[1] = (select auth.uid())::text
    and (storage.foldername(name))[3] = 'uploads'
    and exists (
      select 1
      from public.restaurants
      where restaurants.owner_id = (select auth.uid())
        and restaurants.id::text = (storage.foldername(name))[2]
    )
  );

create policy restaurant_uploads_owner_delete
  on storage.objects for delete
  to authenticated
  using (
    bucket_id = 'restaurant-uploads'
    and (storage.foldername(name))[1] = (select auth.uid())::text
    and (storage.foldername(name))[3] = 'uploads'
    and exists (
      select 1
      from public.restaurants
      where restaurants.owner_id = (select auth.uid())
        and restaurants.id::text = (storage.foldername(name))[2]
    )
  );

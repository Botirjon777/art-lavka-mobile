-- ART-LAVKA schema (SPEC §5).
-- Money is ALWAYS bigint UZS, no decimals. Never float.
-- Append-only ledger: balances are SUMs, never overwritten fields.

create extension if not exists "pgcrypto";

-- ===========================================================================
-- Enums
-- ===========================================================================
create type user_role as enum ('customer', 'designer', 'operations', 'moderator', 'admin');
create type kyc_status as enum ('none', 'pending', 'verified', 'rejected');
create type payout_method as enum ('card', 'bank');
create type design_status as enum ('draft', 'pending', 'approved', 'rejected');
create type order_status as enum ('pending', 'paid', 'inProduction', 'shipped', 'delivered', 'cancelled', 'refunded');
create type payment_provider as enum ('click', 'payme', 'uzum');
create type ledger_entry_type as enum ('royaltyAccrued', 'payoutDebit', 'adjustment', 'refundReversal');
create type payout_status as enum ('requested', 'processing', 'paid', 'failed');
create type banner_link_type as enum ('category', 'listing', 'url', 'none');

-- ===========================================================================
-- Users (1:1 with auth.users). Identity is the phone number (SPEC §8).
-- ===========================================================================
create table users (
  id            uuid primary key references auth.users (id) on delete cascade,
  phone         text not null,
  email         text,
  full_name     text,
  avatar_url    text,
  language_code text not null default 'ru',
  role          user_role not null default 'customer',
  created_at    timestamptz not null default now()
);

-- ===========================================================================
-- Designer profiles + KYC/contract acceptance (SPEC §9).
-- ===========================================================================
create table designer_profiles (
  user_id              uuid primary key references users (id) on delete cascade,
  display_name         text not null,
  bio                  text,
  avatar_url           text,
  kyc_status           kyc_status not null default 'none',
  payout_method        payout_method,
  -- KYC data
  legal_name           text,
  id_number            text,
  id_photo_path        text,          -- private bucket path
  tax_note             text,
  -- Contract enforceability: what they signed, when, and the exact text hash.
  contract_version     text,
  contract_accepted_at timestamptz,
  regulations_hash     text,
  signature_path       text,          -- private `signatures` bucket
  created_at           timestamptz not null default now()
);

-- ===========================================================================
-- Catalog: categories, product types, designs, listings.
-- ===========================================================================
create table categories (
  id         uuid primary key default gen_random_uuid(),
  slug       text not null unique,
  name_ru    text not null,
  name_uz    text not null,
  name_en    text not null,
  sort_order int not null default 0
);

create table product_types (
  id         uuid primary key default gen_random_uuid(),
  slug       text not null unique,
  name_ru    text not null,
  name_uz    text not null,
  name_en    text not null,
  base_cost  bigint not null check (base_cost >= 0),   -- UZS
  sizes      jsonb not null default '[]'::jsonb,       -- ["S","M",...]
  variants   jsonb not null default '[]'::jsonb        -- [{color,template_url,print_zone,warp}]
);

create table designs (
  id               uuid primary key default gen_random_uuid(),
  designer_id      uuid not null references users (id) on delete cascade,
  title            text not null,
  description      text,
  preview_url      text not null,            -- public watermarked
  print_file_path  text not null,            -- PRIVATE print-files path
  width_px         int not null default 0,
  height_px        int not null default 0,
  status           design_status not null default 'pending',
  rejection_reason text,
  created_at       timestamptz not null default now()
);

create table design_categories (
  design_id   uuid not null references designs (id) on delete cascade,
  category_id uuid not null references categories (id) on delete cascade,
  primary key (design_id, category_id)
);

create table listings (
  id              uuid primary key default gen_random_uuid(),
  design_id       uuid not null references designs (id) on delete cascade,
  product_type_id uuid not null references product_types (id) on delete restrict,
  royalty         bigint not null check (royalty >= 0),   -- UZS, bounds enforced app/server
  active          boolean not null default true,
  created_at      timestamptz not null default now(),
  unique (design_id, product_type_id)
);

-- ===========================================================================
-- Orders + items. Prices on items are SNAPSHOTS (SPEC §13).
-- ===========================================================================
create table orders (
  id               uuid primary key default gen_random_uuid(),
  customer_id      uuid not null references users (id) on delete restrict,
  status           order_status not null default 'pending',
  subtotal         bigint not null default 0,
  shipping         bigint not null default 0,
  total            bigint not null default 0,
  payment_provider payment_provider,
  shipping_address text,
  created_at       timestamptz not null default now(),
  paid_at          timestamptz,
  delivered_at     timestamptz
);

create table order_items (
  id                  uuid primary key default gen_random_uuid(),
  order_id            uuid not null references orders (id) on delete cascade,
  listing_id          uuid not null references listings (id) on delete restrict,
  design_id           uuid not null references designs (id) on delete restrict,
  product_type_id     uuid not null references product_types (id) on delete restrict,
  quantity            int not null check (quantity > 0),
  unit_base_cost      bigint not null,    -- snapshot
  unit_royalty        bigint not null,    -- snapshot
  title_snapshot      text,
  mockup_url_snapshot text,
  size                text,
  color               text,
  reviewed            boolean not null default false
);

-- ===========================================================================
-- Money ledger (append-only) + payouts.
-- ===========================================================================
create table ledger (
  id            uuid primary key default gen_random_uuid(),
  designer_id   uuid not null references users (id) on delete restrict,
  type          ledger_entry_type not null,
  amount        bigint not null,                 -- signed: credit > 0, debit < 0
  order_item_id uuid references order_items (id) on delete set null,
  payout_id     uuid,                            -- FK added after payouts table
  memo          text,
  created_at    timestamptz not null default now()
);

create table payouts (
  id             uuid primary key default gen_random_uuid(),
  designer_id    uuid not null references users (id) on delete restrict,
  amount         bigint not null check (amount > 0),
  status         payout_status not null default 'requested',
  method         payout_method not null default 'card',
  requested_at   timestamptz not null default now(),
  processed_at   timestamptz,
  failure_reason text
);

alter table ledger
  add constraint ledger_payout_fk
  foreign key (payout_id) references payouts (id) on delete set null;

-- ===========================================================================
-- Reviews, banners, cart, device tokens.
-- ===========================================================================
create table reviews (
  id            uuid primary key default gen_random_uuid(),
  order_item_id uuid not null unique references order_items (id) on delete cascade,
  customer_id   uuid not null references users (id) on delete cascade,
  rating        int not null check (rating between 1 and 5),
  comment       text,
  created_at    timestamptz not null default now()
);

create table banners (
  id          uuid primary key default gen_random_uuid(),
  image_url   text not null,
  link_type   banner_link_type not null default 'none',
  link_target text,
  sort_order  int not null default 0,
  active      boolean not null default true
);

create table cart_items (
  id          uuid primary key default gen_random_uuid(),
  customer_id uuid not null references users (id) on delete cascade,
  listing_id  uuid not null references listings (id) on delete cascade,
  quantity    int not null default 1 check (quantity > 0),
  size        text,
  color       text,
  added_at    timestamptz not null default now(),
  unique (customer_id, listing_id, size, color)
);

create table device_tokens (
  token      text primary key,
  user_id    uuid not null references users (id) on delete cascade,
  platform   text not null,
  created_at timestamptz not null default now()
);

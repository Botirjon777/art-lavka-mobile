-- Views, indexes, and the auth->users trigger.

-- ===========================================================================
-- Indexes (SPEC §13: hot foreign keys + filter columns).
-- ===========================================================================
create index idx_order_items_design  on order_items (design_id);
create index idx_order_items_order   on order_items (order_id);
create index idx_ledger_designer     on ledger (designer_id);
create index idx_ledger_created      on ledger (created_at desc);
create index idx_listings_design     on listings (design_id);
create index idx_listings_product    on listings (product_type_id);
create index idx_orders_customer     on orders (customer_id);
create index idx_designs_designer    on designs (designer_id);
create index idx_designs_status      on designs (status);
create index idx_design_categories_cat on design_categories (category_id);
create index idx_cart_customer       on cart_items (customer_id);
create index idx_payouts_designer    on payouts (designer_id);

-- ===========================================================================
-- Catalog card view: one row per listing, with denormalized title, designer,
-- rating, and a text[] of category slugs (filter with `cs`/contains, no dupes).
-- Only surfaces APPROVED designs. security_invoker so RLS still applies.
-- NOTE: mockup_url falls back to the design preview until pre-rendered mockups
-- (SPEC §6 Strategy A) are wired; swap to the `mockups` bucket URL then.
-- This is a definer view: it intentionally exposes only safe public columns
-- (title, designer display name, rating) — never KYC fields — so the public
-- catalog works without opening up designer_profiles row-level.
-- ===========================================================================
create view listing_cards as
select
  l.id,
  l.design_id,
  l.product_type_id,
  l.royalty,
  pt.base_cost,
  l.active,
  l.created_at,
  d.title,
  dp.display_name as designer_name,
  d.preview_url   as mockup_url,
  coalesce(r.rating_avg, 0)::float    as rating_avg,
  coalesce(r.rating_count, 0)::int    as rating_count,
  coalesce(cat.slugs, '{}')::text[]   as category_slugs
from listings l
join designs d            on d.id = l.design_id and d.status = 'approved'
join product_types pt     on pt.id = l.product_type_id
join designer_profiles dp on dp.user_id = d.designer_id
left join (
  select dc.design_id, array_agg(c.slug) as slugs
  from design_categories dc
  join categories c on c.id = dc.category_id
  group by dc.design_id
) cat on cat.design_id = l.design_id
left join (
  select oi.design_id,
         avg(rv.rating)::float as rating_avg,
         count(*)              as rating_count
  from reviews rv
  join order_items oi on oi.id = rv.order_item_id
  group by oi.design_id
) r on r.design_id = l.design_id;

-- ===========================================================================
-- Designer balance = SUM of ledger rows (never a stored field). security_invoker
-- so a designer only ever sums their own rows (ledger RLS).
-- ===========================================================================
create view designer_balances
with (security_invoker = on) as
select designer_id, coalesce(sum(amount), 0)::bigint as balance
from ledger
group by designer_id;

-- ===========================================================================
-- Reviews joined to their design (+ customer name) for product pages.
-- Definer view: reviews are public product-page data.
-- ===========================================================================
create view design_reviews as
select
  rv.id,
  rv.order_item_id,
  rv.customer_id,
  rv.rating,
  rv.comment,
  rv.created_at,
  oi.design_id,
  u.full_name as customer_name
from reviews rv
join order_items oi on oi.id = rv.order_item_id
left join users u   on u.id = rv.customer_id;

-- ===========================================================================
-- Create a public.users row whenever an auth user signs up (SPEC §8).
-- ===========================================================================
create or replace function handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.users (id, phone, email)
  values (new.id, coalesce(new.phone, ''), new.email)
  on conflict (id) do nothing;
  return new;
end;
$$;

create trigger on_auth_user_created
after insert on auth.users
for each row execute function handle_new_user();

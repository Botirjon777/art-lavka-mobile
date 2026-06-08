-- Row-Level Security (SPEC §5). Default-deny: enable RLS everywhere, then grant
-- the narrowest policies. Edge functions use the service role and bypass RLS
-- for trusted server-side writes (orders, ledger, payouts).

-- Staff check, used by elevated policies (moderation queue, payouts).
create or replace function is_staff()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from users
    where id = auth.uid()
      and role in ('operations', 'moderator', 'admin')
  );
$$;

-- Enable RLS on every table.
alter table users              enable row level security;
alter table designer_profiles  enable row level security;
alter table categories         enable row level security;
alter table product_types      enable row level security;
alter table designs            enable row level security;
alter table design_categories  enable row level security;
alter table listings           enable row level security;
alter table orders             enable row level security;
alter table order_items        enable row level security;
alter table ledger             enable row level security;
alter table payouts            enable row level security;
alter table reviews            enable row level security;
alter table banners            enable row level security;
alter table cart_items         enable row level security;
alter table device_tokens      enable row level security;

-- ---------------------------------------------------------------------------
-- users: read/update only your own row; staff read all. (Insert via trigger.)
-- ---------------------------------------------------------------------------
create policy users_select_self on users for select using (id = auth.uid());
create policy users_update_self on users for update using (id = auth.uid()) with check (id = auth.uid());
create policy users_staff_read  on users for select using (is_staff());

-- ---------------------------------------------------------------------------
-- designer_profiles: owner read/write; staff manage. NOT public (holds KYC).
-- Public storefront name is surfaced only through the listing_cards view.
-- ---------------------------------------------------------------------------
create policy dp_select_self on designer_profiles for select using (user_id = auth.uid());
create policy dp_insert_self on designer_profiles for insert with check (user_id = auth.uid());
create policy dp_update_self on designer_profiles for update using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy dp_staff_all   on designer_profiles for all using (is_staff()) with check (is_staff());

-- ---------------------------------------------------------------------------
-- Public catalog reference data: anyone may read; only staff may modify.
-- ---------------------------------------------------------------------------
create policy categories_read    on categories    for select using (true);
create policy categories_staff   on categories    for all    using (is_staff()) with check (is_staff());

create policy product_types_read  on product_types for select using (true);
create policy product_types_staff on product_types for all    using (is_staff()) with check (is_staff());

create policy banners_read   on banners for select using (active or is_staff());
create policy banners_staff  on banners for all    using (is_staff()) with check (is_staff());

-- ---------------------------------------------------------------------------
-- designs: public can read APPROVED; owner reads all of theirs and writes;
-- staff (moderation) manage all.
-- ---------------------------------------------------------------------------
create policy designs_read_public on designs for select using (status = 'approved');
create policy designs_read_owner  on designs for select using (designer_id = auth.uid());
create policy designs_insert_owner on designs for insert with check (designer_id = auth.uid());
create policy designs_update_owner on designs for update using (designer_id = auth.uid()) with check (designer_id = auth.uid());
create policy designs_staff_all   on designs for all using (is_staff()) with check (is_staff());

-- design_categories: visible when the design is visible; writable by the owner.
create policy dc_read on design_categories for select using (
  exists (
    select 1 from designs d
    where d.id = design_id
      and (d.status = 'approved' or d.designer_id = auth.uid())
  )
);
create policy dc_write_owner on design_categories for all using (
  exists (select 1 from designs d where d.id = design_id and d.designer_id = auth.uid())
) with check (
  exists (select 1 from designs d where d.id = design_id and d.designer_id = auth.uid())
);

-- ---------------------------------------------------------------------------
-- listings: public reads ACTIVE; owner (via design) reads/writes theirs.
-- ---------------------------------------------------------------------------
create policy listings_read_public on listings for select using (active);
create policy listings_owner_all on listings for all using (
  exists (select 1 from designs d where d.id = design_id and d.designer_id = auth.uid())
) with check (
  exists (select 1 from designs d where d.id = design_id and d.designer_id = auth.uid())
);
create policy listings_staff_all on listings for all using (is_staff()) with check (is_staff());

-- ---------------------------------------------------------------------------
-- orders: customer reads own; staff all. Writes happen server-side (edge fns
-- with the service role), so no client insert/update policy.
-- ---------------------------------------------------------------------------
create policy orders_select_own on orders for select using (customer_id = auth.uid());
create policy orders_staff_all  on orders for all using (is_staff()) with check (is_staff());

-- order_items: the order's customer, the item's designer, or staff may read.
create policy order_items_select on order_items for select using (
  exists (select 1 from orders o where o.id = order_id and o.customer_id = auth.uid())
  or exists (select 1 from designs d where d.id = design_id and d.designer_id = auth.uid())
  or is_staff()
);

-- ---------------------------------------------------------------------------
-- ledger: designer reads own; staff all. Writes are server-side only.
-- ---------------------------------------------------------------------------
create policy ledger_select_own on ledger for select using (designer_id = auth.uid());
create policy ledger_staff_all  on ledger for all using (is_staff()) with check (is_staff());

-- payouts: designer reads own; staff all. Requests go through request-payout
-- (service role); no client insert policy.
create policy payouts_select_own on payouts for select using (designer_id = auth.uid());
create policy payouts_staff_all  on payouts for all using (is_staff()) with check (is_staff());

-- ---------------------------------------------------------------------------
-- reviews: public read; a customer may insert a review for their own delivered
-- order item exactly once (the unique constraint enforces "once").
-- ---------------------------------------------------------------------------
create policy reviews_read_public on reviews for select using (true);
create policy reviews_insert_own on reviews for insert with check (
  customer_id = auth.uid()
  and exists (
    select 1 from order_items oi
    join orders o on o.id = oi.order_id
    where oi.id = order_item_id
      and o.customer_id = auth.uid()
      and o.status = 'delivered'
  )
);

-- ---------------------------------------------------------------------------
-- cart_items + device_tokens: fully owner-scoped.
-- ---------------------------------------------------------------------------
create policy cart_owner_all on cart_items for all
  using (customer_id = auth.uid()) with check (customer_id = auth.uid());

create policy tokens_owner_all on device_tokens for all
  using (user_id = auth.uid()) with check (user_id = auth.uid());

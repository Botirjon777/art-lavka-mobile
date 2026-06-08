-- Local seed data (SPEC §5/§6). Applied by `supabase db reset`.
-- Money is bigint UZS.

-- Categories / themes.
insert into categories (slug, name_ru, name_uz, name_en, sort_order) values
  ('gamers', 'Геймеры',  'Geymerlar', 'Gamers', 1),
  ('memes',  'Мемы',     'Memlar',    'Memes',  2),
  ('funny',  'Смешное',  'Kulgili',   'Funny',  3),
  ('anime',  'Аниме',    'Anime',     'Anime',  4)
on conflict (slug) do nothing;

-- Product types with print-zone mapping metadata (SPEC §6).
-- print_zone is in template-pixel space; warp "none" for flat garments,
-- "cylinder" reserved for mugs (start with the flat label zone).
insert into product_types (slug, name_ru, name_uz, name_en, base_cost, sizes, variants) values
(
  'tshirt', 'Футболка', 'Futbolka', 'T-shirt', 60000,
  '["S","M","L","XL","XXL"]',
  '[
    {"color":"white","template_url":"product-templates/tee-white-front.png","print_zone":{"x":210,"y":180,"w":360,"h":480,"rotation":0},"warp":"none"},
    {"color":"black","template_url":"product-templates/tee-black-front.png","print_zone":{"x":210,"y":180,"w":360,"h":480,"rotation":0},"warp":"none"}
  ]'
),
(
  'hoodie', 'Худи', 'Hudi', 'Hoodie', 130000,
  '["S","M","L","XL","XXL"]',
  '[
    {"color":"black","template_url":"product-templates/hoodie-black-front.png","print_zone":{"x":230,"y":260,"w":320,"h":380,"rotation":0},"warp":"none"}
  ]'
),
(
  'cap', 'Кепка', 'Kepka', 'Cap', 50000,
  '["one-size"]',
  '[
    {"color":"black","template_url":"product-templates/cap-black-front.png","print_zone":{"x":260,"y":210,"w":200,"h":140,"rotation":0},"warp":"none"}
  ]'
),
(
  'cup', 'Кружка', 'Krujka', 'Cup', 45000,
  '["one-size"]',
  '[
    {"color":"white","template_url":"product-templates/cup-white.png","print_zone":{"x":300,"y":160,"w":260,"h":300,"rotation":0},"warp":"none"}
  ]'
)
on conflict (slug) do nothing;

import { Prisma } from '@prisma/client';

/** Average + count of ratings for a design. */
export interface RatingStat {
  avg: number;
  count: number;
}

/**
 * Aggregate per-design rating from flat `{ designId, rating }` rows.
 * Reviews link to a design via their order item, so we aggregate in JS rather
 * than SQL to stay portable (replaces the `listing_cards` view's rating join).
 */
export function aggregateRatings(
  rows: { designId: string; rating: number }[],
): Map<string, RatingStat> {
  const sums = new Map<string, { total: number; count: number }>();
  for (const { designId, rating } of rows) {
    const acc = sums.get(designId) ?? { total: 0, count: 0 };
    acc.total += rating;
    acc.count += 1;
    sums.set(designId, acc);
  }
  const out = new Map<string, RatingStat>();
  for (const [designId, { total, count }] of sums) {
    out.set(designId, { avg: count ? total / count : 0, count });
  }
  return out;
}

/**
 * Map a `sort` query value to a Prisma `orderBy`. Price sort approximates by
 * royalty (base cost is constant per product type); a precise price/popularity
 * sort needs the materialized view from SPEC §13 — TODO when that lands.
 */
export function resolveOrderBy(
  sort: string | undefined,
): Prisma.ListingOrderByWithRelationInput {
  switch (sort) {
    case 'price_low':
      return { royalty: 'asc' };
    case 'price_high':
      return { royalty: 'desc' };
    // Best sellers: most ordered listings first (real sales count).
    case 'popular':
      return { orderItems: { _count: 'desc' } };
    case 'new':
    default:
      return { createdAt: 'desc' };
  }
}

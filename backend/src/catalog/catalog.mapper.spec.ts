import { aggregateRatings, resolveOrderBy } from './catalog.mapper';

describe('catalog mapper', () => {
  it('aggregates ratings per design', () => {
    const stats = aggregateRatings([
      { designId: 'a', rating: 5 },
      { designId: 'a', rating: 3 },
      { designId: 'b', rating: 4 },
    ]);
    expect(stats.get('a')).toEqual({ avg: 4, count: 2 });
    expect(stats.get('b')).toEqual({ avg: 4, count: 1 });
    expect(stats.get('c')).toBeUndefined();
  });

  it('handles no reviews', () => {
    expect(aggregateRatings([]).size).toBe(0);
  });

  it('resolves sort to a prisma orderBy', () => {
    expect(resolveOrderBy('price_low')).toEqual({ royalty: 'asc' });
    expect(resolveOrderBy('price_high')).toEqual({ royalty: 'desc' });
    expect(resolveOrderBy('new')).toEqual({ createdAt: 'desc' });
    expect(resolveOrderBy(undefined)).toEqual({ createdAt: 'desc' });
  });
});

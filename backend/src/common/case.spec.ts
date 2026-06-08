import { camelToSnakeKey, deepSnakeCase } from './case';

describe('case', () => {
  it('converts keys camelCase -> snake_case', () => {
    expect(camelToSnakeKey('fullName')).toBe('full_name');
    expect(camelToSnakeKey('languageCode')).toBe('language_code');
    expect(camelToSnakeKey('id')).toBe('id');
  });

  it('deep-snake-cases nested objects and arrays', () => {
    const input = {
      fullName: 'A',
      items: [{ unitBaseCost: 1, productTypeId: 'x' }],
    };
    expect(deepSnakeCase(input)).toEqual({
      full_name: 'A',
      items: [{ unit_base_cost: 1, product_type_id: 'x' }],
    });
  });

  it('leaves Date values intact for ISO serialization', () => {
    const d = new Date('2026-01-01T00:00:00.000Z');
    const out = deepSnakeCase({ createdAt: d }) as { created_at: Date };
    expect(out.created_at).toBe(d);
  });
});

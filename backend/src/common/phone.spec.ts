import { isValidUzPhone, normalizePhone } from './phone';

describe('phone', () => {
  it('normalizes formatted UZ numbers to E.164', () => {
    expect(normalizePhone('+998 (90) 123-45-67')).toBe('+998901234567');
    expect(normalizePhone('901234567')).toBe('+998901234567');
    expect(normalizePhone('998901234567')).toBe('+998901234567');
  });

  it('validates UZ numbers', () => {
    expect(isValidUzPhone('+998 90 123 45 67')).toBe(true);
    expect(isValidUzPhone('12345')).toBe(false);
    expect(isValidUzPhone('')).toBe(false);
  });
});

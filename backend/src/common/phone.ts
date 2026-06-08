/**
 * UZ phone helpers — server-side mirror of the Dart `Validators` phone logic.
 * Canonical form is E.164: `+998` followed by exactly 9 digits.
 */
const UZ_PHONE = /^\+998\d{9}$/;

/** Strip formatting and coerce to `+998XXXXXXXXX` shape (best effort). */
export function normalizePhone(raw: string): string {
  const cleaned = raw.replace(/[^\d+]/g, '');
  const digits = cleaned.replace(/\+/g, '');
  if (digits.startsWith('998')) return `+${digits}`;
  if (digits.length === 9) return `+998${digits}`;
  return `+${digits}`;
}

/** True when [raw] normalizes to a valid UZ E.164 number. */
export function isValidUzPhone(raw: string): boolean {
  return UZ_PHONE.test(normalizePhone(raw));
}

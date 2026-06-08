/**
 * Integer-UZS money helpers — the server-side mirror of the Dart `Money` util.
 *
 * Money is always `bigint` UZS with no decimals. In JSON it is serialized as a
 * STRING (see `patchBigIntJson`) so large values never lose precision crossing
 * to JS `number` / the Flutter side, which parses it back to `int`.
 */

/** Non-breaking space (U+00A0) thousands separator (written as an escape). */
export const GROUP_SEPARATOR = ' ';
export const UZS_SUFFIX = "so'm";

/** Group digits, e.g. 1234567n -> "1 234 567". */
export function groupUzs(amount: bigint): string {
  const negative = amount < 0n;
  const digits = (negative ? -amount : amount).toString();
  let out = '';
  for (let i = 0; i < digits.length; i++) {
    if (i !== 0 && (digits.length - i) % 3 === 0) out += GROUP_SEPARATOR;
    out += digits[i];
  }
  return negative ? `-${out}` : out;
}

/** Display format, e.g. "120 000 so'm". */
export function formatUzs(amount: bigint, withSuffix = true): string {
  const grouped = groupUzs(amount);
  return withSuffix ? `${grouped}${GROUP_SEPARATOR}${UZS_SUFFIX}` : grouped;
}

/** A bigint augmented with the JSON hook we install below. */
interface JsonableBigInt {
  toJSON?: () => string;
}

/**
 * Make `bigint` JSON-serializable as a string. Call once at bootstrap so any
 * response containing BigInt money serializes correctly (BACKEND_NODE.md §3/§6).
 */
export function patchBigIntJson(): void {
  (BigInt.prototype as unknown as JsonableBigInt).toJSON = function (
    this: bigint,
  ): string {
    return this.toString();
  };
}

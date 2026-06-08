/**
 * Parse a short duration string like "15m", "30d", "12h", "45s" to milliseconds.
 * Falls back to [defaultMs] when the input is empty/unparseable.
 */
export function parseDurationMs(
  value: string | undefined,
  defaultMs: number,
): number {
  if (!value) return defaultMs;
  const match = /^(\d+)\s*(s|m|h|d)$/.exec(value.trim());
  if (!match) {
    const asNumber = Number(value);
    return Number.isFinite(asNumber) ? asNumber : defaultMs;
  }
  const amount = Number(match[1]);
  const unitMs = { s: 1000, m: 60_000, h: 3_600_000, d: 86_400_000 }[match[2]]!;
  return amount * unitMs;
}

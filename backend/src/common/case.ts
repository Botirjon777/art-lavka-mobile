/**
 * camelCase → snake_case key transform for API responses.
 *
 * The Flutter models' `fromJson` use snake_case keys (matching the original SQL
 * columns), so the REST API serializes responses in snake_case to keep the swap
 * drop-in (BACKEND_NODE.md §7). Used by `ResponseTransformInterceptor`.
 */
export function camelToSnakeKey(key: string): string {
  return key.replace(/[A-Z]/g, (m) => `_${m.toLowerCase()}`);
}

/**
 * Recursively snake_case the keys of plain objects/arrays. Leaves Date, bigint,
 * and other non-plain values untouched (Date/bigint serialize via JSON hooks).
 */
export function deepSnakeCase(value: unknown): unknown {
  if (Array.isArray(value)) return value.map(deepSnakeCase);
  if (
    value !== null &&
    typeof value === 'object' &&
    value.constructor === Object
  ) {
    const out: Record<string, unknown> = {};
    for (const [k, v] of Object.entries(value as Record<string, unknown>)) {
      out[camelToSnakeKey(k)] = deepSnakeCase(v);
    }
    return out;
  }
  return value;
}

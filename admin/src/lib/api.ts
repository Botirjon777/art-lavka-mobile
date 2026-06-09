// REST client for the ART-LAVKA admin panel. Talks to the NestJS API; the
// backend returns `{ error: { code, message } }` on failure and snake_case data.
const API_URL =
  process.env.NEXT_PUBLIC_API_URL ?? 'https://art-lavka-mobile.onrender.com';

export class ApiError extends Error {
  constructor(
    readonly code: string,
    message: string,
  ) {
    super(message);
  }
}

export async function api<T>(
  path: string,
  opts: { method?: string; body?: unknown; token?: string | null } = {},
): Promise<T> {
  const res = await fetch(`${API_URL}${path}`, {
    method: opts.method ?? 'GET',
    headers: {
      'Content-Type': 'application/json',
      ...(opts.token ? { Authorization: `Bearer ${opts.token}` } : {}),
    },
    body: opts.body !== undefined ? JSON.stringify(opts.body) : undefined,
    cache: 'no-store',
  });
  const text = await res.text();
  const data = text ? JSON.parse(text) : null;
  if (!res.ok) {
    const err = (data as { error?: { code?: string; message?: string } })?.error;
    throw new ApiError(err?.code ?? 'server', err?.message ?? `HTTP ${res.status}`);
  }
  return data as T;
}

/** Format an integer-UZS value (sent as a string) for display. */
export function formatUzs(value: string | number | null | undefined): string {
  const n = Number(value ?? 0);
  return `${new Intl.NumberFormat('ru-RU').format(n)} so'm`;
}

export interface Paginated<T> {
  data: T[];
  page: number;
  pageSize: number;
  total: number;
}

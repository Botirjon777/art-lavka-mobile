import { createClient, SupabaseClient } from 'jsr:@supabase/supabase-js@2';

/// Admin client (service role) — bypasses RLS for trusted server-side writes.
export function adminClient(): SupabaseClient {
  return createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    { auth: { persistSession: false } },
  );
}

/// Client scoped to the caller's JWT — RLS applies. Use to identify the user.
export function userClient(req: Request): SupabaseClient {
  return createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_ANON_KEY')!,
    {
      global: { headers: { Authorization: req.headers.get('Authorization') ?? '' } },
      auth: { persistSession: false },
    },
  );
}

/// Resolve the authenticated user id from the request, or null.
export async function requireUserId(req: Request): Promise<string | null> {
  const { data } = await userClient(req).auth.getUser();
  return data.user?.id ?? null;
}

// generate-signed-url (SPEC §5/§13).
// Issues a short-lived signed URL for a PRIVATE print file — production/admin
// only. The print-files bucket has no public read; this is the single gate.
import { adminClient, userClient } from '../_shared/client.ts';
import { handleOptions, json } from '../_shared/cors.ts';

const TTL_SECONDS = 300;
const STAFF_ROLES = ['operations', 'admin'];

Deno.serve(async (req) => {
  const pre = handleOptions(req);
  if (pre) return pre;

  const supa = userClient(req);
  const { data: auth } = await supa.auth.getUser();
  const uid = auth.user?.id;
  if (!uid) return json({ error: 'unauthorized' }, 401);

  // Only operations/admin may mint print-file URLs.
  const { data: me } = await supa.from('users').select('role').eq('id', uid).maybeSingle();
  if (!me || !STAFF_ROLES.includes(me.role)) {
    return json({ error: 'forbidden' }, 403);
  }

  let body: { path: string };
  try {
    body = await req.json();
  } catch {
    return json({ error: 'bad_request' }, 400);
  }
  if (!body.path) return json({ error: 'missing_path' }, 400);

  const db = adminClient();
  const { data, error } = await db.storage
    .from('print-files')
    .createSignedUrl(body.path, TTL_SECONDS);
  if (error) return json({ error: error.message }, 500);

  return json({ signed_url: data.signedUrl, expires_in: TTL_SECONDS });
});

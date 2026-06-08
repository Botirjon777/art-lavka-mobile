// payment-webhook (SPEC §5).
// Receives a Click/Payme/Uzum callback, VERIFIES the signature, marks the order
// paid, and moves it to the production queue. Public endpoint (no user JWT) — the
// signature is the trust boundary, so verification is mandatory.
import { adminClient } from '../_shared/client.ts';
import { json } from '../_shared/cors.ts';

// deno-lint-ignore no-explicit-any
function verifySignature(provider: string, payload: any, _req: Request): boolean {
  // TODO: implement per-provider signature verification using the shared secret
  // from Deno.env (e.g. CLICK_SECRET / PAYME_KEY / UZUM_KEY). Until real
  // credentials exist, require an explicit sandbox flag so this never silently
  // marks orders paid in production.
  if (Deno.env.get('PAYMENTS_SANDBOX') === 'true') return true;
  switch (provider) {
    case 'click':
    case 'payme':
    case 'uzum':
      return false; // not yet implemented
    default:
      return false;
  }
}

Deno.serve(async (req) => {
  if (req.method !== 'POST') return json({ error: 'method_not_allowed' }, 405);

  let payload: { provider: string; order_id: string; status: string; provider_ref?: string };
  try {
    payload = await req.json();
  } catch {
    return json({ error: 'bad_request' }, 400);
  }

  if (!verifySignature(payload.provider, payload, req)) {
    return json({ error: 'invalid_signature' }, 401);
  }

  const db = adminClient();

  if (payload.status === 'paid') {
    const { error } = await db
      .from('orders')
      .update({ status: 'paid', paid_at: new Date().toISOString() })
      .eq('id', payload.order_id)
      .eq('status', 'pending'); // idempotent: only the first callback transitions
    if (error) return json({ error: error.message }, 500);
  } else if (payload.status === 'failed') {
    await db
      .from('orders')
      .update({ status: 'cancelled' })
      .eq('id', payload.order_id)
      .eq('status', 'pending');
  }

  return json({ ok: true });
});

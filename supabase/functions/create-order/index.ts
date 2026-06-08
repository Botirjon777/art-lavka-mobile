// create-order (SPEC §5).
// Recomputes price (base_cost + royalty) from the CURRENT listing — never trusts
// a client price — creates the order + items with SNAPSHOTTED prices, and
// returns a payment intent. Runs as service role (bypasses RLS) but verifies the
// caller's identity first.
import { adminClient, requireUserId } from '../_shared/client.ts';
import { handleOptions, json } from '../_shared/cors.ts';

interface IncomingItem {
  listing_id: string;
  quantity: number;
  size?: string | null;
  color?: string | null;
}

const SHIPPING_UZS = 0; // flat-rate/shipping policy TBD; snapshotted on the order.

Deno.serve(async (req) => {
  const pre = handleOptions(req);
  if (pre) return pre;

  const userId = await requireUserId(req);
  if (!userId) return json({ error: 'unauthorized' }, 401);

  let body: { items: IncomingItem[]; provider: string; shipping_address: string };
  try {
    body = await req.json();
  } catch {
    return json({ error: 'bad_request' }, 400);
  }
  if (!Array.isArray(body.items) || body.items.length === 0) {
    return json({ error: 'empty_cart' }, 400);
  }

  const db = adminClient();

  // Pull the authoritative listing + product base_cost for every line.
  const ids = [...new Set(body.items.map((i) => i.listing_id))];
  const { data: listings, error: lErr } = await db
    .from('listings')
    .select('id, design_id, product_type_id, royalty, active, product_types(base_cost), designs(title, status)')
    .in('id', ids);
  if (lErr) return json({ error: lErr.message }, 500);

  const byId = new Map((listings ?? []).map((l) => [l.id, l]));

  let subtotal = 0;
  const itemsToInsert: Record<string, unknown>[] = [];
  for (const line of body.items) {
    const l = byId.get(line.listing_id);
    // deno-lint-ignore no-explicit-any
    const anyL = l as any;
    if (!l || anyL.active !== true || anyL.designs?.status !== 'approved') {
      return json({ error: 'item_unavailable', listing_id: line.listing_id }, 409);
    }
    const qty = Math.max(1, Math.trunc(line.quantity));
    const baseCost = Number(anyL.product_types?.base_cost ?? 0);
    const royalty = Number(anyL.royalty ?? 0);
    subtotal += (baseCost + royalty) * qty;
    itemsToInsert.push({
      listing_id: l.id,
      design_id: anyL.design_id,
      product_type_id: anyL.product_type_id,
      quantity: qty,
      unit_base_cost: baseCost,
      unit_royalty: royalty,
      title_snapshot: anyL.designs?.title ?? null,
      size: line.size ?? null,
      color: line.color ?? null,
    });
  }

  const total = subtotal + SHIPPING_UZS;

  const { data: order, error: oErr } = await db
    .from('orders')
    .insert({
      customer_id: userId,
      status: 'pending',
      subtotal,
      shipping: SHIPPING_UZS,
      total,
      payment_provider: body.provider,
      shipping_address: body.shipping_address ?? null,
    })
    .select('id')
    .single();
  if (oErr) return json({ error: oErr.message }, 500);

  const { error: iErr } = await db
    .from('order_items')
    .insert(itemsToInsert.map((i) => ({ ...i, order_id: order.id })));
  if (iErr) return json({ error: iErr.message }, 500);

  // TODO: create a real provider payment session (Click/Payme/Uzum) and return
  // its hosted checkout URL. Stubbed here until provider credentials are wired.
  return json({
    order_id: order.id,
    provider: body.provider,
    checkout_url: `https://pay.example/${body.provider}/${order.id}`,
    amount: total,
  });
});

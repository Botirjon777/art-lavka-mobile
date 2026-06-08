// accrue-royalty (SPEC §5).
// Scheduled job: for each delivered order item whose return window has passed
// and that hasn't accrued yet, write a `royaltyAccrued` ledger credit to the
// designer. Idempotent via the (type, order_item_id) pairing.
import { adminClient } from '../_shared/client.ts';
import { json } from '../_shared/cors.ts';

const RETURN_WINDOW_DAYS = 14;

Deno.serve(async (_req) => {
  const db = adminClient();
  const cutoff = new Date(Date.now() - RETURN_WINDOW_DAYS * 86_400_000).toISOString();

  // Delivered items past the window that have no royaltyAccrued ledger row yet.
  const { data: items, error } = await db
    .from('order_items')
    .select('id, design_id, unit_royalty, quantity, orders!inner(status, delivered_at), designs!inner(designer_id)')
    .eq('orders.status', 'delivered')
    .lte('orders.delivered_at', cutoff);
  if (error) return json({ error: error.message }, 500);

  let accrued = 0;
  for (const it of items ?? []) {
    // deno-lint-ignore no-explicit-any
    const anyIt = it as any;
    const { data: existing } = await db
      .from('ledger')
      .select('id')
      .eq('order_item_id', anyIt.id)
      .eq('type', 'royaltyAccrued')
      .maybeSingle();
    if (existing) continue;

    const amount = Number(anyIt.unit_royalty) * Number(anyIt.quantity);
    const { error: insErr } = await db.from('ledger').insert({
      designer_id: anyIt.designs.designer_id,
      type: 'royaltyAccrued',
      amount,
      order_item_id: anyIt.id,
      memo: 'Royalty accrued after return window',
    });
    if (!insErr) accrued++;
  }

  return json({ ok: true, accrued });
});

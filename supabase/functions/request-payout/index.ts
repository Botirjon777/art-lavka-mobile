// request-payout (SPEC §5).
// Validates balance >= minimum threshold, then creates the payout and writes the
// matching ledger DEBIT in one step. Runs as service role after verifying the
// caller. The client never debits the ledger directly.
import { adminClient, requireUserId } from '../_shared/client.ts';
import { handleOptions, json } from '../_shared/cors.ts';

const MIN_PAYOUT_UZS = 50_000;

Deno.serve(async (req) => {
  const pre = handleOptions(req);
  if (pre) return pre;

  const userId = await requireUserId(req);
  if (!userId) return json({ error: 'unauthorized' }, 401);

  let body: { amount: number };
  try {
    body = await req.json();
  } catch {
    return json({ error: 'bad_request' }, 400);
  }
  const amount = Math.trunc(Number(body.amount));
  if (!Number.isFinite(amount) || amount <= 0) {
    return json({ error: 'invalid_amount' }, 400);
  }
  if (amount < MIN_PAYOUT_UZS) {
    return json({ error: 'below_payout_threshold', min: MIN_PAYOUT_UZS }, 422);
  }

  const db = adminClient();

  // Balance = SUM(ledger.amount) for this designer.
  const { data: bal, error: balErr } = await db
    .from('designer_balances')
    .select('balance')
    .eq('designer_id', userId)
    .maybeSingle();
  if (balErr) return json({ error: balErr.message }, 500);

  const balance = Number(bal?.balance ?? 0);
  if (amount > balance) {
    return json({ error: 'insufficient_balance', balance }, 422);
  }

  // Read the designer's payout method.
  const { data: profile } = await db
    .from('designer_profiles')
    .select('payout_method')
    .eq('user_id', userId)
    .maybeSingle();

  const { data: payout, error: pErr } = await db
    .from('payouts')
    .insert({
      designer_id: userId,
      amount,
      status: 'requested',
      method: profile?.payout_method ?? 'card',
    })
    .select('*')
    .single();
  if (pErr) return json({ error: pErr.message }, 500);

  // Matching debit (negative) ties the ledger to the payout.
  const { error: lErr } = await db.from('ledger').insert({
    designer_id: userId,
    type: 'payoutDebit',
    amount: -amount,
    payout_id: payout.id,
    memo: 'Payout requested',
  });
  if (lErr) return json({ error: lErr.message }, 500);

  return json(payout);
});

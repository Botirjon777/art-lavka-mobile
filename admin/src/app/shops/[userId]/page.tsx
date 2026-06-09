'use client';

import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import Link from 'next/link';
import { useParams } from 'next/navigation';
import {
  type AdminDesign,
  DesignCard,
  StatusBadge,
} from '@/components/design-card';
import { Shell } from '@/components/shell';
import { api, formatUzs } from '@/lib/api';
import { useAuth } from '@/store/auth';

interface ShopDetail {
  user_id: string;
  display_name: string;
  slug: string;
  bio?: string | null;
  kyc_status: 'none' | 'pending' | 'verified' | 'rejected';
  legal_name?: string | null;
  phone: string;
  email?: string | null;
  full_name?: string | null;
  payout_method?: string | null;
  created_at: string;
  stats: {
    designs: number;
    listings: number;
    sales: number;
    balance_uzs: string;
  };
  designs: AdminDesign[];
}

export default function ShopDetailPage() {
  return (
    <Shell>
      <ShopDetailView />
    </Shell>
  );
}

function ShopDetailView() {
  const params = useParams<{ userId: string }>();
  const userId = params.userId;
  const token = useAuth((s) => s.token);
  const qc = useQueryClient();

  const { data, isLoading, error } = useQuery({
    queryKey: ['shop', userId],
    queryFn: () => api<ShopDetail>(`/admin/shops/${userId}`, { token }),
    enabled: !!token && !!userId,
  });

  const decideShop = useMutation({
    mutationFn: (action: 'verify' | 'reject') =>
      api(`/admin/designers/${userId}/${action}`, { method: 'POST', token }),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['shop', userId] });
      qc.invalidateQueries({ queryKey: ['shops'] });
      qc.invalidateQueries({ queryKey: ['stats'] });
    },
  });

  return (
    <div>
      <Link
        href="/shops"
        className="mb-4 inline-block text-sm text-stone-500 hover:underline"
      >
        ← All shops
      </Link>

      {isLoading && <p className="text-stone-500">Loading…</p>}
      {error && <p className="text-[#C1392B]">Failed to load shop.</p>}

      {data && (
        <>
          <div className="mb-6 flex flex-wrap items-start justify-between gap-4 rounded-2xl border border-stone-200 bg-white p-6">
            <div>
              <div className="flex items-center gap-3">
                <h1 className="text-2xl font-bold">{data.display_name}</h1>
                <StatusBadge status={data.kyc_status} />
              </div>
              <div className="mt-1 text-sm text-stone-500">
                {data.phone}
                {data.legal_name ? ` · ${data.legal_name}` : ''}
                {data.email ? ` · ${data.email}` : ''}
              </div>
              {data.bio && (
                <p className="mt-2 max-w-prose text-sm text-stone-600">
                  {data.bio}
                </p>
              )}
            </div>
            {data.kyc_status === 'pending' && (
              <div className="flex gap-2">
                <button
                  disabled={decideShop.isPending}
                  onClick={() => decideShop.mutate('verify')}
                  className="rounded-lg bg-[#3F8F5B] px-4 py-2 text-sm font-medium text-white disabled:opacity-60"
                >
                  Verify shop
                </button>
                <button
                  disabled={decideShop.isPending}
                  onClick={() => decideShop.mutate('reject')}
                  className="rounded-lg bg-white px-4 py-2 text-sm font-medium text-[#C1392B] ring-1 ring-stone-200 disabled:opacity-60"
                >
                  Reject
                </button>
              </div>
            )}
          </div>

          <div className="mb-8 grid grid-cols-2 gap-4 md:grid-cols-4">
            <Stat label="Prints" value={data.stats.designs} />
            <Stat label="Listings" value={data.stats.listings} />
            <Stat label="Sales" value={data.stats.sales} />
            <Stat label="Balance" value={formatUzs(data.stats.balance_uzs)} />
          </div>

          <h2 className="mb-4 text-lg font-bold">Prints</h2>
          {data.designs.length === 0 ? (
            <p className="text-stone-500">This shop has no prints yet.</p>
          ) : (
            <div className="grid grid-cols-2 gap-4 md:grid-cols-3 xl:grid-cols-4">
              {data.designs.map((d) => (
                <DesignCard
                  key={d.id}
                  design={d}
                  showShop={false}
                  invalidate={['shop', 'stats']}
                />
              ))}
            </div>
          )}
        </>
      )}
    </div>
  );
}

function Stat({ label, value }: { label: string; value: string | number }) {
  return (
    <div className="rounded-2xl border border-stone-200 bg-white p-5">
      <div className="text-sm text-stone-500">{label}</div>
      <div className="mt-2 text-2xl font-bold">{value}</div>
    </div>
  );
}

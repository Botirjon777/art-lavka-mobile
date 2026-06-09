'use client';

import { useQuery } from '@tanstack/react-query';
import Link from 'next/link';
import { useState } from 'react';
import { StatusBadge } from '@/components/design-card';
import { Shell } from '@/components/shell';
import { api, type Paginated } from '@/lib/api';
import { useAuth } from '@/store/auth';

interface Shop {
  user_id: string;
  display_name: string;
  slug: string;
  kyc_status: 'none' | 'pending' | 'verified' | 'rejected';
  phone: string;
  email?: string | null;
  full_name?: string | null;
  design_count: number;
  created_at: string;
}

const FILTERS = ['', 'verified', 'pending', 'rejected'] as const;
const FILTER_LABEL: Record<string, string> = {
  '': 'All',
  verified: 'Verified',
  pending: 'Pending',
  rejected: 'Rejected',
};

export default function ShopsPage() {
  return (
    <Shell>
      <Shops />
    </Shell>
  );
}

function Shops() {
  const token = useAuth((s) => s.token);
  const [status, setStatus] = useState<string>('');

  const { data, isLoading, error } = useQuery({
    queryKey: ['shops', status],
    queryFn: () =>
      api<Paginated<Shop>>(`/admin/shops${status ? `?status=${status}` : ''}`, {
        token,
      }),
    enabled: !!token,
  });

  return (
    <div>
      <h1 className="mb-6 text-2xl font-bold">Shops</h1>

      <div className="mb-5 flex gap-2">
        {FILTERS.map((f) => (
          <button
            key={f}
            onClick={() => setStatus(f)}
            className={`rounded-full px-4 py-1.5 text-sm font-medium ${
              status === f
                ? 'bg-[#E2553B] text-white'
                : 'bg-white text-stone-700 ring-1 ring-stone-200'
            }`}
          >
            {FILTER_LABEL[f]}
          </button>
        ))}
      </div>

      {isLoading && <p className="text-stone-500">Loading…</p>}
      {error && <p className="text-[#C1392B]">Failed to load.</p>}
      {data && data.data.length === 0 && (
        <p className="text-stone-500">No shops yet.</p>
      )}

      <div className="grid grid-cols-1 gap-4 md:grid-cols-2 xl:grid-cols-3">
        {data?.data.map((s) => (
          <Link
            key={s.user_id}
            href={`/shops/${s.user_id}`}
            className="rounded-2xl border border-stone-200 bg-white p-5 transition hover:border-[#E2553B] hover:shadow-sm"
          >
            <div className="flex items-start justify-between">
              <div className="font-semibold">{s.display_name}</div>
              <StatusBadge status={s.kyc_status} />
            </div>
            <div className="mt-1 text-sm text-stone-500">{s.phone}</div>
            <div className="mt-3 text-sm text-stone-600">
              {s.design_count} print{s.design_count === 1 ? '' : 's'}
            </div>
          </Link>
        ))}
      </div>
    </div>
  );
}

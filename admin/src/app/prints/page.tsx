'use client';

import { useQuery } from '@tanstack/react-query';
import { useState } from 'react';
import { type AdminDesign, DesignCard } from '@/components/design-card';
import { Shell } from '@/components/shell';
import { api, type Paginated } from '@/lib/api';
import { useAuth } from '@/store/auth';

const FILTERS = ['pending', 'approved', 'rejected', ''] as const;
const FILTER_LABEL: Record<string, string> = {
  pending: 'Pending',
  approved: 'Approved',
  rejected: 'Rejected',
  '': 'All',
};

export default function PrintsPage() {
  return (
    <Shell>
      <Prints />
    </Shell>
  );
}

function Prints() {
  const token = useAuth((s) => s.token);
  const [status, setStatus] = useState<string>('pending');

  const { data, isLoading, error } = useQuery({
    queryKey: ['designs', status],
    queryFn: () =>
      api<Paginated<AdminDesign>>(
        `/admin/designs${status ? `?status=${status}` : ''}`,
        { token },
      ),
    enabled: !!token,
  });

  return (
    <div>
      <h1 className="mb-6 text-2xl font-bold">Prints</h1>

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
        <p className="text-stone-500">Nothing here.</p>
      )}

      <div className="grid grid-cols-2 gap-4 md:grid-cols-3 xl:grid-cols-4">
        {data?.data.map((d) => (
          <DesignCard key={d.id} design={d} />
        ))}
      </div>
    </div>
  );
}

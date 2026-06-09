'use client';

import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { useState } from 'react';
import { Shell } from '@/components/shell';
import { api, type Paginated } from '@/lib/api';
import { useAuth } from '@/store/auth';

interface Designer {
  user_id: string;
  display_name: string;
  slug: string;
  kyc_status: 'none' | 'pending' | 'verified' | 'rejected';
  legal_name?: string | null;
  phone: string;
  email?: string | null;
  created_at: string;
}

const FILTERS = ['pending', 'verified', 'rejected', ''] as const;
const FILTER_LABEL: Record<string, string> = {
  pending: 'Applications',
  verified: 'Verified',
  rejected: 'Rejected',
  '': 'All',
};

export default function DesignersPage() {
  return (
    <Shell>
      <Designers />
    </Shell>
  );
}

function Designers() {
  const token = useAuth((s) => s.token);
  const qc = useQueryClient();
  const [status, setStatus] = useState<string>('pending');

  const { data, isLoading, error } = useQuery({
    queryKey: ['designers', status],
    queryFn: () =>
      api<Paginated<Designer>>(
        `/admin/designers${status ? `?status=${status}` : ''}`,
        { token },
      ),
    enabled: !!token,
  });

  const decide = useMutation({
    mutationFn: (vars: { userId: string; action: 'verify' | 'reject' }) =>
      api(`/admin/designers/${vars.userId}/${vars.action}`, {
        method: 'POST',
        token,
      }),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['designers'] });
      qc.invalidateQueries({ queryKey: ['stats'] });
    },
  });

  return (
    <div>
      <h1 className="mb-6 text-2xl font-bold">Designers</h1>

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

      <div className="overflow-hidden rounded-2xl border border-stone-200 bg-white">
        {data?.data.map((d) => (
          <div
            key={d.user_id}
            className="flex items-center justify-between border-b border-stone-100 px-5 py-4 last:border-0"
          >
            <div>
              <div className="font-semibold">{d.display_name}</div>
              <div className="text-sm text-stone-500">
                {d.phone}
                {d.legal_name ? ` · ${d.legal_name}` : ''}
              </div>
            </div>
            <div className="flex items-center gap-3">
              <StatusBadge status={d.kyc_status} />
              {d.kyc_status === 'pending' && (
                <>
                  <button
                    disabled={decide.isPending}
                    onClick={() =>
                      decide.mutate({ userId: d.user_id, action: 'verify' })
                    }
                    className="rounded-lg bg-[#3F8F5B] px-3 py-1.5 text-sm font-medium text-white disabled:opacity-60"
                  >
                    Approve
                  </button>
                  <button
                    disabled={decide.isPending}
                    onClick={() =>
                      decide.mutate({ userId: d.user_id, action: 'reject' })
                    }
                    className="rounded-lg bg-white px-3 py-1.5 text-sm font-medium text-[#C1392B] ring-1 ring-stone-200 disabled:opacity-60"
                  >
                    Reject
                  </button>
                </>
              )}
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}

function StatusBadge({ status }: { status: string }) {
  const color =
    status === 'verified'
      ? 'bg-green-100 text-green-800'
      : status === 'pending'
        ? 'bg-amber-100 text-amber-800'
        : status === 'rejected'
          ? 'bg-red-100 text-red-800'
          : 'bg-stone-100 text-stone-600';
  return (
    <span className={`rounded-full px-2.5 py-1 text-xs font-medium ${color}`}>
      {status}
    </span>
  );
}

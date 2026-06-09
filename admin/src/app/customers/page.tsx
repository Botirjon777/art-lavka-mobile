'use client';

import { useQuery } from '@tanstack/react-query';
import { Shell } from '@/components/shell';
import { api, type Paginated } from '@/lib/api';
import { useAuth } from '@/store/auth';

interface Customer {
  id: string;
  full_name?: string | null;
  phone: string;
  email?: string | null;
  language_code: string;
  created_at: string;
  order_count: number;
}

export default function CustomersPage() {
  return (
    <Shell>
      <Customers />
    </Shell>
  );
}

function Customers() {
  const token = useAuth((s) => s.token);
  const { data, isLoading, error } = useQuery({
    queryKey: ['customers'],
    queryFn: () => api<Paginated<Customer>>('/admin/customers', { token }),
    enabled: !!token,
  });

  return (
    <div>
      <h1 className="mb-6 text-2xl font-bold">Customers</h1>
      {isLoading && <p className="text-stone-500">Loading…</p>}
      {error && <p className="text-[#C1392B]">Failed to load.</p>}
      {data && data.data.length === 0 && (
        <p className="text-stone-500">No customers yet.</p>
      )}

      {data && data.data.length > 0 && (
        <div className="overflow-hidden rounded-2xl border border-stone-200 bg-white">
          <div className="grid grid-cols-[2fr_1.5fr_1fr_0.8fr] gap-4 border-b border-stone-200 bg-stone-50 px-5 py-3 text-xs font-semibold uppercase text-stone-500">
            <span>Name</span>
            <span>Phone</span>
            <span>Joined</span>
            <span className="text-right">Orders</span>
          </div>
          {data.data.map((c) => (
            <div
              key={c.id}
              className="grid grid-cols-[2fr_1.5fr_1fr_0.8fr] gap-4 border-b border-stone-100 px-5 py-3 text-sm last:border-0"
            >
              <span className="font-medium">{c.full_name ?? '—'}</span>
              <span className="text-stone-600">{c.phone}</span>
              <span className="text-stone-500">
                {new Date(c.created_at).toLocaleDateString()}
              </span>
              <span className="text-right font-semibold">{c.order_count}</span>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}

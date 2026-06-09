'use client';

import { useQuery } from '@tanstack/react-query';
import { Shell } from '@/components/shell';
import { api, formatUzs } from '@/lib/api';
import { useAuth } from '@/store/auth';

interface Stats {
  customers: number;
  designers: number;
  pendingApplications: number;
  pendingDesigns: number;
  orders: number;
  paidOrders: number;
  revenueUzs: string;
}

export default function DashboardPage() {
  return (
    <Shell>
      <Dashboard />
    </Shell>
  );
}

function Dashboard() {
  const token = useAuth((s) => s.token);
  const { data, isLoading, error } = useQuery({
    queryKey: ['stats'],
    queryFn: () => api<Stats>('/admin/stats', { token }),
    enabled: !!token,
  });

  return (
    <div>
      <h1 className="mb-6 text-2xl font-bold">Dashboard</h1>
      {isLoading && <p className="text-stone-500">Loading…</p>}
      {error && <p className="text-[#C1392B]">Failed to load stats.</p>}
      {data && (
        <div className="grid grid-cols-2 gap-4 md:grid-cols-3">
          <Card label="Customers" value={data.customers} />
          <Card label="Shops" value={data.designers} />
          <Card label="Applications" value={data.pendingApplications} accent />
          <Card label="Prints to review" value={data.pendingDesigns} accent />
          <Card label="Orders" value={data.orders} />
          <Card label="Paid orders" value={data.paidOrders} />
          <Card label="Revenue" value={formatUzs(data.revenueUzs)} />
        </div>
      )}
    </div>
  );
}

function Card({
  label,
  value,
  accent,
}: {
  label: string;
  value: string | number;
  accent?: boolean;
}) {
  return (
    <div className="rounded-2xl border border-stone-200 bg-white p-5">
      <div className="text-sm text-stone-500">{label}</div>
      <div
        className={`mt-2 text-3xl font-bold ${accent ? 'text-[#E2553B]' : ''}`}
      >
        {value}
      </div>
    </div>
  );
}

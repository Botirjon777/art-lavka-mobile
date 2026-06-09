'use client';

import { useMutation, useQueryClient } from '@tanstack/react-query';
import Image from 'next/image';
import Link from 'next/link';
import { api } from '@/lib/api';
import { useAuth } from '@/store/auth';

export interface AdminDesign {
  id: string;
  title: string;
  description?: string | null;
  preview_url: string;
  status: 'draft' | 'pending' | 'approved' | 'rejected';
  rejection_reason?: string | null;
  width_px: number;
  height_px: number;
  created_at: string;
  shop_name?: string | null;
  shop_slug?: string | null;
  designer_id?: string;
  listing_count?: number;
}

/**
 * A print tile with approve/reject moderation. Reusable on the Prints page and
 * inside a single shop. `invalidate` keys are refetched after a decision.
 */
export function DesignCard({
  design,
  showShop = true,
  invalidate = ['designs', 'stats'],
}: {
  design: AdminDesign;
  showShop?: boolean;
  invalidate?: string[];
}) {
  const token = useAuth((s) => s.token);
  const qc = useQueryClient();

  const decide = useMutation({
    mutationFn: (vars: { action: 'approve' | 'reject'; reason?: string }) =>
      api(`/admin/designs/${design.id}/${vars.action}`, {
        method: 'POST',
        token,
        body: vars.action === 'reject' ? { reason: vars.reason } : undefined,
      }),
    onSuccess: () => {
      for (const key of invalidate) qc.invalidateQueries({ queryKey: [key] });
    },
  });

  const onReject = () => {
    const reason = window.prompt('Reason for rejection (optional):') ?? '';
    decide.mutate({ action: 'reject', reason });
  };

  return (
    <div className="flex flex-col overflow-hidden rounded-2xl border border-stone-200 bg-white">
      <div className="relative aspect-square bg-stone-100">
        {design.preview_url ? (
          <Image
            src={design.preview_url}
            alt={design.title}
            fill
            sizes="240px"
            className="object-cover"
            unoptimized
          />
        ) : (
          <div className="grid h-full place-items-center text-stone-400">
            no image
          </div>
        )}
        <span className="absolute left-2 top-2">
          <StatusBadge status={design.status} />
        </span>
      </div>

      <div className="flex flex-1 flex-col gap-1 p-4">
        <div className="font-semibold leading-tight">{design.title}</div>
        {showShop && design.shop_name && (
          <Link
            href={`/shops/${design.designer_id}`}
            className="text-sm text-[#E2553B] hover:underline"
          >
            {design.shop_name}
          </Link>
        )}
        <div className="text-xs text-stone-400">
          {design.width_px}×{design.height_px}px
          {typeof design.listing_count === 'number'
            ? ` · ${design.listing_count} listing(s)`
            : ''}
        </div>
        {design.status === 'rejected' && design.rejection_reason && (
          <div className="mt-1 text-xs text-[#C1392B]">
            {design.rejection_reason}
          </div>
        )}

        <div className="mt-3 flex gap-2">
          {design.status !== 'approved' && (
            <button
              disabled={decide.isPending}
              onClick={() => decide.mutate({ action: 'approve' })}
              className="flex-1 rounded-lg bg-[#3F8F5B] px-3 py-1.5 text-sm font-medium text-white disabled:opacity-60"
            >
              Approve
            </button>
          )}
          {design.status !== 'rejected' && (
            <button
              disabled={decide.isPending}
              onClick={onReject}
              className="flex-1 rounded-lg bg-white px-3 py-1.5 text-sm font-medium text-[#C1392B] ring-1 ring-stone-200 disabled:opacity-60"
            >
              Reject
            </button>
          )}
        </div>
      </div>
    </div>
  );
}

export function StatusBadge({ status }: { status: string }) {
  const color =
    status === 'approved' || status === 'verified'
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

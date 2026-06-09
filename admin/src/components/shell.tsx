'use client';

import Link from 'next/link';
import { usePathname, useRouter } from 'next/navigation';
import { useEffect } from 'react';
import { useAuth } from '@/store/auth';

const NAV = [
  { href: '/', label: 'Dashboard' },
  { href: '/designers', label: 'Designers' },
  { href: '/customers', label: 'Customers' },
];

/** Sidebar layout + client-side auth guard for admin pages. */
export function Shell({ children }: { children: React.ReactNode }) {
  const { token, user, hydrated, logout } = useAuth();
  const router = useRouter();
  const pathname = usePathname();

  useEffect(() => {
    if (hydrated && !token) router.replace('/login');
  }, [hydrated, token, router]);

  if (!hydrated || !token) {
    return (
      <div className="grid min-h-screen place-items-center text-stone-500">
        Loading…
      </div>
    );
  }

  return (
    <div className="flex min-h-screen bg-[#F7F4EF] text-[#1C1A17]">
      <aside className="flex w-60 flex-col border-r border-stone-200 bg-white">
        <div className="px-5 py-5 text-lg font-bold">
          ART-LAVKA <span className="text-[#E2553B]">Admin</span>
        </div>
        <nav className="flex-1 px-3">
          {NAV.map((item) => {
            const active =
              item.href === '/'
                ? pathname === '/'
                : pathname.startsWith(item.href);
            return (
              <Link
                key={item.href}
                href={item.href}
                className={`mb-1 block rounded-lg px-3 py-2 text-sm font-medium ${
                  active
                    ? 'bg-[#E2553B] text-white'
                    : 'text-stone-700 hover:bg-stone-100'
                }`}
              >
                {item.label}
              </Link>
            );
          })}
        </nav>
        <div className="border-t border-stone-200 px-5 py-4 text-sm">
          <div className="mb-2 text-stone-500">{user?.phone}</div>
          <button
            onClick={() => {
              logout();
              router.replace('/login');
            }}
            className="text-[#C1392B] hover:underline"
          >
            Sign out
          </button>
        </div>
      </aside>
      <main className="flex-1 overflow-auto p-8">{children}</main>
    </div>
  );
}

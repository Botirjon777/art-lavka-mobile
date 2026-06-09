'use client';

import { useRouter } from 'next/navigation';
import { useState } from 'react';
import { api, ApiError } from '@/lib/api';
import { useAuth, type AdminUser } from '@/store/auth';

export default function LoginPage() {
  const router = useRouter();
  const setAuth = useAuth((s) => s.setAuth);
  const [phase, setPhase] = useState<'phone' | 'code'>('phone');
  const [phone, setPhone] = useState('');
  const [code, setCode] = useState('');
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  async function requestOtp() {
    setLoading(true);
    setError(null);
    try {
      await api('/auth/otp/request', { method: 'POST', body: { phone } });
      setPhase('code');
    } catch (e) {
      setError(e instanceof ApiError ? e.message : 'Failed to send code');
    } finally {
      setLoading(false);
    }
  }

  async function verify() {
    setLoading(true);
    setError(null);
    try {
      const res = await api<{ user: AdminUser; access_token: string }>(
        '/auth/otp/verify',
        { method: 'POST', body: { phone, code } },
      );
      if (res.user.role !== 'admin' && res.user.role !== 'moderator') {
        setError('This account is not an admin.');
        return;
      }
      setAuth(res.access_token, res.user);
      router.replace('/');
    } catch (e) {
      setError(e instanceof ApiError ? e.message : 'Invalid code');
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="grid min-h-screen place-items-center bg-[#F7F4EF] text-[#1C1A17]">
      <div className="w-full max-w-sm rounded-2xl border border-stone-200 bg-white p-8 shadow-sm">
        <h1 className="mb-1 text-2xl font-bold">
          ART-LAVKA <span className="text-[#E2553B]">Admin</span>
        </h1>
        <p className="mb-6 text-sm text-stone-500">
          {phase === 'phone'
            ? 'Sign in with your admin phone.'
            : `Enter the code sent to ${phone}.`}
        </p>

        {phase === 'phone' ? (
          <input
            value={phone}
            onChange={(e) => setPhone(e.target.value)}
            placeholder="+998 90 123 45 67"
            className="mb-4 w-full rounded-lg border border-stone-300 px-3 py-2 outline-none focus:border-[#E2553B]"
          />
        ) : (
          <input
            value={code}
            onChange={(e) => setCode(e.target.value)}
            placeholder="123456"
            inputMode="numeric"
            maxLength={6}
            className="mb-4 w-full rounded-lg border border-stone-300 px-3 py-2 text-center text-xl tracking-widest outline-none focus:border-[#E2553B]"
          />
        )}

        {error && <p className="mb-3 text-sm text-[#C1392B]">{error}</p>}

        <button
          disabled={loading}
          onClick={phase === 'phone' ? requestOtp : verify}
          className="w-full rounded-lg bg-[#E2553B] py-2.5 font-semibold text-white disabled:opacity-60"
        >
          {loading
            ? 'Please wait…'
            : phase === 'phone'
              ? 'Send code'
              : 'Verify'}
        </button>

        {phase === 'code' && (
          <button
            onClick={() => setPhase('phone')}
            className="mt-3 w-full text-sm text-stone-500 hover:underline"
          >
            Change phone
          </button>
        )}
      </div>
    </div>
  );
}

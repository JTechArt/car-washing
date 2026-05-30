'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'
import { api } from '@/lib/api/client'
import { setAuth } from '@/lib/auth'

export default function LoginPage() {
  const router = useRouter()
  const [phone, setPhone] = useState('')
  const [password, setPassword] = useState('')
  const [error, setError] = useState('')
  const [loading, setLoading] = useState(false)

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault()
    setError('')
    setLoading(true)
    try {
      const res = await api.auth.login(phone, password)
      setAuth(res.token, res.role)
      if (res.role === 'SUPER_ADMIN') {
        router.push('/superadmin')
      } else if (res.role === 'MODERATOR') {
        router.push('/moderator')
      } else {
        router.push('/owner')
      }
    } catch (err: unknown) {
      setError(err instanceof Error ? err.message : 'Login failed')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="min-h-screen flex">
      <div className="hidden lg:flex lg:w-1/2 bg-navy-600 flex-col justify-center px-16">
        <h1 className="text-4xl font-bold text-white mb-4">Lva Admin</h1>
        <p className="text-blue-200 text-lg mb-10">
          Manage your car wash operations, pricing, and analytics.
        </p>
        {[
          { icon: '📊', text: 'Real-time revenue analytics' },
          { icon: '🔴', text: 'Live bay status monitoring' },
          { icon: '💳', text: 'Multi-channel payment tracking' },
          { icon: '🏢', text: 'Corporate account management' },
        ].map(({ icon, text }) => (
          <div key={text} className="flex items-center gap-3 mb-4">
            <div className="w-9 h-9 bg-white/15 rounded-xl flex items-center justify-center text-lg">
              {icon}
            </div>
            <span className="text-blue-100">{text}</span>
          </div>
        ))}
      </div>

      <div className="flex-1 flex items-center justify-center px-8">
        <div className="w-full max-w-sm">
          <div className="flex items-center gap-3 mb-8">
            <div className="w-10 h-10 bg-navy-600 rounded-xl flex items-center justify-center text-white font-bold text-lg">
              Լ
            </div>
            <span className="text-xl font-bold">Lva</span>
          </div>
          <h2 className="text-2xl font-bold mb-1">Welcome back</h2>
          <p className="text-gray-500 mb-8">Sign in to your operations portal</p>

          <form onSubmit={handleSubmit} className="space-y-4">
            <div>
              <label className="block text-sm font-semibold text-gray-700 mb-1">
                Phone Number
              </label>
              <input
                type="tel"
                value={phone}
                onChange={e => setPhone(e.target.value)}
                placeholder="+374 77 123 456"
                required
                className="w-full h-12 border border-gray-200 rounded-xl px-4 text-base focus:outline-none focus:border-navy-600 transition"
              />
            </div>
            <div>
              <label className="block text-sm font-semibold text-gray-700 mb-1">
                Password
              </label>
              <input
                type="password"
                value={password}
                onChange={e => setPassword(e.target.value)}
                placeholder="••••••••"
                required
                className="w-full h-12 border border-gray-200 rounded-xl px-4 text-base focus:outline-none focus:border-navy-600 transition"
              />
            </div>
            {error && (
              <p className="text-red-600 text-sm bg-red-50 rounded-lg px-3 py-2">{error}</p>
            )}
            <button
              type="submit"
              disabled={loading}
              className="w-full h-12 bg-navy-600 hover:bg-navy-700 text-white font-bold rounded-xl transition disabled:opacity-50"
            >
              {loading ? 'Signing in…' : 'Sign In'}
            </button>
          </form>
        </div>
      </div>
    </div>
  )
}

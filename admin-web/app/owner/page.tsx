'use client'

import { useEffect, useState } from 'react'
import { api } from '@/lib/api/client'
import { useBayStatus } from '@/lib/useWebSocket'
import BayStatusCard from '@/components/BayStatusCard'
import type { BayResponse, CarWashResponse } from '@/lib/api/types'

export default function OwnerDashboard() {
  const [carWashes, setCarWashes] = useState<CarWashResponse[]>([])
  const [selectedId, setSelectedId] = useState<string | null>(null)
  const [bays, setBays] = useState<BayResponse[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')

  const liveBayStatuses = useBayStatus(selectedId)

  useEffect(() => {
    api.owner.listCarWashes()
      .then(data => {
        setCarWashes(data)
        if (data.length > 0) setSelectedId(data[0].id)
      })
      .catch((e: unknown) => setError(e instanceof Error ? e.message : 'Failed to load'))
      .finally(() => setLoading(false))
  }, [])

  useEffect(() => {
    if (!selectedId) return
    api.owner.listBays(selectedId).then(setBays).catch(console.error)
  }, [selectedId])

  if (loading) return <div className="text-gray-500 py-8">Loading…</div>
  if (error) return <div className="text-red-600 bg-red-50 rounded-lg p-4">{error}</div>

  if (carWashes.length === 0) {
    return (
      <div className="text-center py-20 text-gray-400">
        <div className="text-5xl mb-4">🚗</div>
        <p className="text-xl font-semibold mb-2">No car washes yet</p>
        <p className="text-sm">Register an OWNER account via the API, then add a car wash.</p>
      </div>
    )
  }

  const selected = carWashes.find(w => w.id === selectedId)

  return (
    <div>
      <div className="flex items-center justify-between mb-8">
        <div>
          <h1 className="text-2xl font-bold">{selected?.name ?? '—'}</h1>
          <p className="text-gray-500 text-sm mt-1">{selected?.address}</p>
        </div>
        {carWashes.length > 1 && (
          <select
            value={selectedId ?? ''}
            onChange={e => setSelectedId(e.target.value)}
            className="border border-gray-200 rounded-lg px-3 py-2 text-sm"
          >
            {carWashes.map(w => (
              <option key={w.id} value={w.id}>{w.name}</option>
            ))}
          </select>
        )}
      </div>

      <div>
        <div className="flex items-center gap-3 mb-4">
          <h2 className="text-lg font-semibold">Bay Status</h2>
          <span className="flex items-center gap-1.5 text-xs bg-green-50 text-green-700 font-semibold px-2.5 py-1 rounded-full">
            <span className="w-2 h-2 bg-green-500 rounded-full inline-block" />
            Live
          </span>
        </div>

        {bays.length === 0 ? (
          <p className="text-gray-400 text-sm">No bays configured. Add bays via the API.</p>
        ) : (
          <div className="grid grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-4">
            {bays.map(bay => (
              <BayStatusCard
                key={bay.id}
                bay={bay}
                liveStatus={liveBayStatuses[bay.id]?.status}
              />
            ))}
          </div>
        )}
      </div>
    </div>
  )
}

'use client'

import { useEffect, useState, useCallback } from 'react'
import { api } from '@/lib/api/client'
import { useBayStatus } from '@/lib/useWebSocket'
import ModeratorBayCard from '@/components/ModeratorBayCard'
import type { BayResponse, CarWashResponse } from '@/lib/api/types'

export default function ModeratorPage() {
  const [carWashes, setCarWashes] = useState<CarWashResponse[]>([])
  const [selectedId, setSelectedId] = useState<string | null>(null)
  const [bays, setBays] = useState<BayResponse[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')

  const liveBayStatuses = useBayStatus(selectedId)

  useEffect(() => {
    api.moderator.listCarWashes()
      .then(data => {
        setCarWashes(data)
        if (data.length > 0) setSelectedId(data[0].id)
      })
      .catch((e: unknown) => setError(e instanceof Error ? e.message : 'Failed to load'))
      .finally(() => setLoading(false))
  }, [])

  const loadBays = useCallback(async () => {
    if (!selectedId) return
    try {
      const data = await api.moderator.listBays(selectedId)
      setBays(data)
    } catch (e: unknown) {
      console.error('Failed to reload bays', e)
    }
  }, [selectedId])

  useEffect(() => {
    loadBays()
  }, [loadBays])

  async function handleUpdateStatus(bookingId: string, status: string) {
    await api.moderator.updateBookingStatus(bookingId, status)
    await loadBays()
  }

  async function handleWalkIn(bayId: string, minutes: number) {
    if (minutes > 0) {
      await api.moderator.createWalkIn(bayId, minutes)
    }
    await loadBays()
  }

  if (loading) return <div className="text-gray-500 py-8">Loading…</div>
  if (error) return <div className="text-red-600 bg-red-50 rounded-lg p-4">{error}</div>

  const selected = carWashes.find(w => w.id === selectedId)

  return (
    <div>
      <div className="flex items-center justify-between mb-8">
        <div>
          <h1 className="text-2xl font-bold">{selected?.name ?? '—'}</h1>
          <p className="text-gray-500 text-sm mt-1">{selected?.address}</p>
        </div>
        <div className="flex items-center gap-3">
          <span className="flex items-center gap-1.5 text-xs bg-green-50 text-green-700 font-semibold px-3 py-1.5 rounded-full">
            <span className="w-2 h-2 bg-green-500 rounded-full inline-block" />
            Live
          </span>
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
          <button
            onClick={loadBays}
            className="border border-gray-200 rounded-lg px-3 py-2 text-sm text-gray-600 hover:bg-gray-50 transition"
          >
            ↻ Refresh
          </button>
        </div>
      </div>

      {bays.length === 0 ? (
        <div className="text-center py-20 text-gray-400">
          <div className="text-5xl mb-4">🚗</div>
          <p className="text-lg font-semibold">No bays configured</p>
        </div>
      ) : (
        <div className="grid grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-5">
          {bays.map(bay => (
            <ModeratorBayCard
              key={bay.id}
              bay={bay}
              liveStatus={liveBayStatuses[bay.id]?.status}
              onUpdateStatus={handleUpdateStatus}
              onWalkIn={handleWalkIn}
            />
          ))}
        </div>
      )}
    </div>
  )
}

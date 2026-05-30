'use client'

import { useState } from 'react'
import type { BayResponse, BayStatus } from '@/lib/api/types'
import { nextAction } from '@/lib/api/types'
import WalkInModal from './WalkInModal'

const BORDER: Record<BayStatus, string> = {
  IDLE:     'border-green-400',
  OCCUPIED: 'border-blue-500',
  BLOCKED:  'border-red-400',
}

const BADGE: Record<BayStatus, { bg: string; text: string; label: string }> = {
  IDLE:     { bg: 'bg-green-100',  text: 'text-green-700', label: 'Available' },
  OCCUPIED: { bg: 'bg-blue-100',   text: 'text-blue-700',  label: 'Occupied'  },
  BLOCKED:  { bg: 'bg-red-100',    text: 'text-red-700',   label: 'Blocked'   },
}

const ACTION_BG: Record<string, string> = {
  PENDING:   '#27AE60',
  ARRIVED:   '#1B4F72',
  WASHING:   '#F39C12',
  FINISHING: '#009688',
}

interface ModeratorBayCardProps {
  bay: BayResponse
  liveStatus?: BayStatus
  onUpdateStatus: (bookingId: string, status: string) => Promise<void>
  onWalkIn: (bayId: string, minutes: number) => Promise<void>
}

export default function ModeratorBayCard({
  bay,
  liveStatus,
  onUpdateStatus,
  onWalkIn,
}: ModeratorBayCardProps) {
  const status = liveStatus ?? bay.status
  const effectiveBay: BayResponse = { ...bay, status }
  const border = BORDER[status]
  const badge = BADGE[status]
  const action = nextAction(effectiveBay)

  const [loading, setLoading] = useState(false)
  const [showWalkIn, setShowWalkIn] = useState(false)

  async function handleAction() {
    if (!action || !bay.activeBookingId) return
    setLoading(true)
    try {
      await onUpdateStatus(bay.activeBookingId, action.targetStatus)
    } finally {
      setLoading(false)
    }
  }

  return (
    <>
      <div className={`bg-white rounded-2xl border-2 ${border} p-5 flex flex-col shadow-sm min-h-[200px]`}>
        {/* Header */}
        <div className="flex items-center justify-between mb-4">
          <span className="text-lg font-bold">{bay.name}</span>
          <span className={`text-xs font-bold px-3 py-1 rounded-full ${badge.bg} ${badge.text}`}>
            {bay.activeBookingStatus ?? badge.label}
          </span>
        </div>

        {/* Body */}
        <div className="flex-1">
          {status === 'IDLE' && !bay.activeBookingId && (
            <p className="text-gray-400 text-sm">Ready for next vehicle</p>
          )}
          {bay.activeBookingId && (
            <div className="bg-gray-50 rounded-xl p-3 text-xs space-y-1">
              <div className="flex justify-between">
                <span className="text-gray-400">Booking</span>
                <span className="font-semibold">
                  #{bay.activeBookingId.slice(0, 8).toUpperCase()}
                </span>
              </div>
              {bay.activeBookingStatus && (
                <div className="flex justify-between">
                  <span className="text-gray-400">Status</span>
                  <span className="font-semibold">{bay.activeBookingStatus}</span>
                </div>
              )}
            </div>
          )}
          {status === 'BLOCKED' && !bay.activeBookingId && (
            <p className="text-gray-400 text-sm">Walk-in customer</p>
          )}
        </div>

        {/* Actions */}
        <div className="mt-4 space-y-2">
          {action && bay.activeBookingId && (
            <button
              onClick={handleAction}
              disabled={loading}
              className="w-full h-11 rounded-xl text-sm font-bold text-white transition disabled:opacity-50"
              style={{ backgroundColor: ACTION_BG[bay.activeBookingStatus ?? ''] ?? '#1B4F72' }}
            >
              {loading ? '…' : action.label}
            </button>
          )}
          {status === 'IDLE' && !bay.activeBookingId && (
            <button
              onClick={() => setShowWalkIn(true)}
              className="w-full h-10 rounded-xl text-sm font-semibold border-2 border-gray-200 text-gray-600 hover:border-gray-400 transition"
            >
              + Walk-In
            </button>
          )}
          {status === 'BLOCKED' && !bay.activeBookingId && (
            <button
              onClick={() => onWalkIn(bay.id, 0)}
              disabled={loading}
              className="w-full h-10 rounded-xl text-sm font-semibold border-2 border-gray-200 text-gray-600 hover:border-gray-400 transition disabled:opacity-50"
            >
              Release Bay
            </button>
          )}
        </div>
      </div>

      {showWalkIn && (
        <WalkInModal
          bayName={bay.name}
          onConfirm={minutes => onWalkIn(bay.id, minutes)}
          onClose={() => setShowWalkIn(false)}
        />
      )}
    </>
  )
}

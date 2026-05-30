'use client'

import { useState } from 'react'

interface WalkInModalProps {
  bayName: string
  onConfirm: (minutes: number) => Promise<void>
  onClose: () => void
}

const DURATION_OPTIONS = [15, 25, 45, 60]

export default function WalkInModal({ bayName, onConfirm, onClose }: WalkInModalProps) {
  const [selected, setSelected] = useState(25)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')

  async function handleConfirm() {
    setLoading(true)
    setError('')
    try {
      await onConfirm(selected)
      onClose()
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : 'Failed to create walk-in')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="fixed inset-0 bg-black/40 flex items-center justify-center z-50">
      <div className="bg-white rounded-2xl p-6 w-full max-w-sm shadow-xl">
        <h3 className="text-lg font-bold mb-1">Walk-In — {bayName}</h3>
        <p className="text-gray-500 text-sm mb-4">Select estimated duration:</p>

        <div className="flex gap-2 flex-wrap mb-5">
          {DURATION_OPTIONS.map(min => (
            <button
              key={min}
              onClick={() => setSelected(min)}
              className="px-4 py-2 rounded-xl text-sm font-semibold border-2 transition"
              style={
                selected === min
                  ? { backgroundColor: '#1B4F72', borderColor: '#1B4F72', color: 'white' }
                  : { borderColor: '#e5e7eb', color: '#374151' }
              }
            >
              {min} min
            </button>
          ))}
        </div>

        {error && <p className="text-red-600 text-sm mb-3">{error}</p>}

        <div className="flex gap-3">
          <button
            onClick={onClose}
            disabled={loading}
            className="flex-1 h-11 border border-gray-200 rounded-xl text-sm font-semibold text-gray-700 hover:bg-gray-50 transition disabled:opacity-50"
          >
            Cancel
          </button>
          <button
            onClick={handleConfirm}
            disabled={loading}
            className="flex-1 h-11 rounded-xl text-sm font-bold text-white transition disabled:opacity-50"
            style={{ backgroundColor: '#1B4F72' }}
          >
            {loading ? 'Blocking…' : 'Block Bay'}
          </button>
        </div>
      </div>
    </div>
  )
}

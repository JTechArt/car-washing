'use client'

import { useEffect, useState } from 'react'
import { api, type BulkPriceEntry } from '@/lib/api/client'
import type { CarWashResponse, PriceResponse, ServiceType, VehicleType } from '@/lib/api/types'

const VEHICLE_TYPES: VehicleType[] = ['SEDAN', 'CROSSOVER', 'SUV', 'COUPE']
const SERVICE_TYPES: ServiceType[] = ['EXTERIOR', 'INTERIOR', 'FULL', 'PREMIUM']
const SERVICE_LABELS: Record<ServiceType, string> = {
  EXTERIOR: 'Exterior Wash',
  INTERIOR: 'Interior Clean',
  FULL: 'Full Wash',
  PREMIUM: 'Premium Detail',
}
const VEHICLE_ICONS: Record<VehicleType, string> = {
  SEDAN: '🚗',
  CROSSOVER: '🚙',
  SUV: '🛻',
  COUPE: '🏎️',
}

type PriceCell = { amountAmd: number; durationMinutes: number }
type PriceGrid = Record<string, PriceCell>

function gridKey(v: VehicleType, s: ServiceType) {
  return `${v}__${s}`
}

export default function PricingPage() {
  const [carWashes, setCarWashes] = useState<CarWashResponse[]>([])
  const [selectedId, setSelectedId] = useState<string | null>(null)
  const [grid, setGrid] = useState<PriceGrid>({})
  const [saving, setSaving] = useState(false)
  const [saved, setSaved] = useState(false)
  const [error, setError] = useState('')

  useEffect(() => {
    api.owner.listCarWashes().then(data => {
      setCarWashes(data)
      if (data.length > 0) setSelectedId(data[0].id)
    })
  }, [])

  useEffect(() => {
    if (!selectedId) return
    api.owner.listPrices(selectedId).then((prices: PriceResponse[]) => {
      const g: PriceGrid = {}
      for (const p of prices) {
        g[gridKey(p.vehicleType, p.serviceType)] = {
          amountAmd: p.amountAmd,
          durationMinutes: p.durationMinutes,
        }
      }
      setGrid(g)
    })
  }, [selectedId])

  function updateCell(v: VehicleType, s: ServiceType, field: keyof PriceCell, value: number) {
    const key = gridKey(v, s)
    setGrid(prev => ({
      ...prev,
      [key]: { ...(prev[key] ?? { amountAmd: 0, durationMinutes: 25 }), [field]: value },
    }))
    setSaved(false)
  }

  async function handleSave() {
    if (!selectedId) return
    setSaving(true)
    setError('')
    try {
      const prices: BulkPriceEntry[] = []
      for (const vt of VEHICLE_TYPES) {
        for (const st of SERVICE_TYPES) {
          const cell = grid[gridKey(vt, st)]
          if (cell && (cell.amountAmd > 0 || cell.durationMinutes > 0)) {
            prices.push({
              vehicleType: vt,
              serviceType: st,
              durationMinutes: cell.durationMinutes || 25,
              amountAmd: cell.amountAmd || 0,
            })
          }
        }
      }
      await api.owner.savePrices(selectedId, prices)
      setSaved(true)
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : 'Save failed')
    } finally {
      setSaving(false)
    }
  }

  return (
    <div>
      <div className="flex items-center justify-between mb-6">
        <div>
          <h1 className="text-2xl font-bold">Pricing Management</h1>
          <p className="text-gray-500 text-sm mt-1">
            Set prices per vehicle type and service. Changes apply immediately in the booking app.
          </p>
        </div>
        {carWashes.length > 1 && (
          <select
            value={selectedId ?? ''}
            onChange={e => setSelectedId(e.target.value)}
            className="border border-gray-200 rounded-lg px-3 py-2 text-sm"
          >
            {carWashes.map(w => <option key={w.id} value={w.id}>{w.name}</option>)}
          </select>
        )}
      </div>

      <div className="bg-white rounded-2xl shadow-sm overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full border-collapse">
            <thead>
              <tr className="bg-gray-50">
                <th className="text-left px-5 py-3 text-xs font-bold text-gray-500 uppercase tracking-wider w-40">
                  Vehicle
                </th>
                {SERVICE_TYPES.map(s => (
                  <th key={s} className="text-left px-4 py-3 text-xs font-bold text-gray-500 uppercase tracking-wider">
                    {SERVICE_LABELS[s]}
                  </th>
                ))}
              </tr>
            </thead>
            <tbody>
              {VEHICLE_TYPES.map(vt => (
                <tr key={vt} className="border-t border-gray-100">
                  <td className="px-5 py-4">
                    <div className="flex items-center gap-2">
                      <span className="text-xl">{VEHICLE_ICONS[vt]}</span>
                      <span className="font-semibold text-sm">
                        {vt.charAt(0) + vt.slice(1).toLowerCase()}
                      </span>
                    </div>
                  </td>
                  {SERVICE_TYPES.map(st => {
                    const cell = grid[gridKey(vt, st)] ?? { amountAmd: 0, durationMinutes: 25 }
                    return (
                      <td key={st} className="px-4 py-3">
                        <div className="space-y-1">
                          <div className="flex items-center gap-1">
                            <input
                              type="number"
                              value={cell.amountAmd || ''}
                              onChange={e => updateCell(vt, st, 'amountAmd', Number(e.target.value))}
                              placeholder="0"
                              className="w-24 h-9 border border-gray-200 rounded-lg px-3 text-sm font-semibold text-right focus:outline-none focus:border-navy-600"
                            />
                            <span className="text-xs text-gray-400">֏</span>
                          </div>
                          <div className="flex items-center gap-1">
                            <input
                              type="number"
                              value={cell.durationMinutes || ''}
                              onChange={e => updateCell(vt, st, 'durationMinutes', Number(e.target.value))}
                              placeholder="min"
                              className="w-24 h-8 border border-gray-200 rounded-lg px-3 text-xs text-right focus:outline-none focus:border-navy-600"
                            />
                            <span className="text-xs text-gray-400">min</span>
                          </div>
                        </div>
                      </td>
                    )
                  })}
                </tr>
              ))}
            </tbody>
          </table>
        </div>
        <div className="flex items-center justify-between px-5 py-4 bg-gray-50 border-t border-gray-100">
          <div>
            {error && <p className="text-red-600 text-sm">{error}</p>}
            {saved && <p className="text-green-600 text-sm font-semibold">✓ Prices saved</p>}
          </div>
          <div className="flex gap-3">
            <button
              onClick={() => { setGrid({}); setSaved(false) }}
              className="h-10 px-5 bg-white border border-gray-200 text-gray-700 font-semibold rounded-xl text-sm hover:bg-gray-50 transition"
            >
              Clear
            </button>
            <button
              onClick={handleSave}
              disabled={saving}
              className="h-10 px-5 bg-navy-600 hover:bg-navy-700 text-white font-bold rounded-xl text-sm transition disabled:opacity-50"
            >
              {saving ? 'Saving…' : 'Save Prices'}
            </button>
          </div>
        </div>
      </div>
    </div>
  )
}

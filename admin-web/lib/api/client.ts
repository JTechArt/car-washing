import { getToken } from '../auth'
import type {
  AuthResponse,
  BayResponse,
  CarWashResponse,
  PriceResponse,
} from './types'

const BASE = process.env.NEXT_PUBLIC_API_URL ?? 'http://localhost:9080'

async function request<T>(path: string, options: RequestInit = {}): Promise<T> {
  const token = getToken()
  const res = await fetch(`${BASE}${path}`, {
    ...options,
    headers: {
      'Content-Type': 'application/json',
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
      ...(options.headers ?? {}),
    },
  })
  if (!res.ok) {
    const text = await res.text()
    throw new Error(`${res.status}: ${text}`)
  }
  if (res.status === 204) return undefined as T
  return res.json()
}

export interface BulkPriceEntry {
  vehicleType: string
  serviceType: string
  durationMinutes: number
  amountAmd: number
}

export const api = {
  auth: {
    login: (phone: string, password: string) =>
      request<AuthResponse>('/api/auth/login', {
        method: 'POST',
        body: JSON.stringify({ phone, password }),
      }),
  },
  owner: {
    listCarWashes: () => request<CarWashResponse[]>('/api/owner/car-washes'),
    listBays: (carWashId: string) =>
      request<BayResponse[]>(`/api/owner/car-washes/${carWashId}/bays`),
    listPrices: (carWashId: string) =>
      request<PriceResponse[]>(`/api/owner/car-washes/${carWashId}/prices`),
    savePrices: (carWashId: string, prices: BulkPriceEntry[]) =>
      request<PriceResponse[]>(`/api/owner/car-washes/${carWashId}/prices`, {
        method: 'PUT',
        body: JSON.stringify({ prices }),
      }),
  },
  moderator: {
    listCarWashes: () => request<CarWashResponse[]>('/api/owner/car-washes'),
    listBays: (carWashId: string) =>
      request<BayResponse[]>(`/api/owner/car-washes/${carWashId}/bays`),
    updateBookingStatus: (bookingId: string, status: string) =>
      request<void>(`/api/moderator/bookings/${bookingId}/status`, {
        method: 'PUT',
        body: JSON.stringify({ status }),
      }),
    createWalkIn: (bayId: string, estimatedDurationMinutes: number) =>
      request<void>(`/api/moderator/bays/${bayId}/walk-ins`, {
        method: 'POST',
        body: JSON.stringify({ estimatedDurationMinutes }),
      }),
    releaseBay: (bayId: string) =>
      request<void>(`/api/moderator/bays/${bayId}/release`, {
        method: 'PUT',
      }),
  },
}

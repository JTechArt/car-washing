export type UserRole = 'CUSTOMER' | 'MODERATOR' | 'OWNER' | 'SUPER_ADMIN'
export type BayStatus = 'IDLE' | 'OCCUPIED' | 'BLOCKED'
export type AvailabilityStatus = 'GREEN' | 'YELLOW' | 'RED'
export type VehicleType = 'SEDAN' | 'CROSSOVER' | 'SUV' | 'COUPE'
export type ServiceType = 'EXTERIOR' | 'INTERIOR' | 'FULL' | 'PREMIUM'
export type BookingStatus = 'PENDING' | 'ARRIVED' | 'WASHING' | 'FINISHING' | 'COMPLETED' | 'CANCELLED'

export interface AuthResponse {
  token: string
  role: UserRole
}

export interface CarWashResponse {
  id: string
  name: string
  address: string
  lat: number
  lng: number
}

export interface BayResponse {
  id: string
  name: string
  status: BayStatus
  activeBookingId: string | null
  activeBookingStatus: BookingStatus | null
}

export interface PriceResponse {
  id: string
  vehicleType: VehicleType
  serviceType: ServiceType
  durationMinutes: number
  amountAmd: number
}

export interface BayStatusMessage {
  bayId: string
  status: BayStatus
}

// Maps activeBookingStatus to the next action label and target status
export function nextAction(bay: BayResponse): { label: string; targetStatus: BookingStatus } | null {
  switch (bay.activeBookingStatus) {
    case 'PENDING':   return { label: 'Mark Arrived',   targetStatus: 'ARRIVED' }
    case 'ARRIVED':   return { label: 'Start Washing',  targetStatus: 'WASHING' }
    case 'WASHING':   return { label: 'Mark Finishing', targetStatus: 'FINISHING' }
    case 'FINISHING': return { label: 'Complete',       targetStatus: 'COMPLETED' }
    default:          return null
  }
}

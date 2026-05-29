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

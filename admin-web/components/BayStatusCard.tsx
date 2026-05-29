import type { BayResponse, BayStatus } from '@/lib/api/types'

const STATUS_STYLES: Record<BayStatus, { border: string; badge: string; label: string; dot: string }> = {
  IDLE: {
    border: 'border-green-400',
    badge: 'bg-green-100 text-green-700',
    label: 'Available',
    dot: 'bg-green-400',
  },
  OCCUPIED: {
    border: 'border-blue-400',
    badge: 'bg-blue-100 text-blue-700',
    label: 'Occupied',
    dot: 'bg-blue-400',
  },
  BLOCKED: {
    border: 'border-red-400',
    badge: 'bg-red-100 text-red-700',
    label: 'Blocked',
    dot: 'bg-red-400',
  },
}

interface BayStatusCardProps {
  bay: BayResponse
  liveStatus?: BayStatus
}

export default function BayStatusCard({ bay, liveStatus }: BayStatusCardProps) {
  const status = liveStatus ?? bay.status
  const styles = STATUS_STYLES[status]
  return (
    <div className={`bg-white rounded-2xl border-2 ${styles.border} p-5 shadow-sm`}>
      <div className="flex items-center justify-between mb-3">
        <span className="text-lg font-bold">{bay.name}</span>
        <span className={`text-xs font-bold px-3 py-1 rounded-full ${styles.badge}`}>
          {styles.label}
        </span>
      </div>
      <div className="flex items-center gap-2">
        <div className={`w-2.5 h-2.5 rounded-full ${styles.dot}`} />
        <span className="text-sm text-gray-500">{status}</span>
      </div>
    </div>
  )
}

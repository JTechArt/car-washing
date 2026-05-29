'use client'

import { useEffect, useRef, useState } from 'react'
import { Client } from '@stomp/stompjs'
import { getToken } from './auth'
import type { BayStatusMessage } from './api/types'

export function useBayStatus(carWashId: string | null) {
  const [bays, setBays] = useState<Record<string, BayStatusMessage>>({})
  const clientRef = useRef<Client | null>(null)

  useEffect(() => {
    if (!carWashId) return
    const token = getToken()
    const wsUrl = (process.env.NEXT_PUBLIC_WS_URL ?? 'ws://localhost:8080/ws')
      .replace(/^http/, 'ws')

    const client = new Client({
      brokerURL: wsUrl,
      connectHeaders: token ? { Authorization: `Bearer ${token}` } : {},
      reconnectDelay: 3000,
      onConnect: () => {
        client.subscribe(`/topic/carwash/${carWashId}/bays`, msg => {
          const data: BayStatusMessage = JSON.parse(msg.body)
          setBays(prev => ({ ...prev, [data.bayId]: data }))
        })
      },
    })

    client.activate()
    clientRef.current = client

    return () => {
      client.deactivate()
    }
  }, [carWashId])

  return bays
}

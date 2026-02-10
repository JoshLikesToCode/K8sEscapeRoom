'use client'

import { useAuth, useProgress } from '@/lib/auth'

interface StatsBarProps {
  totalRooms: number
  bossRoomCount: number
}

export function StatsBar({ totalRooms, bossRoomCount }: StatsBarProps) {
  const { isAuthenticated } = useAuth()
  const { completedRooms, isLoading } = useProgress()

  const completedCount = completedRooms.size

  return (
    <div className="flex items-center gap-6 mb-8 p-4 bg-gray-900 rounded-xl border border-gray-800">
      <Stat
        label="Completed"
        value={isAuthenticated ? completedCount : 0}
        total={totalRooms}
        color="green"
        loading={isLoading && isAuthenticated}
      />
      <div className="h-8 w-px bg-gray-800" />
      <Stat label="Available" value={totalRooms} color="blue" />
      <div className="h-8 w-px bg-gray-800" />
      <Stat label="Boss Rooms" value={bossRoomCount} color="purple" />

      {!isAuthenticated && (
        <>
          <div className="h-8 w-px bg-gray-800" />
          <div className="text-xs text-gray-500">
            Login to track progress
          </div>
        </>
      )}
    </div>
  )
}

function Stat({
  label,
  value,
  total,
  color,
  loading,
}: {
  label: string
  value: number
  total?: number
  color: 'green' | 'blue' | 'purple'
  loading?: boolean
}) {
  const colors = {
    green: 'text-terminal-green',
    blue: 'text-k8s-blue',
    purple: 'text-purple-400',
  }

  return (
    <div className="flex items-center gap-3">
      <div>
        {loading ? (
          <div className="h-8 w-12 bg-gray-800 rounded animate-pulse" />
        ) : (
          <p className={`text-2xl font-bold ${colors[color]}`}>
            {value}
            {total !== undefined && <span className="text-gray-500 text-sm">/{total}</span>}
          </p>
        )}
        <p className="text-xs text-gray-500">{label}</p>
      </div>
    </div>
  )
}

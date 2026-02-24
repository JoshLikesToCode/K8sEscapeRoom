'use client'

import { useProgress } from '@/lib/auth'
import { LevelCardWithProgress } from './LevelCardWithProgress'
import type { Level } from './LevelCard'

interface FinalBossRevealProps {
  finalBoss: Omit<Level, 'completed'>
  requiredRoomIds: string[]
}

export function FinalBossReveal({ finalBoss, requiredRoomIds }: FinalBossRevealProps) {
  const { completedRooms } = useProgress()

  const allCompleted = requiredRoomIds.length > 0 && requiredRoomIds.every((id) => completedRooms.has(id))

  if (!allCompleted) {
    return null
  }

  return (
    <div className="mt-8" style={{ animation: 'finalBossReveal 0.7s ease-out' }}>
      <div className="relative rounded-xl p-[2px] bg-gradient-to-r from-red-500 to-orange-500">
        <div className="absolute inset-0 rounded-xl bg-gradient-to-r from-red-500/20 to-orange-500/20 blur-xl animate-pulse" />
        <div className="relative bg-gray-950 rounded-xl p-6">
          <h2 className="text-xl font-bold text-red-400 mb-1 flex items-center justify-center gap-2">
            <span>FINAL BOSS UNLOCKED</span>
            <span className="text-xs px-2 py-0.5 rounded bg-red-500/20 text-red-400 border border-red-500/30">
              💀
            </span>
          </h2>
          <p className="text-gray-500 text-sm mb-4 text-center">
            You&apos;ve completed every room. One last challenge remains.
          </p>
          <div className="max-w-md mx-auto">
            <LevelCardWithProgress level={finalBoss} />
          </div>
        </div>
      </div>
    </div>
  )
}

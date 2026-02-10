'use client'

import { useProgress } from '@/lib/auth'
import { LevelCard, Level } from './LevelCard'

interface LevelCardWithProgressProps {
  level: Omit<Level, 'completed'>
}

/**
 * Wrapper around LevelCard that integrates with the progress context
 * to determine if a room is completed
 */
export function LevelCardWithProgress({ level }: LevelCardWithProgressProps) {
  const { isRoomCompleted } = useProgress()

  const levelWithProgress: Level = {
    ...level,
    completed: isRoomCompleted(level.id),
  }

  return <LevelCard level={levelWithProgress} />
}

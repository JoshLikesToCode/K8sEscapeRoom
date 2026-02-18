'use client'

import { createContext, useContext, useState, useEffect, useCallback, ReactNode } from 'react'
import { useAuth } from '../auth/AuthProvider'
import { apiGet, apiPost, resetRoom, ApiError } from '../api'
import type { UserProgress } from '../auth/types'

// ============================================================================
// Progress Context
// ============================================================================

interface ProgressContextValue {
  /** Set of completed room IDs */
  completedRooms: Set<string>
  /** Whether progress is loading */
  isLoading: boolean
  /** Error message if API is unavailable */
  error: string | null
  /** Check if a room is completed */
  isRoomCompleted: (roomId: string) => boolean
  /** Mark a room as complete (calls API). Throws on failure. */
  markRoomComplete: (roomId: string) => Promise<void>
  /** Reset progress for a room (calls API). Throws on failure. */
  resetRoomProgress: (roomId: string) => Promise<void>
  /** Refresh progress from API */
  refresh: () => Promise<void>
}

const ProgressContext = createContext<ProgressContextValue | null>(null)

interface ProgressProviderProps {
  children: ReactNode
}

export function ProgressProvider({ children }: ProgressProviderProps) {
  const { user, isAuthenticated } = useAuth()
  const [completedRooms, setCompletedRooms] = useState<Set<string>>(new Set())
  const [isLoading, setIsLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const refresh = useCallback(async () => {
    if (!isAuthenticated) {
      setCompletedRooms(new Set())
      setIsLoading(false)
      setError(null)
      return
    }

    setIsLoading(true)
    setError(null)
    try {
      const data = await apiGet<UserProgress>('/api/me')
      setCompletedRooms(new Set(data.completedRooms))
    } catch (err) {
      if (err instanceof ApiError) {
        if (err.isUnauthorized) {
          // User session expired or invalid - treat as unauthenticated
          setCompletedRooms(new Set())
        } else {
          setError(`API error: ${err.message}`)
        }
      } else {
        // Network error
        setError('Unable to connect to API')
      }
    } finally {
      setIsLoading(false)
    }
  }, [isAuthenticated])

  useEffect(() => {
    refresh()
  }, [refresh, user])

  const isRoomCompleted = useCallback(
    (roomId: string) => completedRooms.has(roomId),
    [completedRooms]
  )

  const markRoomComplete = useCallback(async (roomId: string) => {
    if (!isAuthenticated) {
      throw new Error('Must be authenticated to mark rooms complete')
    }

    // Call API - throws on failure
    await apiPost<{ success: boolean }>(`/api/rooms/${roomId}/complete`)

    // Only update local state if API call succeeded
    setCompletedRooms((prev) => new Set([...Array.from(prev), roomId]))
  }, [isAuthenticated])

  const resetRoomProgress = useCallback(async (roomId: string) => {
    if (!isAuthenticated) {
      throw new Error('Must be authenticated to reset room progress')
    }

    await resetRoom(roomId)

    setCompletedRooms((prev) => {
      const next = new Set(prev)
      next.delete(roomId)
      return next
    })
  }, [isAuthenticated])

  const value: ProgressContextValue = {
    completedRooms,
    isLoading,
    error,
    isRoomCompleted,
    markRoomComplete,
    resetRoomProgress,
    refresh,
  }

  return (
    <ProgressContext.Provider value={value}>
      {children}
    </ProgressContext.Provider>
  )
}

/**
 * Hook to access progress state
 */
export function useProgress(): ProgressContextValue {
  const context = useContext(ProgressContext)
  if (!context) {
    throw new Error('useProgress must be used within a ProgressProvider')
  }
  return context
}

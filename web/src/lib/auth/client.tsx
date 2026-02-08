'use client'

import { createContext, useContext, useState, useEffect, useCallback, ReactNode } from 'react'
import type { User, AuthState, UserProgress, AuthMeResponse } from './types'

/** Dev mode mock user for local development */
const DEV_MOCK_USER: User = {
  id: 'dev-user-123',
  username: 'DevUser',
  provider: 'github',
}

/** Whether we're in development mode without auth */
const IS_DEV = process.env.NODE_ENV === 'development'

/**
 * Parse Azure Static Web Apps auth response into User
 */
function parseAuthResponse(data: AuthMeResponse): User | null {
  const principal = data.clientPrincipal
  if (!principal) return null

  return {
    id: principal.userId,
    username: principal.userDetails,
    provider: principal.identityProvider,
  }
}

/**
 * Fetch current user from Azure SWA auth endpoint
 */
async function fetchUser(): Promise<User | null> {
  try {
    const res = await fetch('/.auth/me')
    if (!res.ok) {
      // In dev without SWA, this will 404 - use mock user
      if (IS_DEV) {
        return DEV_MOCK_USER
      }
      return null
    }
    const data: AuthMeResponse = await res.json()
    return parseAuthResponse(data)
  } catch {
    // Network error or not running on SWA - use mock in dev
    if (IS_DEV) {
      return DEV_MOCK_USER
    }
    return null
  }
}

/**
 * Auth URLs for Azure Static Web Apps
 */
export const AUTH_URLS = {
  login: {
    github: '/.auth/login/github',
  },
  logout: '/.auth/logout',
} as const

// ============================================================================
// Auth Context
// ============================================================================

interface AuthContextValue extends AuthState {
  /** Refresh auth state */
  refresh: () => Promise<void>
  /** Login URL for GitHub */
  loginUrl: string
  /** Logout URL */
  logoutUrl: string
}

const AuthContext = createContext<AuthContextValue | null>(null)

interface AuthProviderProps {
  children: ReactNode
}

export function AuthProvider({ children }: AuthProviderProps) {
  const [user, setUser] = useState<User | null>(null)
  const [isLoading, setIsLoading] = useState(true)

  const refresh = useCallback(async () => {
    setIsLoading(true)
    try {
      const user = await fetchUser()
      setUser(user)
    } finally {
      setIsLoading(false)
    }
  }, [])

  useEffect(() => {
    refresh()
  }, [refresh])

  const value: AuthContextValue = {
    user,
    isLoading,
    isAuthenticated: !!user,
    refresh,
    loginUrl: AUTH_URLS.login.github,
    logoutUrl: AUTH_URLS.logout,
  }

  return (
    <AuthContext.Provider value={value}>
      {children}
    </AuthContext.Provider>
  )
}

/**
 * Hook to access auth state
 */
export function useAuth(): AuthContextValue {
  const context = useContext(AuthContext)
  if (!context) {
    throw new Error('useAuth must be used within an AuthProvider')
  }
  return context
}

/**
 * Hook to get current user (convenience wrapper)
 */
export function useUser(): User | null {
  const { user } = useAuth()
  return user
}

// ============================================================================
// Progress Context
// ============================================================================

interface ProgressContextValue {
  /** Set of completed room IDs */
  completedRooms: Set<string>
  /** Whether progress is loading */
  isLoading: boolean
  /** Check if a room is completed */
  isRoomCompleted: (roomId: string) => boolean
  /** Mark a room as complete (calls API) */
  markRoomComplete: (roomId: string) => Promise<void>
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

  const refresh = useCallback(async () => {
    if (!isAuthenticated) {
      setCompletedRooms(new Set())
      return
    }

    setIsLoading(true)
    try {
      const res = await fetch('/api/me')
      if (res.ok) {
        const data: UserProgress = await res.json()
        setCompletedRooms(new Set(data.completedRooms))
      }
    } catch {
      // API not available - keep empty progress
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
    if (!isAuthenticated) return

    try {
      const res = await fetch(`/api/rooms/${roomId}/complete`, {
        method: 'POST',
      })
      if (res.ok) {
        setCompletedRooms((prev) => new Set([...Array.from(prev), roomId]))
      }
    } catch {
      // Failed to mark complete
    }
  }, [isAuthenticated])

  const value: ProgressContextValue = {
    completedRooms,
    isLoading,
    isRoomCompleted,
    markRoomComplete,
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

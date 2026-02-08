'use client'

import { createContext, useContext, useState, useEffect, useCallback, ReactNode } from 'react'
import type { User, AuthState, UserProgress, AuthMeResponse } from './types'
import { apiGet, apiPost, ApiError } from '../api'

/** Dev mode mock user for local development - OPT-IN only */
const DEV_MOCK_USER: User = {
  id: 'dev-user-123',
  username: 'DevUser',
  provider: 'github',
}

/**
 * Check if dev mock auth is enabled.
 * Must explicitly set NEXT_PUBLIC_DEV_AUTH=1 to enable mock auth.
 */
const isDevAuthEnabled = (): boolean => {
  return process.env.NEXT_PUBLIC_DEV_AUTH === '1'
}

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
  // If dev auth is explicitly enabled, use mock user
  if (isDevAuthEnabled()) {
    return DEV_MOCK_USER
  }

  try {
    const res = await fetch('/.auth/me')
    if (!res.ok) {
      // Not authenticated or SWA not available
      return null
    }
    const data: AuthMeResponse = await res.json()
    return parseAuthResponse(data)
  } catch {
    // Network error or not running on SWA - unauthenticated
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
  /** Error message if API is unavailable */
  error: string | null
  /** Check if a room is completed */
  isRoomCompleted: (roomId: string) => boolean
  /** Mark a room as complete (calls API). Throws on failure. */
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
  const [error, setError] = useState<string | null>(null)

  const refresh = useCallback(async () => {
    if (!isAuthenticated) {
      setCompletedRooms(new Set())
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

  const value: ProgressContextValue = {
    completedRooms,
    isLoading,
    error,
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

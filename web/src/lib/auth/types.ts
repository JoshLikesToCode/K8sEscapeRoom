/**
 * Auth types for Azure Static Web Apps authentication
 */

export interface User {
  /** Unique user identifier (from auth provider) */
  id: string
  /** Display username (GitHub username) */
  username: string
  /** Auth provider (e.g., 'github') */
  provider: string
}

export interface AuthState {
  /** Current user or null if not authenticated */
  user: User | null
  /** Whether auth state is still loading */
  isLoading: boolean
  /** Whether user is authenticated */
  isAuthenticated: boolean
}

export interface UserProgress {
  /** User info */
  user: User
  /** List of completed room IDs */
  completedRooms: string[]
}

/**
 * Azure Static Web Apps client principal structure
 * Returned from /.auth/me endpoint
 */
export interface ClientPrincipal {
  identityProvider: string
  userId: string
  userDetails: string
  userRoles: string[]
}

export interface AuthMeResponse {
  clientPrincipal: ClientPrincipal | null
}

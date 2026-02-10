/**
 * Auth module for Azure Static Web Apps authentication
 *
 * This module provides:
 * - User type definitions
 * - AuthProvider for client-side auth state
 * - Hooks: useAuth, useUser
 *
 * Azure Static Web Apps Auth:
 * - Login: /.auth/login/github
 * - Logout: /.auth/logout
 * - User info: /.auth/me
 *
 * In development mode without SWA, a mock user is provided
 * when NEXT_PUBLIC_DEV_AUTH=1 is set.
 */

// Types
export type { User, AuthState, UserProgress, ClientPrincipal } from './types'

// Auth provider and hooks
export { AuthProvider, useAuth, useUser, AUTH_URLS } from './AuthProvider'

// Re-export progress for backwards compatibility
// (components can import from '@/lib/auth' or '@/lib/progress')
export { ProgressProvider, useProgress } from '../progress'

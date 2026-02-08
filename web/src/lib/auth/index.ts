/**
 * Auth module for Azure Static Web Apps authentication
 *
 * This module provides:
 * - User type definitions
 * - AuthProvider for client-side auth state
 * - ProgressProvider for tracking room completion
 * - Hooks: useAuth, useUser, useProgress
 *
 * Azure Static Web Apps Auth:
 * - Login: /.auth/login/github
 * - Logout: /.auth/logout
 * - User info: /.auth/me
 *
 * In development mode without SWA, a mock user is provided.
 */

export type { User, AuthState, UserProgress, ClientPrincipal } from './types'
export {
  AuthProvider,
  ProgressProvider,
  useAuth,
  useUser,
  useProgress,
  AUTH_URLS,
} from './client'

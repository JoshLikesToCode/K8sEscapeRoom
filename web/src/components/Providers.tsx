'use client'

import { ReactNode } from 'react'
import { AuthProvider, ProgressProvider } from '@/lib/auth'

interface ProvidersProps {
  children: ReactNode
}

/**
 * Client-side providers wrapper
 * Wraps the app with auth and progress context providers
 */
export function Providers({ children }: ProvidersProps) {
  return (
    <AuthProvider>
      <ProgressProvider>
        {children}
      </ProgressProvider>
    </AuthProvider>
  )
}

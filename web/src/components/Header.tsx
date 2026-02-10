'use client'

import Link from 'next/link'
import { useAuth } from '@/lib/auth'
import { UserIcon, ServerIcon } from '@/components/icons'

export function Header() {
  const { user, isLoading, isAuthenticated, loginUrl, logoutUrl } = useAuth()

  return (
    <header className="fixed top-0 left-0 right-0 z-50 h-14 border-b border-gray-800 bg-gray-950/95 backdrop-blur">
      <div className="flex h-full items-center justify-between px-4">
        {/* Logo / Title */}
        <Link href="/play" className="flex items-center gap-3 hover:opacity-80 transition-opacity">
          <div className="flex h-8 w-8 items-center justify-center rounded-lg bg-k8s-blue text-white font-bold text-sm">
            K8s
          </div>
          <span className="text-lg font-semibold text-white">
            Escape<span className="text-k8s-blue">Room</span>
          </span>
        </Link>

        {/* Right side */}
        <div className="flex items-center gap-4">
          {/* BYO Cluster badge */}
          <div className="hidden sm:flex items-center gap-2 text-sm text-gray-400 bg-gray-800/50 px-3 py-1.5 rounded-lg border border-gray-700">
            <ServerIcon className="h-4 w-4 text-k8s-blue" />
            <span>BYO Cluster</span>
          </div>

          {/* Auth section */}
          {isLoading ? (
            <div className="flex items-center gap-2">
              <div className="h-8 w-8 rounded-full bg-gray-700 animate-pulse" />
              <span className="hidden sm:block text-sm text-gray-500">Loading...</span>
            </div>
          ) : isAuthenticated && user ? (
            <div className="flex items-center gap-3">
              {/* User info */}
              <div className="flex items-center gap-2">
                <div className="h-8 w-8 rounded-full bg-terminal-green/20 flex items-center justify-center">
                  <span className="text-terminal-green text-sm font-medium">
                    {user.username.charAt(0).toUpperCase()}
                  </span>
                </div>
                <span className="hidden sm:block text-sm text-gray-300">{user.username}</span>
              </div>
              {/* Logout button */}
              <a
                href={logoutUrl}
                className="text-xs text-gray-500 hover:text-gray-300 transition-colors"
              >
                Logout
              </a>
            </div>
          ) : (
            <div className="flex items-center gap-3">
              {/* Guest indicator */}
              <div className="flex items-center gap-2">
                <div className="h-8 w-8 rounded-full bg-gray-700 flex items-center justify-center">
                  <UserIcon className="h-4 w-4 text-gray-400" />
                </div>
                <span className="hidden sm:block text-sm text-gray-400">Guest</span>
              </div>
              {/* Login button */}
              <a
                href={loginUrl}
                className="flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-sm font-medium bg-gray-800 text-gray-300 hover:bg-gray-700 hover:text-white transition-colors border border-gray-700"
              >
                <GitHubIcon className="h-4 w-4" />
                <span className="hidden sm:inline">Login</span>
              </a>
            </div>
          )}
        </div>
      </div>
    </header>
  )
}

function GitHubIcon({ className }: { className?: string }) {
  return (
    <svg className={className} viewBox="0 0 24 24" fill="currentColor">
      <path d="M12 0c-6.626 0-12 5.373-12 12 0 5.302 3.438 9.8 8.207 11.387.599.111.793-.261.793-.577v-2.234c-3.338.726-4.033-1.416-4.033-1.416-.546-1.387-1.333-1.756-1.333-1.756-1.089-.745.083-.729.083-.729 1.205.084 1.839 1.237 1.839 1.237 1.07 1.834 2.807 1.304 3.492.997.107-.775.418-1.305.762-1.604-2.665-.305-5.467-1.334-5.467-5.931 0-1.311.469-2.381 1.236-3.221-.124-.303-.535-1.524.117-3.176 0 0 1.008-.322 3.301 1.23.957-.266 1.983-.399 3.003-.404 1.02.005 2.047.138 3.006.404 2.291-1.552 3.297-1.23 3.297-1.23.653 1.653.242 2.874.118 3.176.77.84 1.235 1.911 1.235 3.221 0 4.609-2.807 5.624-5.479 5.921.43.372.823 1.102.823 2.222v3.293c0 .319.192.694.801.576 4.765-1.589 8.199-6.086 8.199-11.386 0-6.627-5.373-12-12-12z" />
    </svg>
  )
}

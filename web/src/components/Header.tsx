'use client'

import Link from 'next/link'

export function Header() {
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

        {/* Right side - User placeholder */}
        <div className="flex items-center gap-4">
          <div className="hidden sm:flex items-center gap-2 text-sm text-gray-400">
            <span className="text-terminal-green">●</span>
            <span>Cluster Connected</span>
          </div>
          <div className="flex items-center gap-2">
            <div className="h-8 w-8 rounded-full bg-gray-700 flex items-center justify-center">
              <UserIcon className="h-4 w-4 text-gray-400" />
            </div>
            <span className="hidden sm:block text-sm text-gray-300">Guest</span>
          </div>
        </div>
      </div>
    </header>
  )
}

function UserIcon({ className }: { className?: string }) {
  return (
    <svg
      className={className}
      fill="none"
      viewBox="0 0 24 24"
      strokeWidth={1.5}
      stroke="currentColor"
    >
      <path
        strokeLinecap="round"
        strokeLinejoin="round"
        d="M15.75 6a3.75 3.75 0 11-7.5 0 3.75 3.75 0 017.5 0zM4.501 20.118a7.5 7.5 0 0114.998 0A17.933 17.933 0 0112 21.75c-2.676 0-5.216-.584-7.499-1.632z"
      />
    </svg>
  )
}

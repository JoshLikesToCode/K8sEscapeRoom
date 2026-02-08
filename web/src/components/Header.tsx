'use client'

import Link from 'next/link'
import { UserIcon, ServerIcon } from '@/components/icons'

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
          <div className="hidden sm:flex items-center gap-2 text-sm text-gray-400 bg-gray-800/50 px-3 py-1.5 rounded-lg border border-gray-700">
            <ServerIcon className="h-4 w-4 text-k8s-blue" />
            <span>BYO Cluster</span>
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

'use client'

import Link from 'next/link'
import { usePathname } from 'next/navigation'
import { useAuth, useProgress } from '@/lib/auth'

interface SidebarLevel {
  id: string
  name: string
  difficulty: string
}

interface SidebarProps {
  levels: SidebarLevel[]
}

export function Sidebar({ levels }: SidebarProps) {
  const pathname = usePathname()
  const { isAuthenticated } = useAuth()
  const { completedRooms, isLoading: progressLoading } = useProgress()

  const completedCount = levels.filter((l) => completedRooms.has(l.id)).length
  const totalCount = levels.length
  const progressPercent = totalCount > 0 ? Math.round((completedCount / totalCount) * 100) : 0

  return (
    <aside className="fixed left-0 top-14 bottom-0 w-64 border-r border-gray-800 bg-gray-950 overflow-y-auto">
      <div className="p-4 space-y-6">
        {/* Progress Section */}
        <div className="space-y-3">
          <h2 className="text-xs font-semibold uppercase tracking-wider text-gray-500">
            Progress
          </h2>

          {!isAuthenticated ? (
            <div className="p-3 bg-gray-900 rounded-lg border border-gray-800">
              <p className="text-xs text-gray-500">
                Login to track your progress
              </p>
            </div>
          ) : progressLoading ? (
            <div className="grid grid-cols-2 gap-3">
              <div className="bg-gray-900 rounded-lg p-3 border border-gray-800 animate-pulse">
                <div className="h-8 bg-gray-800 rounded mb-1" />
                <div className="h-3 bg-gray-800 rounded w-12" />
              </div>
              <div className="bg-gray-900 rounded-lg p-3 border border-gray-800 animate-pulse">
                <div className="h-8 bg-gray-800 rounded mb-1" />
                <div className="h-3 bg-gray-800 rounded w-12" />
              </div>
            </div>
          ) : (
            <>
              <div className="grid grid-cols-2 gap-3">
                <ProgressCard
                  label="Escaped"
                  value={completedCount.toString()}
                  total={totalCount.toString()}
                  color="green"
                />
                <ProgressCard
                  label="Remaining"
                  value={(totalCount - completedCount).toString()}
                  total={totalCount.toString()}
                  color="blue"
                />
              </div>
              <div className="h-2 bg-gray-800 rounded-full overflow-hidden">
                <div
                  className="h-full bg-gradient-to-r from-terminal-green to-k8s-blue transition-all duration-500"
                  style={{ width: `${progressPercent}%` }}
                />
              </div>
              <p className="text-xs text-gray-500 text-center">{progressPercent}% Complete</p>
            </>
          )}
        </div>

        {/* Levels Section */}
        <div className="space-y-3">
          <h2 className="text-xs font-semibold uppercase tracking-wider text-gray-500">
            Levels
          </h2>
          <nav className="space-y-1">
            {levels.slice(0, 10).map((level) => {
              const isActive = pathname === `/play/${level.id}`
              const isCompleted = completedRooms.has(level.id)

              return (
                <Link
                  key={level.id}
                  href={`/play/${level.id}`}
                  className={`
                    flex items-center gap-3 px-3 py-2 rounded-lg text-sm transition-colors
                    ${isActive ? 'bg-k8s-blue/20 text-white' : 'text-gray-400 hover:bg-gray-800 hover:text-gray-200'}
                  `}
                >
                  <LevelIcon completed={isCompleted} />
                  <div className="flex-1 min-w-0">
                    <p className="truncate font-medium">{level.name}</p>
                    <p className="text-xs text-gray-500 capitalize">{level.difficulty}</p>
                  </div>
                  {isCompleted && <CheckBadge />}
                </Link>
              )
            })}
            {levels.length > 10 && (
              <Link
                href="/play"
                className="block px-3 py-2 text-xs text-gray-500 hover:text-gray-300"
              >
                +{levels.length - 10} more rooms...
              </Link>
            )}
          </nav>
        </div>

      </div>
    </aside>
  )
}

function ProgressCard({
  label,
  value,
  total,
  color,
}: {
  label: string
  value: string
  total: string
  color: 'green' | 'blue'
}) {
  return (
    <div className="bg-gray-900 rounded-lg p-3 border border-gray-800">
      <p className="text-2xl font-bold text-white">
        {value}
        <span className="text-sm text-gray-500">/{total}</span>
      </p>
      <p className={`text-xs ${color === 'green' ? 'text-terminal-green' : 'text-k8s-blue'}`}>
        {label}
      </p>
    </div>
  )
}

function LevelIcon({ completed }: { completed: boolean }) {
  return (
    <div
      className={`
        h-8 w-8 rounded-lg flex items-center justify-center text-xs font-bold
        ${completed ? 'bg-terminal-green/20 text-terminal-green' : 'bg-gray-800 text-gray-500'}
      `}
    >
      {completed ? '✓' : '?'}
    </div>
  )
}

function CheckBadge() {
  return (
    <span className="flex h-5 w-5 items-center justify-center rounded-full bg-terminal-green/20">
      <svg className="h-3 w-3 text-terminal-green" fill="currentColor" viewBox="0 0 20 20">
        <path
          fillRule="evenodd"
          d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z"
          clipRule="evenodd"
        />
      </svg>
    </span>
  )
}

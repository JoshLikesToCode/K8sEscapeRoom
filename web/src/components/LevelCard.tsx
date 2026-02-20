import Link from 'next/link'

export interface Level {
  id: string
  name: string
  description: string
  difficulty: 'beginner' | 'intermediate' | 'advanced' | 'unknown'
  failureMode: string
  completed: boolean
  locked?: boolean
  isBoss?: boolean
  isFinalBoss?: boolean
}

export function LevelCard({ level }: { level: Level }) {
  if (level.locked) {
    return (
      <div className="relative group">
        <div className="absolute inset-0 bg-gradient-to-r from-gray-800/50 to-gray-700/50 rounded-xl blur-xl opacity-0 group-hover:opacity-100 transition-opacity" />
        <div className="relative bg-gray-900/80 border border-gray-800 rounded-xl p-6 opacity-60">
          <div className="flex items-start justify-between mb-4">
            <div className="h-12 w-12 rounded-xl bg-gray-800 flex items-center justify-center">
              <LockIcon className="h-6 w-6 text-gray-600" />
            </div>
            <DifficultyBadge difficulty={level.difficulty} />
          </div>
          <h3 className="text-lg font-semibold text-gray-500 mb-2">{level.name}</h3>
          <p className="text-sm text-gray-600 mb-4">{level.description}</p>
          <div className="flex items-center gap-2">
            <FailureModeBadge mode={level.failureMode} />
          </div>
        </div>
      </div>
    )
  }

  return (
    <Link href={`/play/${level.id}`} className="relative group block">
      <div className={`absolute inset-0 bg-gradient-to-r ${level.isFinalBoss ? 'from-red-500/20 to-orange-500/20' : 'from-k8s-blue/20 to-purple-500/20'} rounded-xl blur-xl opacity-0 group-hover:opacity-100 transition-opacity`} />
      <div className="relative bg-gray-900 border border-gray-800 rounded-xl p-6 hover:border-k8s-blue/50 transition-colors">
        {/* Icon */}
        <div className="flex items-start justify-between mb-4">
          <div
            className={`
              h-12 w-12 rounded-xl flex items-center justify-center text-lg
              ${level.completed ? 'bg-terminal-green/20 text-terminal-green' : level.isFinalBoss ? 'bg-red-500/20 text-red-400' : level.isBoss ? 'bg-purple-500/20 text-purple-400' : 'bg-k8s-blue/20 text-k8s-blue'}
            `}
          >
            {level.completed ? '✓' : level.isFinalBoss ? '💀' : level.isBoss ? '👑' : '🔧'}
          </div>
          {level.completed ? <CompletedBadge /> : <DifficultyBadge difficulty={level.difficulty} />}
        </div>

        {/* Content */}
        <h3 className="text-lg font-semibold text-white mb-2 group-hover:text-k8s-blue transition-colors">
          {level.name}
        </h3>
        <p className="text-sm text-gray-400 mb-4 line-clamp-2">{level.description}</p>

        {/* Tags */}
        <div className="flex items-center gap-2 flex-wrap">
          {level.isFinalBoss ? <FinalBossBadge /> : level.isBoss && <BossBadge />}
          <FailureModeBadge mode={level.failureMode} />
        </div>

        {/* Hover arrow */}
        <div className="absolute bottom-6 right-6 opacity-0 group-hover:opacity-100 transition-opacity">
          <ArrowIcon className="h-5 w-5 text-k8s-blue" />
        </div>
      </div>
    </Link>
  )
}

function DifficultyBadge({ difficulty }: { difficulty: Level['difficulty'] }) {
  const colors: Record<Level['difficulty'], string> = {
    beginner: 'bg-green-500/20 text-green-400 border-green-500/30',
    intermediate: 'bg-yellow-500/20 text-yellow-400 border-yellow-500/30',
    advanced: 'bg-red-500/20 text-red-400 border-red-500/30',
    unknown: 'bg-gray-500/20 text-gray-400 border-gray-500/30',
  }

  return (
    <span
      className={`px-2 py-1 rounded-md text-xs font-medium border capitalize ${colors[difficulty]}`}
    >
      {difficulty}
    </span>
  )
}

function BossBadge() {
  return (
    <span className="px-2 py-1 rounded-md text-xs font-bold bg-purple-500/20 text-purple-400 border border-purple-500/30">
      BOSS
    </span>
  )
}

function FinalBossBadge() {
  return (
    <span className="px-2 py-1 rounded-md text-xs font-bold bg-red-500/20 text-red-400 border border-red-500/30">
      FINAL BOSS
    </span>
  )
}

function FailureModeBadge({ mode }: { mode: string }) {
  return (
    <span className="px-2 py-1 rounded-md text-xs font-mono bg-gray-800 text-terminal-amber border border-gray-700">
      {mode}
    </span>
  )
}

function CompletedBadge() {
  return (
    <span className="flex items-center gap-1 px-2 py-1 rounded-full bg-terminal-green/20 text-terminal-green text-xs font-medium">
      <svg className="h-3 w-3" fill="currentColor" viewBox="0 0 20 20">
        <path
          fillRule="evenodd"
          d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z"
          clipRule="evenodd"
        />
      </svg>
      Escaped
    </span>
  )
}

function LockIcon({ className }: { className?: string }) {
  return (
    <svg className={className} fill="none" viewBox="0 0 24 24" strokeWidth={1.5} stroke="currentColor">
      <path
        strokeLinecap="round"
        strokeLinejoin="round"
        d="M16.5 10.5V6.75a4.5 4.5 0 10-9 0v3.75m-.75 11.25h10.5a2.25 2.25 0 002.25-2.25v-6.75a2.25 2.25 0 00-2.25-2.25H6.75a2.25 2.25 0 00-2.25 2.25v6.75a2.25 2.25 0 002.25 2.25z"
      />
    </svg>
  )
}

function ArrowIcon({ className }: { className?: string }) {
  return (
    <svg className={className} fill="none" viewBox="0 0 24 24" strokeWidth={2} stroke="currentColor">
      <path strokeLinecap="round" strokeLinejoin="round" d="M13.5 4.5L21 12m0 0l-7.5 7.5M21 12H3" />
    </svg>
  )
}

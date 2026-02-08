import { LevelCard, Level } from '@/components'

// Hardcoded fake levels for now
const LEVELS: Level[] = [
  {
    id: 'room-crashloop-env',
    name: 'CrashLoop Mystery',
    description:
      'A pod keeps crashing with CrashLoopBackOff. Something is missing from its configuration. Can you find out what?',
    difficulty: 'beginner',
    failureMode: 'CrashLoopBackOff',
    completed: true,
  },
  {
    id: 'room-imagepull-fail',
    name: 'Image Pull Chaos',
    description:
      'The deployment is stuck with ImagePullBackOff. The image exists... or does it? Debug the pull failure.',
    difficulty: 'beginner',
    failureMode: 'ImagePullBackOff',
    completed: false,
  },
  {
    id: 'room-pending-doom',
    name: 'Pending Forever',
    description:
      'This pod has been Pending for hours. The scheduler refuses to place it. What resource constraints are at play?',
    difficulty: 'intermediate',
    failureMode: 'Pending',
    completed: false,
    locked: true,
  },
  {
    id: 'room-service-void',
    name: 'Service Black Hole',
    description:
      'Traffic is disappearing into the void. The service exists but returns no endpoints. Something is misconfigured.',
    difficulty: 'intermediate',
    failureMode: 'NoEndpoints',
    completed: false,
    locked: true,
  },
]

export default function PlayPage() {
  const completedCount = LEVELS.filter((l) => l.completed).length
  const unlockedCount = LEVELS.filter((l) => !l.locked).length

  return (
    <div className="max-w-6xl mx-auto">
      {/* Header */}
      <div className="mb-8">
        <h1 className="text-3xl font-bold text-white mb-2">Select a Level</h1>
        <p className="text-gray-400">
          Choose an escape room to begin debugging. Complete rooms to unlock more challenges.
        </p>
      </div>

      {/* Stats Bar */}
      <div className="flex items-center gap-6 mb-8 p-4 bg-gray-900 rounded-xl border border-gray-800">
        <Stat label="Completed" value={completedCount} total={LEVELS.length} color="green" />
        <div className="h-8 w-px bg-gray-800" />
        <Stat label="Unlocked" value={unlockedCount} total={LEVELS.length} color="blue" />
        <div className="h-8 w-px bg-gray-800" />
        <Stat label="Total XP" value={150} suffix="xp" color="amber" />
      </div>

      {/* Level Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        {LEVELS.map((level) => (
          <LevelCard key={level.id} level={level} />
        ))}
      </div>

      {/* Coming Soon */}
      <div className="mt-8 p-6 bg-gray-900/50 border border-dashed border-gray-700 rounded-xl text-center">
        <p className="text-gray-500 text-sm">
          More rooms coming soon. Check back for advanced challenges!
        </p>
      </div>
    </div>
  )
}

function Stat({
  label,
  value,
  total,
  suffix,
  color,
}: {
  label: string
  value: number
  total?: number
  suffix?: string
  color: 'green' | 'blue' | 'amber'
}) {
  const colors = {
    green: 'text-terminal-green',
    blue: 'text-k8s-blue',
    amber: 'text-terminal-amber',
  }

  return (
    <div className="flex items-center gap-3">
      <div>
        <p className={`text-2xl font-bold ${colors[color]}`}>
          {value}
          {total !== undefined && <span className="text-gray-500 text-sm">/{total}</span>}
          {suffix && <span className="text-sm ml-1">{suffix}</span>}
        </p>
        <p className="text-xs text-gray-500">{label}</p>
      </div>
    </div>
  )
}

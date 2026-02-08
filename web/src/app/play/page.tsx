import { LevelCard, Level } from '@/components'
import { getAllRooms } from '@/lib/rooms'

export default async function PlayPage() {
  const rooms = await getAllRooms()

  // Convert rooms to Level format for LevelCard
  const levels: Level[] = rooms.map((room) => ({
    id: room.id,
    name: room.title,
    description: room.description,
    difficulty: room.difficulty,
    failureMode: room.failureMode,
    completed: false, // TODO: Track completion in future milestone
    locked: false,
    isBoss: room.isBoss,
  }))

  // Separate regular rooms and boss rooms for display
  const regularRooms = levels.filter((l) => !l.isBoss)
  const bossRooms = levels.filter((l) => l.isBoss)

  const completedCount = levels.filter((l) => l.completed).length
  const totalCount = levels.length

  return (
    <div className="max-w-6xl mx-auto">
      {/* Header */}
      <div className="mb-8">
        <h1 className="text-3xl font-bold text-white mb-2">Select a Level</h1>
        <p className="text-gray-400">
          Choose an escape room to begin debugging. Each room presents a different Kubernetes failure scenario.
        </p>
      </div>

      {/* Stats Bar */}
      <div className="flex items-center gap-6 mb-8 p-4 bg-gray-900 rounded-xl border border-gray-800">
        <Stat label="Completed" value={completedCount} total={totalCount} color="green" />
        <div className="h-8 w-px bg-gray-800" />
        <Stat label="Available" value={totalCount} color="blue" />
        <div className="h-8 w-px bg-gray-800" />
        <Stat label="Boss Rooms" value={bossRooms.length} color="purple" />
      </div>

      {/* Regular Rooms */}
      {regularRooms.length > 0 && (
        <>
          <h2 className="text-xl font-semibold text-white mb-4">Escape Rooms</h2>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mb-8">
            {regularRooms.map((level) => (
              <LevelCard key={level.id} level={level} />
            ))}
          </div>
        </>
      )}

      {/* Boss Rooms */}
      {bossRooms.length > 0 && (
        <>
          <h2 className="text-xl font-semibold text-white mb-4 flex items-center gap-2">
            <span>Boss Rooms</span>
            <span className="text-xs px-2 py-0.5 rounded bg-purple-500/20 text-purple-400 border border-purple-500/30">
              Advanced
            </span>
          </h2>
          <p className="text-gray-500 text-sm mb-4">
            Boss rooms combine multiple failure modes. Fix everything to escape.
          </p>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            {bossRooms.map((level) => (
              <LevelCard key={level.id} level={level} />
            ))}
          </div>
        </>
      )}

      {/* Empty State */}
      {levels.length === 0 && (
        <div className="p-8 bg-gray-900/50 border border-dashed border-gray-700 rounded-xl text-center">
          <p className="text-gray-500">
            No rooms found. Make sure the /rooms directory contains room definitions.
          </p>
        </div>
      )}
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
  color: 'green' | 'blue' | 'amber' | 'purple'
}) {
  const colors = {
    green: 'text-terminal-green',
    blue: 'text-k8s-blue',
    amber: 'text-terminal-amber',
    purple: 'text-purple-400',
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

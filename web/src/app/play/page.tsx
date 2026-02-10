import { getAllRooms } from '@/lib/rooms'
import { LevelCardWithProgress } from '@/components/LevelCardWithProgress'
import { StatsBar } from '@/components/StatsBar'

export default async function PlayPage() {
  const rooms = await getAllRooms()

  // Convert rooms to level format (without completed status - that's handled client-side)
  const levels = rooms.map((room) => ({
    id: room.id,
    name: room.title,
    description: room.description,
    difficulty: room.difficulty,
    failureMode: room.failureMode,
    locked: false,
    isBoss: room.isBoss,
  }))

  // Separate regular rooms and boss rooms for display
  const regularRooms = levels.filter((l) => !l.isBoss)
  const bossRooms = levels.filter((l) => l.isBoss)

  return (
    <div className="max-w-6xl mx-auto">
      {/* Header */}
      <div className="mb-8">
        <h1 className="text-3xl font-bold text-white mb-2">Select a Level</h1>
        <p className="text-gray-400">
          Choose an escape room to begin debugging. Each room presents a different Kubernetes failure scenario.
        </p>
      </div>

      {/* Stats Bar - client component for live progress */}
      <StatsBar totalRooms={levels.length} bossRoomCount={bossRooms.length} />

      {/* Regular Rooms */}
      {regularRooms.length > 0 && (
        <>
          <h2 className="text-xl font-semibold text-white mb-4">Escape Rooms</h2>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mb-8">
            {regularRooms.map((level) => (
              <LevelCardWithProgress key={level.id} level={level} />
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
              <LevelCardWithProgress key={level.id} level={level} />
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

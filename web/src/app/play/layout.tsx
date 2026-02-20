import { Header } from '@/components/Header'
import { Sidebar } from '@/components/Sidebar'
import { getAllRooms } from '@/lib/rooms'

export default async function PlayLayout({ children }: { children: React.ReactNode }) {
  const rooms = await getAllRooms()

  // Convert rooms to sidebar-compatible format (exclude final boss)
  const visibleRooms = rooms.filter((room) => !room.isFinalBoss)
  const sidebarLevels = visibleRooms.map((room) => ({
    id: room.id,
    name: room.title,
    difficulty: room.difficulty,
  }))
  const finalBossRoomId = rooms.find((room) => room.isFinalBoss)?.id

  return (
    <div className="min-h-screen bg-gray-950">
      <Header />
      <Sidebar levels={sidebarLevels} finalBossRoomId={finalBossRoomId} />
      <main className="pl-64 pt-14">
        <div className="p-6">{children}</div>
      </main>
    </div>
  )
}

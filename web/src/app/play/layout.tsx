import { Header } from '@/components/Header'
import { Sidebar } from '@/components/Sidebar'

export default function PlayLayout({ children }: { children: React.ReactNode }) {
  return (
    <div className="min-h-screen bg-gray-950">
      <Header />
      <Sidebar />
      <main className="pl-64 pt-14">
        <div className="p-6">{children}</div>
      </main>
    </div>
  )
}

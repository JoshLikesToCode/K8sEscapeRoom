import Link from 'next/link'
import { ArrowLeftIcon } from '@/components/icons'

export default function RoomNotFound() {
  return (
    <div className="max-w-4xl mx-auto">
      <div className="text-center py-16">
        <div className="text-6xl mb-6">🔍</div>
        <h1 className="text-2xl font-bold text-white mb-4">Room Not Found</h1>
        <p className="text-gray-400 mb-6">
          This room doesn&apos;t exist or hasn&apos;t been implemented yet.
        </p>
        <Link
          href="/play"
          className="inline-flex items-center gap-2 px-4 py-2 bg-k8s-blue text-white rounded-lg hover:bg-k8s-blue/80 transition-colors"
        >
          <ArrowLeftIcon className="h-4 w-4" />
          Back to Level Select
        </Link>
      </div>
    </div>
  )
}

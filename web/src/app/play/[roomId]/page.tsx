import Link from 'next/link'
import { notFound } from 'next/navigation'
import { getRoomById } from '@/lib/rooms'
import { parseHintsMarkdown } from '@/lib/rooms/parseHints'
import { CommandPanel, HintAccordion, ProofSubmit, SingleCommand, MarkdownRenderer } from '@/components'
import {
  ArrowLeftIcon,
  TargetIcon,
  PlayIcon,
  EyeOffIcon,
  ChevronDownIcon,
} from '@/components/icons'

const difficultyColors: Record<string, string> = {
  beginner: 'bg-green-500/20 text-green-400 border-green-500/30',
  intermediate: 'bg-yellow-500/20 text-yellow-400 border-yellow-500/30',
  advanced: 'bg-red-500/20 text-red-400 border-red-500/30',
  unknown: 'bg-gray-500/20 text-gray-400 border-gray-500/30',
}

interface PageProps {
  params: Promise<{ roomId: string }>
}

export default async function RoomDetailPage({ params }: PageProps) {
  const { roomId } = await params
  const room = await getRoomById(roomId)

  if (!room) {
    notFound()
  }

  // Parse hints from markdown
  const hints = parseHintsMarkdown(room.hintsMarkdown)

  // Build commands for this room
  const commands = [
    {
      label: 'Check pod status',
      command: `kubectl get pods -n ${room.namespace}`,
      description: 'See the current state of pods in the namespace',
    },
    {
      label: 'View events',
      command: `kubectl get events -n ${room.namespace} --sort-by='.lastTimestamp'`,
      description: 'Check recent events for error details',
    },
    {
      label: 'Describe pods',
      command: `kubectl describe pods -n ${room.namespace}`,
      description: 'Get detailed information about pods',
    },
    {
      label: 'Check logs',
      command: `kubectl logs -l app.kubernetes.io/part-of=K8sEscapeRoom -n ${room.namespace}`,
      description: 'View the application logs',
    },
  ]

  return (
    <div className="max-w-6xl mx-auto">
      {/* Back link */}
      <Link
        href="/play"
        className="inline-flex items-center gap-2 text-sm text-gray-400 hover:text-white transition-colors mb-6"
      >
        <ArrowLeftIcon className="h-4 w-4" />
        Back to Level Select
      </Link>

      {/* Header */}
      <div className="mb-8">
        <div className="flex items-start justify-between gap-4 mb-4">
          <div>
            <h1 className="text-3xl font-bold text-white mb-2">{room.title}</h1>
            <div className="flex items-center gap-3">
              <span
                className={`px-2 py-1 rounded-md text-xs font-medium border capitalize ${difficultyColors[room.difficulty]}`}
              >
                {room.difficulty}
              </span>
              <span className="px-2 py-1 rounded-md text-xs font-mono bg-gray-800 text-terminal-amber border border-gray-700">
                {room.failureMode}
              </span>
              {room.isBoss && (
                <span className="px-2 py-1 rounded-md text-xs font-bold bg-purple-500/20 text-purple-400 border border-purple-500/30">
                  BOSS
                </span>
              )}
            </div>
          </div>
          <div className="flex items-center gap-2">
            <button className="px-4 py-2 bg-gray-800 text-gray-300 rounded-lg hover:bg-gray-700 transition-colors text-sm">
              Reset Room
            </button>
          </div>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Main Content */}
        <div className="lg:col-span-2 space-y-6">
          {/* Objective */}
          <section className="bg-gray-900 border border-gray-800 rounded-xl p-6">
            <h2 className="text-lg font-semibold text-white mb-4 flex items-center gap-2">
              <TargetIcon className="h-5 w-5 text-k8s-blue" />
              {room.isBoss ? 'Incident Report' : 'Objective'}
            </h2>
            {room.objectiveMarkdown ? (
              <MarkdownRenderer content={room.objectiveMarkdown} />
            ) : (
              <div className="p-4 bg-yellow-500/10 border border-yellow-500/30 rounded-lg">
                <p className="text-yellow-400 text-sm">
                  Objective file missing. See docs/RoomContract.md for the expected format.
                </p>
              </div>
            )}
            {room.warnings.length > 0 && (
              <div className="mt-4 p-3 bg-gray-800/50 rounded-lg border border-gray-700">
                <p className="text-xs text-gray-500">
                  Warnings: {room.warnings.join(', ')}
                </p>
              </div>
            )}
          </section>

          {/* Quick Start */}
          <section className="bg-gray-900 border border-gray-800 rounded-xl p-6">
            <h2 className="text-lg font-semibold text-white mb-4 flex items-center gap-2">
              <PlayIcon className="h-5 w-5 text-terminal-green" />
              Quick Start
            </h2>
            <p className="text-gray-400 mb-4">
              Run this command in your terminal to set up the room:
            </p>
            <SingleCommand command={`make room-apply ROOM=${roomId}`} />
            <p className="text-xs text-gray-500 mt-3">
              This creates the namespace{' '}
              <code className="text-terminal-green">{room.namespace}</code> with the broken
              resources.
            </p>

            <div className="mt-4 pt-4 border-t border-gray-800">
              <p className="text-gray-400 text-sm mb-3">Other useful commands:</p>
              <div className="space-y-2">
                <SingleCommand command={`make room-test ROOM=${roomId}`} />
                <p className="text-xs text-gray-500 ml-1">Verify the room is in the expected broken state</p>
              </div>
              <div className="space-y-2 mt-3">
                <SingleCommand command={`make room-escape-test ROOM=${roomId}`} />
                <p className="text-xs text-gray-500 ml-1">Test if you have successfully fixed all issues</p>
              </div>
              <div className="space-y-2 mt-3">
                <SingleCommand command={`make room-reset ROOM=${roomId}`} />
                <p className="text-xs text-gray-500 ml-1">Reset the room to try again</p>
              </div>
            </div>
          </section>

          {/* Commands */}
          <CommandPanel commands={commands} />
        </div>

        {/* Sidebar */}
        <div className="space-y-6">
          {/* Hints */}
          {hints.length > 0 ? (
            <HintAccordion hints={hints} />
          ) : (
            <div className="bg-gray-900 border border-gray-800 rounded-xl p-4">
              <p className="text-gray-500 text-sm">No hints available for this room.</p>
            </div>
          )}

          {/* Proof Submit */}
          <ProofSubmit roomId={roomId} />

          {/* Solution (spoiler) */}
          <div className="bg-gray-900 border border-gray-800 rounded-xl overflow-hidden">
            <details className="group">
              <summary className="px-4 py-3 cursor-pointer hover:bg-gray-800/50 transition-colors flex items-center justify-between">
                <span className="text-sm font-medium text-gray-400 flex items-center gap-2">
                  <EyeOffIcon className="h-4 w-4" />
                  View Solution (Spoiler)
                </span>
                <ChevronDownIcon className="h-4 w-4 text-gray-500 group-open:rotate-180 transition-transform" />
              </summary>
              <div className="px-4 pb-4 border-t border-gray-800">
                {/* Locked banner */}
                <div className="mt-3 mb-4 p-3 bg-gray-800/50 rounded-lg border border-gray-700 flex items-center gap-3">
                  <div className="h-8 w-8 rounded-full bg-gray-700 flex items-center justify-center">
                    <EyeOffIcon className="h-4 w-4 text-gray-500" />
                  </div>
                  <div>
                    <p className="text-sm text-gray-400">Solution preview locked</p>
                    <p className="text-xs text-gray-500">Complete the room to unlock the full solution here</p>
                  </div>
                </div>

                <p className="text-sm text-gray-400">Run this to see the full solution:</p>
                <div className="mt-2">
                  <SingleCommand command={`make room-solution ROOM=${roomId}`} />
                </div>

                {room.solutionMarkdown && (
                  <details className="mt-4">
                    <summary className="text-xs text-gray-500 cursor-pointer hover:text-gray-400">
                      Show solution anyway (spoiler)
                    </summary>
                    <div className="mt-3 p-4 bg-gray-800/30 rounded-lg border border-gray-700">
                      <MarkdownRenderer content={room.solutionMarkdown} />
                    </div>
                  </details>
                )}
              </div>
            </details>
          </div>
        </div>
      </div>
    </div>
  )
}

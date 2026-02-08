'use client'

import Link from 'next/link'
import { useParams } from 'next/navigation'
import { CommandPanel, HintAccordion, ProofSubmit, SingleCommand } from '@/components'
import type { Command, Hint } from '@/components'

// Hardcoded room data for now
const ROOMS: Record<
  string,
  {
    name: string
    difficulty: 'beginner' | 'intermediate' | 'advanced'
    failureMode: string
    objective: string
    scenario: string
    namespace: string
    commands: Command[]
    hints: Hint[]
  }
> = {
  'room-crashloop-env': {
    name: 'CrashLoop Mystery',
    difficulty: 'beginner',
    failureMode: 'CrashLoopBackOff',
    namespace: 'escape-room-crashloop-env',
    objective:
      'Fix the pod so it starts successfully and stays running. The application should print a startup message and remain healthy.',
    scenario: `Your team deployed a new service last night, but it's been crashing ever since. The pod keeps restarting with CrashLoopBackOff status.

The on-call engineer checked the logs but couldn't figure out the issue. Now it's your turn to debug.

Something is missing from the pod's configuration. Can you find what's causing the crash and fix it?`,
    commands: [
      {
        label: 'Check pod status',
        command: 'kubectl get pods -n escape-room-crashloop-env',
        description: 'See the current state of pods in the namespace',
      },
      {
        label: 'View pod details',
        command: 'kubectl describe pod escape-app -n escape-room-crashloop-env',
        description: 'Get detailed information about the pod',
      },
      {
        label: 'Check logs',
        command: 'kubectl logs escape-app -n escape-room-crashloop-env',
        description: 'View the application logs',
      },
      {
        label: 'Check previous logs',
        command: 'kubectl logs escape-app -n escape-room-crashloop-env --previous',
        description: 'View logs from the previous crashed container',
      },
    ],
    hints: [
      {
        level: 1,
        title: 'Where to look',
        content:
          'Start by checking the pod logs. The application usually prints helpful error messages when it fails to start.',
      },
      {
        level: 2,
        title: 'What kind of error',
        content:
          'The application is crashing because it expects certain environment variables to be set. Check what variables the app needs.',
      },
      {
        level: 3,
        title: 'The fix',
        content:
          'You need to add an environment variable to the pod spec. Look for DATABASE_URL or similar connection strings that the app requires.',
      },
    ],
  },
  'room-imagepull-fail': {
    name: 'Image Pull Chaos',
    difficulty: 'beginner',
    failureMode: 'ImagePullBackOff',
    namespace: 'escape-room-imagepull-fail',
    objective:
      'Fix the deployment so pods can successfully pull their container image and start running.',
    scenario: `A new deployment was rolled out but none of the pods are starting. They're all stuck in ImagePullBackOff.

The DevOps team swears the image was pushed to the registry. The developer claims the image name is correct. Someone is wrong.

Debug the image pull failure and get the deployment running.`,
    commands: [
      {
        label: 'Check pod status',
        command: 'kubectl get pods -n escape-room-imagepull-fail',
        description: 'See the current state of pods',
      },
      {
        label: 'View events',
        command: 'kubectl get events -n escape-room-imagepull-fail --sort-by=.lastTimestamp',
        description: 'Check recent events for error details',
      },
      {
        label: 'Describe pod',
        command: 'kubectl describe pod -l app=escape-app -n escape-room-imagepull-fail',
        description: 'Get detailed pod information including image pull errors',
      },
    ],
    hints: [
      {
        level: 1,
        title: 'Check the events',
        content:
          'Events often contain detailed error messages about why an image pull failed. Look for the exact error.',
      },
      {
        level: 2,
        title: 'Image name inspection',
        content:
          'The image name might have a typo, wrong tag, or reference a non-existent registry. Double-check every part of the image reference.',
      },
      {
        level: 3,
        title: 'Common mistakes',
        content:
          'Check for: typos in image name, wrong tag version, missing registry prefix, or private registry without imagePullSecrets.',
      },
    ],
  },
}

export default function RoomDetailPage() {
  const params = useParams()
  const roomId = params.roomId as string

  const room = ROOMS[roomId]

  if (!room) {
    return (
      <div className="max-w-4xl mx-auto">
        <div className="text-center py-16">
          <h1 className="text-2xl font-bold text-white mb-4">Room Not Found</h1>
          <p className="text-gray-400 mb-6">
            The room &quot;{roomId}&quot; doesn&apos;t exist or hasn&apos;t been implemented yet.
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

  const difficultyColors = {
    beginner: 'bg-green-500/20 text-green-400 border-green-500/30',
    intermediate: 'bg-yellow-500/20 text-yellow-400 border-yellow-500/30',
    advanced: 'bg-red-500/20 text-red-400 border-red-500/30',
  }

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
            <h1 className="text-3xl font-bold text-white mb-2">{room.name}</h1>
            <div className="flex items-center gap-3">
              <span
                className={`px-2 py-1 rounded-md text-xs font-medium border capitalize ${difficultyColors[room.difficulty]}`}
              >
                {room.difficulty}
              </span>
              <span className="px-2 py-1 rounded-md text-xs font-mono bg-gray-800 text-terminal-amber border border-gray-700">
                {room.failureMode}
              </span>
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
              Objective
            </h2>
            <p className="text-gray-300">{room.objective}</p>
          </section>

          {/* Scenario */}
          <section className="bg-gray-900 border border-gray-800 rounded-xl p-6">
            <h2 className="text-lg font-semibold text-white mb-4 flex items-center gap-2">
              <BookIcon className="h-5 w-5 text-terminal-amber" />
              Scenario
            </h2>
            <p className="text-gray-400 whitespace-pre-line">{room.scenario}</p>
          </section>

          {/* Quick Start */}
          <section className="bg-gray-900 border border-gray-800 rounded-xl p-6">
            <h2 className="text-lg font-semibold text-white mb-4 flex items-center gap-2">
              <PlayIcon className="h-5 w-5 text-terminal-green" />
              Quick Start
            </h2>
            <p className="text-gray-400 mb-4">
              Run this command in your terminal to enter the room:
            </p>
            <SingleCommand command={`make room-apply ROOM=${roomId}`} />
            <p className="text-xs text-gray-500 mt-3">
              This creates the namespace <code className="text-terminal-green">{room.namespace}</code> with the
              broken resources.
            </p>
          </section>

          {/* Commands */}
          <CommandPanel commands={room.commands} />
        </div>

        {/* Sidebar */}
        <div className="space-y-6">
          {/* Hints */}
          <HintAccordion hints={room.hints} />

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
                <ChevronIcon className="h-4 w-4 text-gray-500 group-open:rotate-180 transition-transform" />
              </summary>
              <div className="px-4 pb-4 border-t border-gray-800">
                <p className="text-sm text-gray-400 mt-3">
                  Run this to see the full solution:
                </p>
                <div className="mt-2">
                  <SingleCommand command={`make room-solution ROOM=${roomId}`} />
                </div>
              </div>
            </details>
          </div>
        </div>
      </div>
    </div>
  )
}

function ArrowLeftIcon({ className }: { className?: string }) {
  return (
    <svg className={className} fill="none" viewBox="0 0 24 24" strokeWidth={2} stroke="currentColor">
      <path strokeLinecap="round" strokeLinejoin="round" d="M10.5 19.5L3 12m0 0l7.5-7.5M3 12h18" />
    </svg>
  )
}

function TargetIcon({ className }: { className?: string }) {
  return (
    <svg className={className} fill="none" viewBox="0 0 24 24" strokeWidth={1.5} stroke="currentColor">
      <path
        strokeLinecap="round"
        strokeLinejoin="round"
        d="M12 21a9 9 0 100-18 9 9 0 000 18z"
      />
      <path strokeLinecap="round" strokeLinejoin="round" d="M12 15a3 3 0 100-6 3 3 0 000 6z" />
      <path strokeLinecap="round" strokeLinejoin="round" d="M12 12h.01" />
    </svg>
  )
}

function BookIcon({ className }: { className?: string }) {
  return (
    <svg className={className} fill="none" viewBox="0 0 24 24" strokeWidth={1.5} stroke="currentColor">
      <path
        strokeLinecap="round"
        strokeLinejoin="round"
        d="M12 6.042A8.967 8.967 0 006 3.75c-1.052 0-2.062.18-3 .512v14.25A8.987 8.987 0 016 18c2.305 0 4.408.867 6 2.292m0-14.25a8.966 8.966 0 016-2.292c1.052 0 2.062.18 3 .512v14.25A8.987 8.987 0 0018 18a8.967 8.967 0 00-6 2.292m0-14.25v14.25"
      />
    </svg>
  )
}

function PlayIcon({ className }: { className?: string }) {
  return (
    <svg className={className} fill="none" viewBox="0 0 24 24" strokeWidth={1.5} stroke="currentColor">
      <path
        strokeLinecap="round"
        strokeLinejoin="round"
        d="M5.25 5.653c0-.856.917-1.398 1.667-.986l11.54 6.348a1.125 1.125 0 010 1.971l-11.54 6.347a1.125 1.125 0 01-1.667-.985V5.653z"
      />
    </svg>
  )
}

function EyeOffIcon({ className }: { className?: string }) {
  return (
    <svg className={className} fill="none" viewBox="0 0 24 24" strokeWidth={1.5} stroke="currentColor">
      <path
        strokeLinecap="round"
        strokeLinejoin="round"
        d="M3.98 8.223A10.477 10.477 0 001.934 12C3.226 16.338 7.244 19.5 12 19.5c.993 0 1.953-.138 2.863-.395M6.228 6.228A10.45 10.45 0 0112 4.5c4.756 0 8.773 3.162 10.065 7.498a10.523 10.523 0 01-4.293 5.774M6.228 6.228L3 3m3.228 3.228l3.65 3.65m7.894 7.894L21 21m-3.228-3.228l-3.65-3.65m0 0a3 3 0 10-4.243-4.243m4.242 4.242L9.88 9.88"
      />
    </svg>
  )
}

function ChevronIcon({ className }: { className?: string }) {
  return (
    <svg className={className} fill="none" viewBox="0 0 24 24" strokeWidth={2} stroke="currentColor">
      <path strokeLinecap="round" strokeLinejoin="round" d="M19.5 8.25l-7.5 7.5-7.5-7.5" />
    </svg>
  )
}

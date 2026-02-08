'use client'

import { useState } from 'react'

export interface Hint {
  level: number
  title: string
  content: string
}

export function HintAccordion({ hints }: { hints: Hint[] }) {
  const [openHint, setOpenHint] = useState<number | null>(null)
  const [revealedHints, setRevealedHints] = useState<Set<number>>(new Set())

  const handleToggle = (level: number) => {
    if (!revealedHints.has(level)) {
      const newSet = new Set(revealedHints)
      newSet.add(level)
      setRevealedHints(newSet)
    }
    setOpenHint(openHint === level ? null : level)
  }

  return (
    <div className="bg-gray-900 border border-gray-800 rounded-xl overflow-hidden">
      <div className="px-4 py-3 border-b border-gray-800 flex items-center justify-between">
        <div className="flex items-center gap-2">
          <LightbulbIcon className="h-4 w-4 text-terminal-amber" />
          <h3 className="text-sm font-semibold text-white">Hints</h3>
        </div>
        <span className="text-xs text-gray-500">
          {revealedHints.size}/{hints.length} revealed
        </span>
      </div>
      <div className="divide-y divide-gray-800">
        {hints.map((hint) => {
          const isRevealed = revealedHints.has(hint.level)
          const isOpen = openHint === hint.level

          return (
            <div key={hint.level} className="group">
              <button
                onClick={() => handleToggle(hint.level)}
                className="w-full px-4 py-3 flex items-center justify-between text-left hover:bg-gray-800/50 transition-colors"
              >
                <div className="flex items-center gap-3">
                  <span
                    className={`
                      flex h-6 w-6 items-center justify-center rounded-full text-xs font-bold
                      ${isRevealed
                        ? 'bg-terminal-amber/20 text-terminal-amber'
                        : 'bg-gray-800 text-gray-500'
                      }
                    `}
                  >
                    {hint.level}
                  </span>
                  <span
                    className={`text-sm font-medium ${isRevealed ? 'text-white' : 'text-gray-400'}`}
                  >
                    {isRevealed ? hint.title : `Hint Level ${hint.level}`}
                  </span>
                </div>
                <div className="flex items-center gap-2">
                  {!isRevealed && (
                    <span className="text-xs text-terminal-amber bg-terminal-amber/10 px-2 py-0.5 rounded">
                      Click to reveal
                    </span>
                  )}
                  <ChevronIcon
                    className={`h-4 w-4 text-gray-500 transition-transform ${isOpen ? 'rotate-180' : ''}`}
                  />
                </div>
              </button>
              {isOpen && isRevealed && (
                <div className="px-4 pb-4">
                  <div className="ml-9 p-3 bg-gray-800/50 rounded-lg border border-gray-700">
                    <p className="text-sm text-gray-300 whitespace-pre-wrap">{hint.content}</p>
                  </div>
                </div>
              )}
            </div>
          )
        })}
      </div>
    </div>
  )
}

function LightbulbIcon({ className }: { className?: string }) {
  return (
    <svg className={className} fill="none" viewBox="0 0 24 24" strokeWidth={1.5} stroke="currentColor">
      <path
        strokeLinecap="round"
        strokeLinejoin="round"
        d="M12 18v-5.25m0 0a6.01 6.01 0 001.5-.189m-1.5.189a6.01 6.01 0 01-1.5-.189m3.75 7.478a12.06 12.06 0 01-4.5 0m3.75 2.383a14.406 14.406 0 01-3 0M14.25 18v-.192c0-.983.658-1.823 1.508-2.316a7.5 7.5 0 10-7.517 0c.85.493 1.509 1.333 1.509 2.316V18"
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

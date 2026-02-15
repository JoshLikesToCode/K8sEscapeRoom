'use client'

import { useState, useRef, useEffect } from 'react'
import { useProgress } from '@/lib/progress'

interface ResetButtonProps {
  roomId: string
}

export function ResetButton({ roomId }: ResetButtonProps) {
  const { isRoomCompleted, resetRoomProgress } = useProgress()
  const [showPrompt, setShowPrompt] = useState(false)
  const [input, setInput] = useState('')
  const [isResetting, setIsResetting] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [lines, setLines] = useState<Array<{ text: string; type: 'info' | 'warn' | 'error' | 'success' | 'prompt' }>>([])
  const inputRef = useRef<HTMLInputElement>(null)
  const terminalRef = useRef<HTMLDivElement>(null)

  const completed = isRoomCompleted(roomId)

  useEffect(() => {
    if (showPrompt && inputRef.current) {
      inputRef.current.focus()
    }
  }, [showPrompt])

  useEffect(() => {
    if (terminalRef.current) {
      terminalRef.current.scrollTop = terminalRef.current.scrollHeight
    }
  }, [lines])

  if (!completed) return null

  const handleOpen = () => {
    setShowPrompt(true)
    setInput('')
    setError(null)
    setLines([
      { text: `$ kubectl delete namespace escape-${roomId}`, type: 'info' },
      { text: `WARNING: This will reset all progress for ${roomId}.`, type: 'warn' },
      { text: 'Your completion status will be cleared.', type: 'warn' },
      { text: '', type: 'info' },
      { text: 'Type RESET to confirm:', type: 'prompt' },
    ])
  }

  const handleClose = () => {
    if (isResetting) return
    setShowPrompt(false)
    setInput('')
    setError(null)
    setLines([])
  }

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()

    if (input.trim() !== 'RESET') {
      setLines((prev) => [
        ...prev,
        { text: `> ${input}`, type: 'info' },
        { text: `error: expected "RESET", got "${input.trim()}"`, type: 'error' },
        { text: 'Type RESET to confirm:', type: 'prompt' },
      ])
      setInput('')
      return
    }

    setLines((prev) => [
      ...prev,
      { text: '> RESET', type: 'info' },
      { text: 'Resetting room progress...', type: 'info' },
    ])
    setIsResetting(true)
    setError(null)

    try {
      await resetRoomProgress(roomId)
      setLines((prev) => [
        ...prev,
        { text: `namespace "escape-${roomId}" deleted`, type: 'success' },
        { text: 'Room progress has been reset.', type: 'success' },
      ])
      setTimeout(() => {
        setShowPrompt(false)
        setLines([])
      }, 1200)
    } catch {
      setLines((prev) => [
        ...prev,
        { text: 'error: failed to reset room progress', type: 'error' },
      ])
      setError('Failed to reset room. Is the API running?')
    } finally {
      setIsResetting(false)
    }
  }

  return (
    <>
      <button
        onClick={handleOpen}
        className="px-4 py-2 bg-gray-800 text-gray-300 rounded-lg hover:bg-gray-700 transition-colors text-sm"
      >
        Reset Room
      </button>

      {showPrompt && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
          {/* Backdrop */}
          <div className="absolute inset-0 bg-black/70" onClick={handleClose} />

          {/* Terminal */}
          <div className="relative w-full max-w-lg bg-gray-950 border border-gray-700 rounded-xl overflow-hidden shadow-2xl">
            {/* Title bar */}
            <div className="flex items-center justify-between px-4 py-2.5 bg-gray-900 border-b border-gray-800">
              <div className="flex items-center gap-2">
                <div className="flex gap-1.5">
                  <button
                    onClick={handleClose}
                    className="h-3 w-3 rounded-full bg-red-500 hover:bg-red-400 transition-colors"
                    aria-label="Close"
                  />
                  <div className="h-3 w-3 rounded-full bg-yellow-500" />
                  <div className="h-3 w-3 rounded-full bg-green-500" />
                </div>
                <span className="text-xs text-gray-500 font-mono ml-2">reset — {roomId}</span>
              </div>
            </div>

            {/* Terminal body */}
            <div ref={terminalRef} className="p-4 font-mono text-sm max-h-64 overflow-y-auto">
              {lines.map((line, i) => (
                <div key={i} className={`${lineColor(line.type)} ${line.text === '' ? 'h-4' : ''}`}>
                  {line.text}
                </div>
              ))}

              {/* Input line */}
              {!isResetting && !lines.some((l) => l.type === 'success') && (
                <form onSubmit={handleSubmit} className="flex items-center mt-1">
                  <span className="text-terminal-green mr-2">&gt;</span>
                  <input
                    ref={inputRef}
                    type="text"
                    value={input}
                    onChange={(e) => setInput(e.target.value)}
                    className="flex-1 bg-transparent text-white outline-none font-mono text-sm caret-terminal-green"
                    spellCheck={false}
                    autoComplete="off"
                    disabled={isResetting}
                  />
                  <span className="animate-pulse text-terminal-green">_</span>
                </form>
              )}

              {isResetting && (
                <div className="flex items-center gap-2 mt-1 text-gray-400">
                  <LoadingSpinner />
                  <span>processing...</span>
                </div>
              )}
            </div>

            {/* Footer */}
            {error && (
              <div className="px-4 py-2 bg-red-500/10 border-t border-red-500/30">
                <p className="text-xs text-red-400">{error}</p>
              </div>
            )}
          </div>
        </div>
      )}
    </>
  )
}

function lineColor(type: 'info' | 'warn' | 'error' | 'success' | 'prompt'): string {
  switch (type) {
    case 'warn': return 'text-yellow-400'
    case 'error': return 'text-red-400'
    case 'success': return 'text-terminal-green'
    case 'prompt': return 'text-k8s-blue'
    default: return 'text-gray-300'
  }
}

function LoadingSpinner() {
  return (
    <svg className="animate-spin h-3.5 w-3.5" fill="none" viewBox="0 0 24 24">
      <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
      <path
        className="opacity-75"
        fill="currentColor"
        d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
      />
    </svg>
  )
}

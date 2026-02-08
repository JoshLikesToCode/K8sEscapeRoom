'use client'

import { useState } from 'react'

export function ProofSubmit({ roomId, onSuccess }: { roomId: string; onSuccess?: () => void }) {
  const [token, setToken] = useState('')
  const [status, setStatus] = useState<'idle' | 'loading' | 'success' | 'error'>('idle')
  const [errorMessage, setErrorMessage] = useState('')

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()

    if (!token.trim()) {
      setErrorMessage('Please enter a proof token')
      setStatus('error')
      return
    }

    setStatus('loading')
    setErrorMessage('')

    // Simulate API call (no real API yet)
    await new Promise((resolve) => setTimeout(resolve, 1500))

    // For now, just show success for demo purposes
    // In real implementation, this would validate with the API
    if (token.startsWith('eyJ')) {
      setStatus('success')
      onSuccess?.()
    } else {
      setStatus('error')
      setErrorMessage('Invalid proof token. Make sure you copied the entire token from the CLI.')
    }
  }

  if (status === 'success') {
    return (
      <div className="bg-terminal-green/10 border border-terminal-green/30 rounded-xl p-6 text-center">
        <div className="h-12 w-12 rounded-full bg-terminal-green/20 flex items-center justify-center mx-auto mb-4">
          <CheckIcon className="h-6 w-6 text-terminal-green" />
        </div>
        <h3 className="text-lg font-semibold text-terminal-green mb-2">Room Escaped!</h3>
        <p className="text-sm text-gray-400">
          Congratulations! Your progress has been saved.
        </p>
      </div>
    )
  }

  return (
    <div className="bg-gray-900 border border-gray-800 rounded-xl overflow-hidden">
      <div className="px-4 py-3 border-b border-gray-800 flex items-center gap-2">
        <KeyIcon className="h-4 w-4 text-k8s-blue" />
        <h3 className="text-sm font-semibold text-white">Submit Proof Token</h3>
      </div>
      <form onSubmit={handleSubmit} className="p-4 space-y-4">
        <div>
          <p className="text-sm text-gray-400 mb-3">
            After fixing the room, run the verify command and paste the proof token below:
          </p>
          <div className="bg-gray-800 rounded-lg p-3 mb-3">
            <code className="text-sm text-terminal-green font-mono">
              $ make room-verify ROOM={roomId}
            </code>
          </div>
        </div>

        <div>
          <label htmlFor="proof-token" className="block text-xs text-gray-500 mb-2">
            Proof Token
          </label>
          <textarea
            id="proof-token"
            value={token}
            onChange={(e) => setToken(e.target.value)}
            placeholder="eyJhbGciOiJIUzI1NiIs..."
            className={`
              w-full h-24 px-3 py-2 bg-gray-800 border rounded-lg text-sm font-mono
              placeholder-gray-600 focus:outline-none focus:ring-2 transition-colors resize-none
              ${status === 'error'
                ? 'border-red-500/50 focus:ring-red-500/30 text-red-400'
                : 'border-gray-700 focus:ring-k8s-blue/30 text-white'
              }
            `}
          />
          {status === 'error' && errorMessage && (
            <p className="mt-2 text-xs text-red-400">{errorMessage}</p>
          )}
        </div>

        <button
          type="submit"
          disabled={status === 'loading'}
          className={`
            w-full py-2.5 px-4 rounded-lg font-medium text-sm transition-all
            ${status === 'loading'
              ? 'bg-gray-700 text-gray-400 cursor-not-allowed'
              : 'bg-k8s-blue hover:bg-k8s-blue/80 text-white'
            }
          `}
        >
          {status === 'loading' ? (
            <span className="flex items-center justify-center gap-2">
              <LoadingSpinner />
              Verifying...
            </span>
          ) : (
            'Verify & Submit'
          )}
        </button>
      </form>
    </div>
  )
}

function KeyIcon({ className }: { className?: string }) {
  return (
    <svg className={className} fill="none" viewBox="0 0 24 24" strokeWidth={1.5} stroke="currentColor">
      <path
        strokeLinecap="round"
        strokeLinejoin="round"
        d="M15.75 5.25a3 3 0 013 3m3 0a6 6 0 01-7.029 5.912c-.563-.097-1.159.026-1.563.43L10.5 17.25H8.25v2.25H6v2.25H2.25v-2.818c0-.597.237-1.17.659-1.591l6.499-6.499c.404-.404.527-1 .43-1.563A6 6 0 1121.75 8.25z"
      />
    </svg>
  )
}

function CheckIcon({ className }: { className?: string }) {
  return (
    <svg className={className} fill="none" viewBox="0 0 24 24" strokeWidth={2} stroke="currentColor">
      <path strokeLinecap="round" strokeLinejoin="round" d="M4.5 12.75l6 6 9-13.5" />
    </svg>
  )
}

function LoadingSpinner() {
  return (
    <svg className="animate-spin h-4 w-4" fill="none" viewBox="0 0 24 24">
      <circle
        className="opacity-25"
        cx="12"
        cy="12"
        r="10"
        stroke="currentColor"
        strokeWidth="4"
      />
      <path
        className="opacity-75"
        fill="currentColor"
        d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
      />
    </svg>
  )
}

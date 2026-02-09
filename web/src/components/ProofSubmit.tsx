'use client'

import { useState } from 'react'
import { useAuth, useProgress } from '@/lib/auth'
import { startAttempt, submitProof, ApiError, AttemptResponse } from '@/lib/api'

// Dev mode flag for direct completion (bypass proof verification)
const DEV_COMPLETE_ENABLED = process.env.NEXT_PUBLIC_DEV_COMPLETE === '1'

interface ProofSubmitProps {
  roomId: string
  onSuccess?: () => void
}

type FlowState =
  | { step: 'idle' }
  | { step: 'starting' }
  | { step: 'attempt'; nonce: string; expiresAt: Date }
  | { step: 'submitting' }
  | { step: 'success' }
  | { step: 'error'; message: string }

export function ProofSubmit({ roomId, onSuccess }: ProofSubmitProps) {
  const { isAuthenticated } = useAuth()
  const { isRoomCompleted, markRoomComplete, refresh: refreshProgress } = useProgress()
  const [flowState, setFlowState] = useState<FlowState>({ step: 'idle' })
  const [token, setToken] = useState('')
  // Preserve nonce and expiry across error states
  const [currentAttempt, setCurrentAttempt] = useState<{ nonce: string; expiresAt: Date } | null>(null)

  const isCompleted = isRoomCompleted(roomId)

  // Start a new attempt
  const handleStartAttempt = async () => {
    setFlowState({ step: 'starting' })

    try {
      const response = await startAttempt(roomId)
      const attempt = {
        nonce: response.nonce,
        expiresAt: new Date(response.expiresAtUtc),
      }
      setCurrentAttempt(attempt)
      setFlowState({ step: 'attempt', ...attempt })
    } catch (err) {
      const message = err instanceof ApiError ? err.message : 'Failed to start attempt'
      setFlowState({ step: 'error', message })
    }
  }

  // Submit proof token
  const handleSubmitProof = async (e: React.FormEvent) => {
    e.preventDefault()

    if (!token.trim()) {
      setFlowState({ step: 'error', message: 'Please paste your proof token' })
      return
    }

    setFlowState({ step: 'submitting' })

    try {
      await submitProof(roomId, token.trim())
      await refreshProgress()
      setFlowState({ step: 'success' })
      onSuccess?.()
    } catch (err) {
      const message = err instanceof ApiError ? err.message : 'Failed to submit proof'
      setFlowState({ step: 'error', message })
    }
  }

  // Dev-only direct completion (hidden behind flag)
  const handleDevComplete = async () => {
    setFlowState({ step: 'submitting' })
    try {
      await markRoomComplete(roomId)
      await refreshProgress()
      setFlowState({ step: 'success' })
      onSuccess?.()
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Failed to mark complete'
      setFlowState({ step: 'error', message })
    }
  }

  // Show completed state
  if (isCompleted || flowState.step === 'success') {
    return (
      <div className="bg-terminal-green/10 border border-terminal-green/30 rounded-xl p-6 text-center">
        <div className="h-12 w-12 rounded-full bg-terminal-green/20 flex items-center justify-center mx-auto mb-4">
          <CheckIcon className="h-6 w-6 text-terminal-green" />
        </div>
        <h3 className="text-lg font-semibold text-terminal-green mb-2">Room Escaped!</h3>
        <p className="text-sm text-gray-400">
          {flowState.step === 'success'
            ? 'Congratulations! Your progress has been saved.'
            : 'You have already completed this room.'}
        </p>
      </div>
    )
  }

  // Show login prompt if not authenticated
  if (!isAuthenticated) {
    return (
      <div className="bg-gray-900 border border-gray-800 rounded-xl overflow-hidden">
        <div className="px-4 py-3 border-b border-gray-800 flex items-center gap-2">
          <KeyIcon className="h-4 w-4 text-gray-500" />
          <h3 className="text-sm font-semibold text-gray-400">Submit Proof</h3>
        </div>
        <div className="p-4 text-center">
          <p className="text-sm text-gray-500 mb-4">
            Login to submit proof and track your progress.
          </p>
          <a
            href="/.auth/login/github"
            className="inline-flex items-center gap-2 px-4 py-2 rounded-lg bg-gray-800 hover:bg-gray-700 text-white text-sm font-medium transition-colors"
          >
            <GitHubIcon className="h-4 w-4" />
            Login with GitHub
          </a>
        </div>
      </div>
    )
  }

  // Idle state: show "Start Attempt" button
  if (flowState.step === 'idle' || flowState.step === 'starting') {
    return (
      <div className="bg-gray-900 border border-gray-800 rounded-xl overflow-hidden">
        <div className="px-4 py-3 border-b border-gray-800 flex items-center gap-2">
          <KeyIcon className="h-4 w-4 text-k8s-blue" />
          <h3 className="text-sm font-semibold text-white">Submit Proof</h3>
        </div>
        <div className="p-4 space-y-4">
          <p className="text-sm text-gray-400">
            After fixing all issues in the room, start an attempt to get a unique nonce for proof generation.
          </p>

          <button
            type="button"
            onClick={handleStartAttempt}
            disabled={flowState.step === 'starting'}
            className={`
              w-full py-2.5 px-4 rounded-lg font-medium text-sm transition-all
              ${flowState.step === 'starting'
                ? 'bg-gray-700 text-gray-400 cursor-not-allowed'
                : 'bg-k8s-blue hover:bg-k8s-blue/80 text-white'
              }
            `}
          >
            {flowState.step === 'starting' ? (
              <span className="flex items-center justify-center gap-2">
                <LoadingSpinner />
                Starting...
              </span>
            ) : (
              'Start Attempt'
            )}
          </button>

          {/* Dev-only direct complete */}
          {DEV_COMPLETE_ENABLED && (
            <div className="pt-2 border-t border-gray-800">
              <p className="text-xs text-gray-600 mb-2 text-center">Development mode</p>
              <button
                type="button"
                onClick={handleDevComplete}
                className="w-full py-2 px-4 rounded-lg text-sm font-medium bg-purple-600/20 hover:bg-purple-600/30 text-purple-400 border border-purple-500/30 transition-colors"
              >
                Mark Complete (Dev)
              </button>
            </div>
          )}
        </div>
      </div>
    )
  }

  // Attempt state: show nonce and token input
  if (flowState.step === 'attempt' || flowState.step === 'submitting' || (flowState.step === 'error' && currentAttempt)) {
    const nonce = currentAttempt?.nonce ?? ''
    const expiresAt = currentAttempt?.expiresAt

    return (
      <div className="bg-gray-900 border border-gray-800 rounded-xl overflow-hidden">
        <div className="px-4 py-3 border-b border-gray-800 flex items-center gap-2">
          <KeyIcon className="h-4 w-4 text-k8s-blue" />
          <h3 className="text-sm font-semibold text-white">Submit Proof Token</h3>
        </div>
        <div className="p-4 space-y-4">
          {/* Nonce display */}
          {nonce && (
            <div className="space-y-2">
              <p className="text-sm text-gray-400">
                Run this command after fixing the room:
              </p>
              <div className="bg-gray-800 rounded-lg p-3 font-mono text-sm">
                <code className="text-terminal-green break-all">
                  escape room proof {roomId} --nonce {nonce}
                </code>
              </div>
              {expiresAt && (
                <p className="text-xs text-gray-500">
                  Expires: {expiresAt.toLocaleTimeString()}
                </p>
              )}
            </div>
          )}

          {/* Error display */}
          {flowState.step === 'error' && (
            <div className="p-3 bg-red-500/10 border border-red-500/30 rounded-lg">
              <p className="text-xs text-red-400">{flowState.message}</p>
            </div>
          )}

          {/* Token input form */}
          <form onSubmit={handleSubmitProof} className="space-y-3">
            <div>
              <label htmlFor="proof-token" className="block text-xs text-gray-500 mb-2">
                Paste your proof token
              </label>
              <textarea
                id="proof-token"
                value={token}
                onChange={(e) => setToken(e.target.value)}
                placeholder="K8SER|room-...|..."
                className="w-full h-20 px-3 py-2 bg-gray-800 border border-gray-700 rounded-lg text-sm font-mono placeholder-gray-600 focus:outline-none focus:ring-2 focus:ring-k8s-blue/30 text-white resize-none"
              />
            </div>

            <div className="flex gap-2">
              <button
                type="button"
                onClick={() => {
                  setFlowState({ step: 'idle' })
                  setCurrentAttempt(null)
                  setToken('')
                }}
                className="px-4 py-2 rounded-lg text-sm font-medium text-gray-400 hover:text-white transition-colors"
              >
                Cancel
              </button>
              <button
                type="submit"
                disabled={flowState.step === 'submitting'}
                className={`
                  flex-1 py-2 px-4 rounded-lg font-medium text-sm transition-all
                  ${flowState.step === 'submitting'
                    ? 'bg-gray-700 text-gray-400 cursor-not-allowed'
                    : 'bg-terminal-green hover:bg-terminal-green/80 text-black'
                  }
                `}
              >
                {flowState.step === 'submitting' ? (
                  <span className="flex items-center justify-center gap-2">
                    <LoadingSpinner />
                    Verifying...
                  </span>
                ) : (
                  'Submit Proof'
                )}
              </button>
            </div>
          </form>
        </div>
      </div>
    )
  }

  return null
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

function GitHubIcon({ className }: { className?: string }) {
  return (
    <svg className={className} fill="currentColor" viewBox="0 0 24 24">
      <path
        fillRule="evenodd"
        d="M12 2C6.477 2 2 6.484 2 12.017c0 4.425 2.865 8.18 6.839 9.504.5.092.682-.217.682-.483 0-.237-.008-.868-.013-1.703-2.782.605-3.369-1.343-3.369-1.343-.454-1.158-1.11-1.466-1.11-1.466-.908-.62.069-.608.069-.608 1.003.07 1.531 1.032 1.531 1.032.892 1.53 2.341 1.088 2.91.832.092-.647.35-1.088.636-1.338-2.22-.253-4.555-1.113-4.555-4.951 0-1.093.39-1.988 1.029-2.688-.103-.253-.446-1.272.098-2.65 0 0 .84-.27 2.75 1.026A9.564 9.564 0 0112 6.844c.85.004 1.705.115 2.504.337 1.909-1.296 2.747-1.027 2.747-1.027.546 1.379.202 2.398.1 2.651.64.7 1.028 1.595 1.028 2.688 0 3.848-2.339 4.695-4.566 4.943.359.309.678.92.678 1.855 0 1.338-.012 2.419-.012 2.747 0 .268.18.58.688.482A10.019 10.019 0 0022 12.017C22 6.484 17.522 2 12 2z"
        clipRule="evenodd"
      />
    </svg>
  )
}

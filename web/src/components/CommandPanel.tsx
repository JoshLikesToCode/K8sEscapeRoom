'use client'

import { useState } from 'react'

export interface Command {
  label: string
  command: string
  description?: string
}

export function CommandPanel({ commands }: { commands: Command[] }) {
  return (
    <div className="bg-gray-900 border border-gray-800 rounded-xl overflow-hidden">
      <div className="px-4 py-3 border-b border-gray-800 flex items-center gap-2">
        <TerminalIcon className="h-4 w-4 text-terminal-green" />
        <h3 className="text-sm font-semibold text-white">Useful Commands</h3>
      </div>
      <div className="divide-y divide-gray-800">
        {commands.map((cmd, index) => (
          <CommandRow key={index} command={cmd} />
        ))}
      </div>
    </div>
  )
}

function CommandRow({ command }: { command: Command }) {
  const [copied, setCopied] = useState(false)

  const handleCopy = async () => {
    try {
      await navigator.clipboard.writeText(command.command)
      setCopied(true)
      setTimeout(() => setCopied(false), 2000)
    } catch (err) {
      console.error('Failed to copy:', err)
    }
  }

  return (
    <div className="p-4 hover:bg-gray-800/50 transition-colors group">
      <div className="flex items-start justify-between gap-4">
        <div className="flex-1 min-w-0">
          <p className="text-xs text-gray-500 mb-1">{command.label}</p>
          <code className="block text-sm text-terminal-green font-mono break-all">
            $ {command.command}
          </code>
          {command.description && (
            <p className="text-xs text-gray-500 mt-2">{command.description}</p>
          )}
        </div>
        <button
          onClick={handleCopy}
          className={`
            flex-shrink-0 p-2 rounded-lg transition-all
            ${copied
              ? 'bg-terminal-green/20 text-terminal-green'
              : 'bg-gray-800 text-gray-400 hover:text-white hover:bg-gray-700'
            }
          `}
          title={copied ? 'Copied!' : 'Copy to clipboard'}
        >
          {copied ? (
            <CheckIcon className="h-4 w-4" />
          ) : (
            <CopyIcon className="h-4 w-4" />
          )}
        </button>
      </div>
    </div>
  )
}

export function SingleCommand({ command, label }: { command: string; label?: string }) {
  const [copied, setCopied] = useState(false)

  const handleCopy = async () => {
    try {
      await navigator.clipboard.writeText(command)
      setCopied(true)
      setTimeout(() => setCopied(false), 2000)
    } catch (err) {
      console.error('Failed to copy:', err)
    }
  }

  return (
    <div className="bg-gray-900 border border-gray-800 rounded-lg p-3 group">
      {label && <p className="text-xs text-gray-500 mb-2">{label}</p>}
      <div className="flex items-center justify-between gap-3">
        <code className="text-sm text-terminal-green font-mono flex-1 break-all">
          $ {command}
        </code>
        <button
          onClick={handleCopy}
          className={`
            flex-shrink-0 p-1.5 rounded transition-all
            ${copied
              ? 'bg-terminal-green/20 text-terminal-green'
              : 'text-gray-500 hover:text-white hover:bg-gray-800'
            }
          `}
          title={copied ? 'Copied!' : 'Copy to clipboard'}
        >
          {copied ? (
            <CheckIcon className="h-3.5 w-3.5" />
          ) : (
            <CopyIcon className="h-3.5 w-3.5" />
          )}
        </button>
      </div>
    </div>
  )
}

function TerminalIcon({ className }: { className?: string }) {
  return (
    <svg className={className} fill="none" viewBox="0 0 24 24" strokeWidth={1.5} stroke="currentColor">
      <path strokeLinecap="round" strokeLinejoin="round" d="M6.75 7.5l3 2.25-3 2.25m4.5 0h3m-9 8.25h13.5A2.25 2.25 0 0021 18V6a2.25 2.25 0 00-2.25-2.25H5.25A2.25 2.25 0 003 6v12a2.25 2.25 0 002.25 2.25z" />
    </svg>
  )
}

function CopyIcon({ className }: { className?: string }) {
  return (
    <svg className={className} fill="none" viewBox="0 0 24 24" strokeWidth={1.5} stroke="currentColor">
      <path strokeLinecap="round" strokeLinejoin="round" d="M15.666 3.888A2.25 2.25 0 0013.5 2.25h-3c-1.03 0-1.9.693-2.166 1.638m7.332 0c.055.194.084.4.084.612v0a.75.75 0 01-.75.75H9a.75.75 0 01-.75-.75v0c0-.212.03-.418.084-.612m7.332 0c.646.049 1.288.11 1.927.184 1.1.128 1.907 1.077 1.907 2.185V19.5a2.25 2.25 0 01-2.25 2.25H6.75A2.25 2.25 0 014.5 19.5V6.257c0-1.108.806-2.057 1.907-2.185a48.208 48.208 0 011.927-.184" />
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

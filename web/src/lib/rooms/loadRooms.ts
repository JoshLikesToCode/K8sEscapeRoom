/**
 * Server-side room loader
 *
 * Scans the /rooms directory and parses room metadata from app.yaml and markdown files.
 * This module runs only on the server (RSC / build time).
 */

import { cache } from 'react'
import * as fs from 'fs'
import * as path from 'path'
import * as yaml from 'yaml'
import type { Room, RoomMetadata, Difficulty } from './types'

/**
 * Resolve the path to the rooms directory.
 * Works whether cwd is /web or repo root.
 */
function getRoomsDir(): string {
  const cwd = process.cwd()

  // If we're in the web directory, go up one level
  if (cwd.endsWith('/web') || cwd.endsWith('\\web')) {
    return path.resolve(cwd, '..', 'rooms')
  }

  // If cwd contains /web/ somewhere, we might be in a subdirectory
  const webIndex = cwd.indexOf('/web')
  if (webIndex !== -1) {
    const repoRoot = cwd.substring(0, webIndex)
    return path.resolve(repoRoot, 'rooms')
  }

  // Assume we're at repo root
  return path.resolve(cwd, 'rooms')
}

/**
 * Read a file if it exists, otherwise return null
 */
function readFileIfExists(filePath: string): string | null {
  try {
    return fs.readFileSync(filePath, 'utf-8')
  } catch {
    return null
  }
}

/**
 * Parse app.yaml to extract metadata labels and annotations.
 * Handles multi-document YAML files.
 */
function parseAppYaml(yamlContent: string): RoomMetadata {
  const defaultMetadata: RoomMetadata = {
    difficulty: 'unknown',
    failureMode: 'unknown',
    description: '',
  }

  try {
    // Parse all documents in the YAML file
    const docs = yaml.parseAllDocuments(yamlContent)

    for (const doc of docs) {
      if (!doc.contents) continue

      const obj = doc.toJSON()
      if (!obj || typeof obj !== 'object') continue

      const metadata = obj.metadata
      if (!metadata) continue

      // Check for labels
      const labels = metadata.labels || {}
      const annotations = metadata.annotations || {}

      const difficulty = labels['k8sescaperoom.dev/difficulty']
      const failureMode = labels['k8sescaperoom.dev/failure-mode']
      const description = annotations['k8sescaperoom.dev/description']

      // Return if we found the relevant labels
      if (difficulty || failureMode || description) {
        return {
          difficulty: validateDifficulty(difficulty),
          failureMode: failureMode || 'unknown',
          description: description || '',
        }
      }
    }
  } catch (err) {
    console.warn('Failed to parse app.yaml:', err)
  }

  return defaultMetadata
}

/**
 * Validate and normalize difficulty value
 */
function validateDifficulty(value: string | undefined): Difficulty {
  if (!value) return 'unknown'
  const normalized = value.toLowerCase()
  if (normalized === 'beginner' || normalized === 'intermediate' || normalized === 'advanced') {
    return normalized
  }
  return 'unknown'
}

/**
 * Convert folder name to human-friendly title
 * e.g., "room-crashloop-env" -> "Crashloop Env"
 * e.g., "boss-checkout-meltdown" -> "Checkout Meltdown"
 */
function folderToTitle(folderId: string): string {
  // Remove room- or boss- prefix
  let name = folderId.replace(/^(room-|boss-)/, '')

  // Convert hyphens to spaces and capitalize each word
  return name
    .split('-')
    .map((word) => word.charAt(0).toUpperCase() + word.slice(1))
    .join(' ')
}

/**
 * Load a single room from its directory
 */
function loadRoom(roomsDir: string, folderId: string): Room | null {
  const roomDir = path.join(roomsDir, folderId)

  // Check if it's a directory
  try {
    const stat = fs.statSync(roomDir)
    if (!stat.isDirectory()) return null
  } catch {
    return null
  }

  const warnings: string[] = []

  // Read app.yaml
  const appYamlPath = path.join(roomDir, 'app.yaml')
  const appYamlContent = readFileIfExists(appYamlPath)

  let metadata: RoomMetadata = {
    difficulty: 'unknown',
    failureMode: 'unknown',
    description: '',
  }

  if (appYamlContent) {
    metadata = parseAppYaml(appYamlContent)
  } else {
    warnings.push('app.yaml not found')
  }

  // Read objective markdown (prefer OBJECTIVE.md, fallback to INCIDENT.md)
  let objectiveMarkdown = readFileIfExists(path.join(roomDir, 'OBJECTIVE.md'))
  if (!objectiveMarkdown) {
    objectiveMarkdown = readFileIfExists(path.join(roomDir, 'INCIDENT.md'))
  }
  if (!objectiveMarkdown) {
    objectiveMarkdown = ''
    warnings.push('No OBJECTIVE.md or INCIDENT.md found - see docs/RoomContract.md')
  }

  // Read hints markdown
  const hintsMarkdown = readFileIfExists(path.join(roomDir, 'HINTS.md')) || ''
  if (!hintsMarkdown) {
    warnings.push('HINTS.md not found')
  }

  // Read solution markdown
  const solutionMarkdown = readFileIfExists(path.join(roomDir, 'SOLUTION.md')) || ''
  if (!solutionMarkdown) {
    warnings.push('SOLUTION.md not found')
  }

  const isBoss = folderId.startsWith('boss-')

  // Generate title from description or folder name
  const title = metadata.description
    ? metadata.description.split('.')[0] // Use first sentence of description
    : folderToTitle(folderId)

  // Log warnings to server console
  if (warnings.length > 0) {
    console.warn(`[Room ${folderId}] Warnings:`, warnings)
  }

  return {
    id: folderId,
    title,
    description: metadata.description || `Debug a ${metadata.failureMode} failure`,
    difficulty: metadata.difficulty,
    failureMode: metadata.failureMode,
    isBoss,
    namespace: `escape-${folderId}`,
    objectiveMarkdown,
    hintsMarkdown,
    solutionMarkdown,
    warnings,
  }
}

/**
 * Load all rooms from the /rooms directory.
 * Cached using React's cache() to avoid re-scanning on every request.
 */
export const loadAllRooms = cache(async (): Promise<Room[]> => {
  const roomsDir = getRoomsDir()

  // Log for debugging
  console.log(`[loadAllRooms] Scanning rooms directory: ${roomsDir}`)

  let entries: string[]
  try {
    entries = fs.readdirSync(roomsDir)
  } catch (err) {
    console.error(`[loadAllRooms] Failed to read rooms directory:`, err)
    return []
  }

  // Filter to room- and boss- prefixed folders
  const roomFolders = entries.filter(
    (name) => name.startsWith('room-') || name.startsWith('boss-')
  )

  console.log(`[loadAllRooms] Found ${roomFolders.length} room folders`)

  // Load each room
  const rooms: Room[] = []
  for (const folder of roomFolders) {
    const room = loadRoom(roomsDir, folder)
    if (room) {
      rooms.push(room)
    }
  }

  // Difficulty sort order: beginner first, then intermediate, then advanced, then unknown
  const difficultyOrder: Record<string, number> = {
    beginner: 0,
    intermediate: 1,
    advanced: 2,
    unknown: 3,
  }

  // Sort: regular rooms first (by difficulty, then alphabetically), then boss rooms (alphabetically)
  rooms.sort((a, b) => {
    // Boss rooms always come after regular rooms
    if (a.isBoss !== b.isBoss) {
      return a.isBoss ? 1 : -1
    }
    // For regular rooms, sort by difficulty first
    if (!a.isBoss && !b.isBoss) {
      const diffA = difficultyOrder[a.difficulty] ?? 3
      const diffB = difficultyOrder[b.difficulty] ?? 3
      if (diffA !== diffB) {
        return diffA - diffB
      }
    }
    // Then sort alphabetically within the same difficulty/boss group
    return a.id.localeCompare(b.id)
  })

  return rooms
})

/**
 * Load a single room by ID.
 * Uses the cached loadAllRooms under the hood.
 */
export const loadRoomById = cache(async (id: string): Promise<Room | null> => {
  const rooms = await loadAllRooms()
  return rooms.find((room) => room.id === id) || null
})

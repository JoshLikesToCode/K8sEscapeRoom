/**
 * Pure data-transformation functions for room parsing.
 * No fs, path, or cache dependencies - usable in both build scripts and runtime.
 */

import * as yaml from 'yaml'
import type { Room, RoomMetadata, Difficulty } from './types'

export interface RawRoomFiles {
  folderId: string
  appYaml: string | null
  objectiveMarkdown: string | null
  hintsMarkdown: string | null
  solutionMarkdown: string | null
}

/**
 * Validate and normalize difficulty value
 */
export function validateDifficulty(value: string | undefined): Difficulty {
  if (!value) return 'unknown'
  const normalized = value.toLowerCase()
  if (normalized === 'beginner' || normalized === 'intermediate' || normalized === 'advanced') {
    return normalized
  }
  return 'unknown'
}

/**
 * Parse app.yaml to extract metadata labels and annotations.
 * Handles multi-document YAML files.
 */
export function parseAppYaml(yamlContent: string): RoomMetadata {
  const defaultMetadata: RoomMetadata = {
    difficulty: 'unknown',
    failureMode: 'unknown',
    description: '',
  }

  try {
    const docs = yaml.parseAllDocuments(yamlContent)

    for (const doc of docs) {
      if (!doc.contents) continue

      const obj = doc.toJSON()
      if (!obj || typeof obj !== 'object') continue

      const metadata = obj.metadata
      if (!metadata) continue

      const labels = metadata.labels || {}
      const annotations = metadata.annotations || {}

      const difficulty = labels['k8sescaperoom.dev/difficulty']
      const failureMode = labels['k8sescaperoom.dev/failure-mode']
      const description = annotations['k8sescaperoom.dev/description']

      if (difficulty || failureMode || description) {
        return {
          difficulty: validateDifficulty(difficulty),
          failureMode: failureMode || 'unknown',
          description: description || '',
        }
      }
    }
  } catch (err) {
    console.warn('[rooms] Failed to parse app.yaml:', err)
  }

  return defaultMetadata
}

/**
 * Convert folder name to human-friendly title
 * e.g., "room-groundhog-deploy" -> "Groundhog Deploy"
 * e.g., "boss-checkout-meltdown" -> "Checkout Meltdown"
 */
export function folderToTitle(folderId: string): string {
  let name = folderId.replace(/^(room-|boss-)/, '')

  return name
    .split('-')
    .map((word) => word.charAt(0).toUpperCase() + word.slice(1))
    .join(' ')
}

/**
 * Assemble a Room object from raw file contents.
 */
export function assembleRoom(raw: RawRoomFiles): Room {
  const { folderId, appYaml, objectiveMarkdown, hintsMarkdown, solutionMarkdown } = raw
  const warnings: string[] = []

  let metadata: RoomMetadata = {
    difficulty: 'unknown',
    failureMode: 'unknown',
    description: '',
  }

  if (appYaml) {
    metadata = parseAppYaml(appYaml)
  } else {
    warnings.push('app.yaml not found')
  }

  if (!objectiveMarkdown) {
    warnings.push('No OBJECTIVE.md or INCIDENT.md found - see docs/RoomContract.md')
  }
  if (!hintsMarkdown) {
    warnings.push('HINTS.md not found')
  }
  if (!solutionMarkdown) {
    warnings.push('SOLUTION.md not found')
  }

  const isBoss = folderId.startsWith('boss-')

  const descriptionParts = metadata.description?.split('.') || []
  const title =
    descriptionParts.length > 1 ? descriptionParts[0] : folderToTitle(folderId)
  const description =
    descriptionParts.length > 1
      ? descriptionParts.slice(1).join('.').trim()
      : metadata.description || `Debug a ${metadata.failureMode} failure`

  if (warnings.length > 0) {
    console.warn(`[rooms] Room ${folderId}:`, warnings)
  }

  return {
    id: folderId,
    title,
    description,
    difficulty: metadata.difficulty,
    failureMode: metadata.failureMode,
    isBoss,
    namespace: `escape-${folderId}`,
    objectiveMarkdown: objectiveMarkdown || '',
    hintsMarkdown: hintsMarkdown || '',
    solutionMarkdown: solutionMarkdown || '',
    warnings,
  }
}

/**
 * Sort rooms: regular rooms first (by difficulty, then alphabetically), then boss rooms.
 */
export function sortRooms(rooms: Room[]): Room[] {
  const difficultyOrder: Record<string, number> = {
    beginner: 0,
    intermediate: 1,
    advanced: 2,
    unknown: 3,
  }

  return [...rooms].sort((a, b) => {
    if (a.isBoss !== b.isBoss) {
      return a.isBoss ? 1 : -1
    }
    if (!a.isBoss && !b.isBoss) {
      const diffA = difficultyOrder[a.difficulty] ?? 3
      const diffB = difficultyOrder[b.difficulty] ?? 3
      if (diffA !== diffB) {
        return diffA - diffB
      }
    }
    return a.id.localeCompare(b.id)
  })
}

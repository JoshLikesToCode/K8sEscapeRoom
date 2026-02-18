/**
 * Room types for K8sEscapeRoom
 */

export type Difficulty = 'beginner' | 'intermediate' | 'advanced' | 'unknown'

export interface Room {
  /** Folder name (e.g., "room-groundhog-deploy") */
  id: string

  /** Human-friendly title derived from description or folder name */
  title: string

  /** Short description from k8sescaperoom.dev/description annotation */
  description: string

  /** Difficulty level from k8sescaperoom.dev/difficulty label */
  difficulty: Difficulty

  /** Failure mode from k8sescaperoom.dev/failure-mode label */
  failureMode: string

  /** Whether this is a boss room (folder starts with "boss-") */
  isBoss: boolean

  /** Namespace for the room (escape-{id}) */
  namespace: string

  /** Objective/Incident markdown content */
  objectiveMarkdown: string

  /** Hints markdown content */
  hintsMarkdown: string

  /** Solution markdown content */
  solutionMarkdown: string

  /** Warning if expected files are missing */
  warnings: string[]
}

/**
 * Parsed metadata from app.yaml
 */
export interface RoomMetadata {
  difficulty: Difficulty
  failureMode: string
  description: string
}

/**
 * Prebuild script: generates web/src/generated/rooms.json
 *
 * Reads room directories from the repo's rooms/ folder and produces a static
 * JSON file so the deployed web app has no filesystem dependency on rooms/.
 *
 * Usage: npx tsx scripts/generate-rooms.ts
 */

import * as fs from 'fs'
import * as path from 'path'
import { assembleRoom, sortRooms } from '../src/lib/rooms/roomParsing'
import type { RawRoomFiles } from '../src/lib/rooms/roomParsing'

const SCRIPT_DIR = path.dirname(new URL(import.meta.url).pathname)
const ROOMS_DIR = path.resolve(SCRIPT_DIR, '../../rooms')
const OUTPUT_DIR = path.resolve(SCRIPT_DIR, '../src/generated')
const OUTPUT_FILE = path.join(OUTPUT_DIR, 'rooms.json')

function readFileIfExists(filePath: string): string | null {
  try {
    return fs.readFileSync(filePath, 'utf-8')
  } catch {
    return null
  }
}

function main() {
  console.log(`[generate-rooms] Scanning: ${ROOMS_DIR}`)

  if (!fs.existsSync(ROOMS_DIR)) {
    console.error(`[generate-rooms] rooms/ directory not found at ${ROOMS_DIR}`)
    process.exit(1)
  }

  const entries = fs.readdirSync(ROOMS_DIR)
  const roomFolders = entries.filter(
    (name) => name.startsWith('room-') || name.startsWith('boss-') || name.startsWith('final-')
  )

  console.log(`[generate-rooms] Found ${roomFolders.length} room folders`)

  const rooms = roomFolders
    .map((folderId) => {
      const roomDir = path.join(ROOMS_DIR, folderId)

      try {
        if (!fs.statSync(roomDir).isDirectory()) return null
      } catch {
        return null
      }

      let objectiveMarkdown = readFileIfExists(path.join(roomDir, 'OBJECTIVE.md'))
      if (!objectiveMarkdown) {
        objectiveMarkdown = readFileIfExists(path.join(roomDir, 'INCIDENT.md'))
      }

      const raw: RawRoomFiles = {
        folderId,
        appYaml: readFileIfExists(path.join(roomDir, 'app.yaml')),
        objectiveMarkdown,
        hintsMarkdown: readFileIfExists(path.join(roomDir, 'HINTS.md')),
        solutionMarkdown: readFileIfExists(path.join(roomDir, 'SOLUTION.md')),
      }

      return assembleRoom(raw)
    })
    .filter((room) => room !== null)

  if (rooms.length === 0) {
    console.error('[generate-rooms] No rooms found! Failing build.')
    process.exit(1)
  }

  const sorted = sortRooms(rooms)

  // Ensure output directory exists
  fs.mkdirSync(OUTPUT_DIR, { recursive: true })

  fs.writeFileSync(OUTPUT_FILE, JSON.stringify(sorted, null, 2) + '\n')
  console.log(`[generate-rooms] Wrote ${sorted.length} rooms to ${OUTPUT_FILE}`)
}

main()

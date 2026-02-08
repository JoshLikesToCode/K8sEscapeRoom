/**
 * Room Repository - Server-side room data access
 *
 * ARCHITECTURE NOTES:
 * ==================
 *
 * This module reads room data from the filesystem at BUILD TIME using Node.js fs.
 * It runs ONLY on the server side (React Server Components / RSC).
 *
 * Key constraints:
 * - Room data is read from `../../rooms/` relative to project root
 * - This code runs during `next build` and in RSC, never in the browser
 * - Room metadata is extracted from app.yaml labels and markdown files
 * - No runtime filesystem access from client components
 *
 * Data flow:
 * 1. At build time (or in RSC), we scan /rooms directory
 * 2. Parse app.yaml for metadata labels (difficulty, failure-mode, etc.)
 * 3. Parse OBJECTIVE.md / INCIDENT.md for descriptions
 * 4. Return typed room data to components
 *
 * File structure expected:
 * ```
 * rooms/
 * ├── room-crashloop-env/
 * │   ├── app.yaml          # Has k8sescaperoom.dev/* labels
 * │   ├── OBJECTIVE.md      # Room objective
 * │   ├── HINTS.md          # Progressive hints
 * │   └── SOLUTION.md       # Full solution
 * └── boss-checkout-meltdown/
 *     ├── app.yaml
 *     ├── INCIDENT.md       # Boss rooms use INCIDENT.md
 *     ├── HINTS.md
 *     └── SOLUTION.md
 * ```
 *
 * Usage in RSC:
 * ```tsx
 * // app/rooms/page.tsx (Server Component)
 * import { getAllRooms } from '@/lib/rooms'
 *
 * export default async function RoomsPage() {
 *   const rooms = await getAllRooms()
 *   return <RoomList rooms={rooms} />
 * }
 * ```
 *
 * DO NOT:
 * - Import this in client components ('use client')
 * - Use dynamic filesystem reads based on user input
 * - Expose filesystem paths to the client
 */

// Types will be defined here
export interface Room {
  id: string
  name: string
  type: 'room' | 'boss'
  difficulty: 'beginner' | 'intermediate' | 'advanced'
  failureMode: string
  summary: string
  // ... more fields TBD
}

// Placeholder - implementation coming
export async function getAllRooms(): Promise<Room[]> {
  // TODO: Implement filesystem read
  // - Use fs.readdir to scan rooms directory
  // - Parse app.yaml with yaml library
  // - Extract labels: k8sescaperoom.dev/*
  // - Read OBJECTIVE.md or INCIDENT.md for summary
  return []
}

export async function getRoomById(id: string): Promise<Room | null> {
  // TODO: Implement single room fetch
  return null
}

export async function getRoomHints(id: string): Promise<string | null> {
  // TODO: Read and parse HINTS.md
  return null
}

export async function getRoomSolution(id: string): Promise<string | null> {
  // TODO: Read SOLUTION.md
  return null
}

/**
 * Room Repository - Server-side room data access
 *
 * This module provides access to room data by reading from the filesystem.
 * It runs ONLY on the server side (React Server Components / build time).
 *
 * Usage:
 * ```tsx
 * // In a Server Component
 * import { getAllRooms, getRoomById } from '@/lib/rooms'
 *
 * export default async function RoomsPage() {
 *   const rooms = await getAllRooms()
 *   return <RoomList rooms={rooms} />
 * }
 * ```
 *
 * DO NOT import this in client components ('use client').
 */

export type { Room, Difficulty, RoomMetadata } from './types'
export { loadAllRooms, loadRoomById } from './loadRooms'

// Re-export with cleaner names for public API
import { loadAllRooms, loadRoomById } from './loadRooms'
import type { Room } from './types'

export async function getAllRooms(): Promise<Room[]> {
  return loadAllRooms()
}

export async function getRoomById(id: string): Promise<Room | null> {
  return loadRoomById(id)
}

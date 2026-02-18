/**
 * Server-side room loader
 *
 * Loads room data from the pre-generated rooms.json (built by scripts/generate-rooms.ts).
 * This module runs only on the server (RSC / build time).
 */

import { cache } from 'react'
import type { Room } from './types'
import roomsData from '@/generated/rooms.json'

/**
 * Load all rooms from the pre-generated JSON.
 * Cached using React's cache() to avoid re-parsing on every request.
 */
export const loadAllRooms = cache(async (): Promise<Room[]> => {
  return roomsData as Room[]
})

/**
 * Load a single room by ID.
 * Uses the cached loadAllRooms under the hood.
 */
export const loadRoomById = cache(async (id: string): Promise<Room | null> => {
  const rooms = await loadAllRooms()
  return rooms.find((room) => room.id === id) || null
})

/**
 * Centralized API client for K8s Escape Room API
 *
 * All API calls go through this module to ensure consistent
 * error handling and typed responses.
 */

/**
 * API error with status code for handling specific cases
 */
export class ApiError extends Error {
  constructor(
    message: string,
    public readonly status: number,
    public readonly body?: unknown
  ) {
    super(message)
    this.name = 'ApiError'
  }

  get isUnauthorized(): boolean {
    return this.status === 401
  }

  get isBadRequest(): boolean {
    return this.status === 400
  }

  get isServerError(): boolean {
    return this.status >= 500
  }
}

/**
 * Fetch JSON from the API with proper error handling
 *
 * @throws {ApiError} on non-2xx responses
 * @throws {Error} on network errors
 */
export async function apiFetchJson<T>(
  path: string,
  options: RequestInit = {}
): Promise<T> {
  const url = path.startsWith('/') ? path : `/${path}`

  const res = await fetch(url, {
    ...options,
    headers: {
      'Content-Type': 'application/json',
      ...options.headers,
    },
  })

  // Try to parse response body (might be empty or invalid JSON)
  let body: unknown
  try {
    const text = await res.text()
    body = text ? JSON.parse(text) : undefined
  } catch {
    body = undefined
  }

  if (!res.ok) {
    const message =
      (body && typeof body === 'object' && 'error' in body
        ? String((body as { error: unknown }).error)
        : null) ?? `API error: ${res.status} ${res.statusText}`

    throw new ApiError(message, res.status, body)
  }

  return body as T
}

/**
 * POST to API endpoint
 */
export async function apiPost<T>(
  path: string,
  data?: unknown
): Promise<T> {
  return apiFetchJson<T>(path, {
    method: 'POST',
    body: data ? JSON.stringify(data) : undefined,
  })
}

/**
 * GET from API endpoint
 */
export async function apiGet<T>(path: string): Promise<T> {
  return apiFetchJson<T>(path, { method: 'GET' })
}

// ============================================================================
// Room API Types and Functions
// ============================================================================

export interface AttemptResponse {
  roomId: string
  nonce: string
  expiresAtUtc: string
}

export interface SubmitResponse {
  ok: boolean
}

/**
 * Start a new completion attempt for a room.
 * Returns a nonce that must be used with the CLI proof command.
 */
export async function startAttempt(roomId: string): Promise<AttemptResponse> {
  return apiPost<AttemptResponse>(`/api/rooms/${roomId}/attempt`)
}

/**
 * Submit a proof token to complete a room.
 */
export async function submitProof(roomId: string, token: string): Promise<SubmitResponse> {
  return apiPost<SubmitResponse>(`/api/rooms/${roomId}/submit`, { token })
}

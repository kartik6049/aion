// Base URL of the AION API. Override with VITE_API_BASE_URL in .env files.
const API_BASE_URL = (
  import.meta.env?.VITE_API_BASE_URL || 'http://127.0.0.1:8000'
).replace(/\/+$/, '')

const REQUEST_TIMEOUT_MS = 30000

export class ApiError extends Error {
  constructor(message, { status = null, cause } = {}) {
    super(message)
    this.name = 'ApiError'
    this.status = status
    if (cause) this.cause = cause
  }
}

async function readErrorDetail(response) {
  try {
    const body = await response.json()
    if (typeof body?.detail === 'string') return body.detail
  } catch {
    // Body was not JSON; fall back to the status text below.
  }
  return response.statusText || 'Request failed'
}

/**
 * GET a JSON endpoint. Rejects with ApiError on network failure, timeout,
 * non-2xx status, or an unparsable body. `signal` lets callers cancel.
 */
async function fetchJson(endpoint, { signal } = {}) {
  const controller = new AbortController()
  let timedOut = false

  const timer = setTimeout(() => {
    timedOut = true
    controller.abort()
  }, REQUEST_TIMEOUT_MS)

  const onCallerAbort = () => controller.abort()
  if (signal) {
    if (signal.aborted) controller.abort()
    else signal.addEventListener('abort', onCallerAbort, { once: true })
  }

  try {
    const response = await fetch(`${API_BASE_URL}${endpoint}`, {
      signal: controller.signal,
    })

    if (!response.ok) {
      throw new ApiError(await readErrorDetail(response), {
        status: response.status,
      })
    }

    try {
      return await response.json()
    } catch (err) {
      throw new ApiError('The server returned an invalid response.', {
        status: response.status,
        cause: err,
      })
    }
  } catch (err) {
    if (err instanceof ApiError) throw err
    if (err?.name === 'AbortError') {
      if (timedOut) throw new ApiError('The request timed out.', { cause: err })
      throw err // cancelled by the caller; callers ignore this
    }
    throw new ApiError(
      'Unable to reach the AION API. Check that the backend is running.',
      { cause: err },
    )
  } finally {
    clearTimeout(timer)
    signal?.removeEventListener('abort', onCallerAbort)
  }
}

export const getPlan = (options) => fetchJson('/api/plan', options)
export const getSystem = (options) => fetchJson('/api/system', options)
export const getHealth = (options) => fetchJson('/api/health', options)
export const getZone = (zone, options) =>
  fetchJson(`/api/zone/${encodeURIComponent(zone)}`, options)

export const isAbortError = (err) => err?.name === 'AbortError'

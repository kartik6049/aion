import { useCallback, useEffect, useRef, useState } from 'react'
import { isAbortError } from '../services/api'

/**
 * Runs `load(signal)` on mount and whenever `deps` change. Only the latest
 * request may update state, so a slow earlier response can never overwrite a
 * newer one. `reload()` retries manually.
 */
export function useAsync(load, deps) {
  const [state, setState] = useState({ data: null, error: null, loading: true })
  const [attempt, setAttempt] = useState(0)
  const loadRef = useRef(load)

  useEffect(() => {
    loadRef.current = load
  })

  useEffect(() => {
    const controller = new AbortController()
    // Clear old data so a previous zone/response is never shown as current.
    setState({ data: null, error: null, loading: true })

    loadRef
      .current(controller.signal)
      .then((data) => {
        if (!controller.signal.aborted) {
          setState({ data, error: null, loading: false })
        }
      })
      .catch((err) => {
        if (controller.signal.aborted || isAbortError(err)) return
        setState({ data: null, error: err, loading: false })
      })

    return () => controller.abort()
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [...deps, attempt])

  const reload = useCallback(() => setAttempt((n) => n + 1), [])

  return { ...state, reload }
}

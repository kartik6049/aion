import { useCallback, useEffect, useState } from 'react'
import { formatHash, parseHash } from '../lib/route'

export function useHashRoute() {
  const [route, setRoute] = useState(() => parseHash(window.location.hash))

  useEffect(() => {
    const onChange = () => setRoute(parseHash(window.location.hash))
    window.addEventListener('hashchange', onChange)
    return () => window.removeEventListener('hashchange', onChange)
  }, [])

  const navigate = useCallback((next) => {
    window.location.hash = formatHash(next)
  }, [])

  return [route, navigate]
}

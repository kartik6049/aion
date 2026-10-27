// Minimal hash router: "#/", "#/dashboard", "#/dashboard/zone/<name>", "#/game".
// Hash routing keeps deep links and the browser back button working without
// a router dependency or server-side rewrite rules.

export function parseHash(hash) {
  const path = (hash || '').replace(/^#\/?/, '')
  const parts = path.split('/').filter(Boolean)

  if (parts[0] === 'game') return { page: 'game' }
  if (parts[0] === 'facts') return { page: 'facts' }

  if (parts[0] === 'dashboard') {
    if (parts[1] === 'zone' && parts[2]) {
      try {
        return { page: 'zone', zone: decodeURIComponent(parts.slice(2).join('/')) }
      } catch {
        return { page: 'dashboard' } // malformed percent-encoding
      }
    }
    return { page: 'dashboard' }
  }

  return { page: 'home' }
}

export function formatHash(route) {
  switch (route.page) {
    case 'game':
      return '#/game'
    case 'facts':
      return '#/facts'
    case 'dashboard':
      return '#/dashboard'
    case 'zone':
      return `#/dashboard/zone/${encodeURIComponent(route.zone)}`
    default:
      return '#/'
  }
}

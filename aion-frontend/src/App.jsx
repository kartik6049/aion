import { useHashRoute } from './hooks/useHashRoute'

import Home from './pages/Home'
import Dashboard from './pages/Dashboard'
import ZoneDetails from './pages/ZoneDetails'
import GameLab from './pages/GameLab'

function App() {
  const [route, navigate] = useHashRoute()

  switch (route.page) {
    case 'game':
      return <GameLab onBack={() => navigate({ page: 'home' })} />

    case 'zone':
      return (
        <ZoneDetails
          zoneName={route.zone}
          onBack={() => navigate({ page: 'dashboard' })}
        />
      )

    case 'dashboard':
      return (
        <Dashboard
          onBack={() => navigate({ page: 'home' })}
          onZoneSelect={(zone) => navigate({ page: 'zone', zone })}
        />
      )

    default:
      return (
        <Home
          onOpenEmergency={() => navigate({ page: 'dashboard' })}
          onOpenGameLab={() => navigate({ page: 'game' })}
        />
      )
  }
}

export default App

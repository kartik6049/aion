import Header from '../components/Header'
import StatCard from '../components/StatCard'
import ZoneCard from '../components/ZoneCard'
import StatusMessage from '../components/StatusMessage'
import { useAsync } from '../hooks/useAsync'
import { getPlan, getSystem } from '../services/api'
import { formatText } from '../lib/format'
import { describeShortage } from '../lib/shortages'

function loadDashboard(signal) {
  return Promise.all([getPlan({ signal }), getSystem({ signal })])
}

function Dashboard({ onZoneSelect, onBack, onOpenFacts }) {
  const { data, error, loading, reload } = useAsync(loadDashboard, [])

  const status = error ? 'offline' : loading ? 'checking' : 'online'
  const [plan, system] = data ?? []

  return (
    <div className="app-shell">
      <Header status={status} />

      <main className="dashboard">
        <button type="button" className="back-button" onClick={onBack}>
          ← Back to AION
        </button>

        {loading && (
          <StatusMessage
            kind="loading"
            title="Loading emergency response data"
          />
        )}

        {error && (
          <StatusMessage
            kind="error"
            title="Unable to load emergency response data"
            detail={error.message}
            onRetry={reload}
          />
        )}

        {data && <DashboardContent
            plan={plan}
            system={system}
            onZoneSelect={onZoneSelect}
            onOpenFacts={onOpenFacts}
          />}
      </main>
    </div>
  )
}

function DashboardContent({ plan, system, onZoneSelect, onOpenFacts }) {
  const zones = plan?.plan ?? []
  const metrics = system?.metrics ?? {}
  const disaster = system?.disaster ?? {}
  const shortages = system?.resource_shortages ?? []

  return (
    <>
      <section className="overview">
        <div>
          <div className="eyebrow">
            {formatText(disaster.type, 'Emergency')} ·{' '}
            {formatText(disaster.severity, 'Unknown severity')}
          </div>

          <h1>Emergency Response Overview</h1>

          <p>Response priorities and resource decisions derived by the Prolog reasoning engine.</p>

          <button type="button" className="text-link" onClick={onOpenFacts}>
            View the facts behind these results
          </button>
        </div>

        <div className="zone-count">
          <strong>{metrics.total_zones ?? zones.length}</strong>
          <span>Zones</span>
        </div>
      </section>

      <section className="stats-grid">
        <StatCard label="Critical Zones" value={metrics.critical_zones ?? 0} />
        <StatCard
          label="Medical Emergency"
          value={metrics.medical_emergency_zones ?? 0}
        />
        <StatCard
          label="Immediate Evacuation"
          value={metrics.immediate_evacuation_zones ?? 0}
        />
        <StatCard
          label="Resource Shortages"
          value={metrics.resource_shortages ?? 0}
        />
      </section>

      <section className="content-grid">
        <div className="panel">
          <div className="panel-header">
            <div>
              <div className="panel-eyebrow">PRIORITY</div>
              <h2>Response Zones</h2>
            </div>
          </div>

          {zones.length === 0 ? (
            <StatusMessage kind="empty" title="No zones were returned by the engine" />
          ) : (
            <div className="zone-list">
              {zones.map((zone, index) => (
                <ZoneCard
                  key={zone.zone}
                  zone={zone}
                  index={index}
                  onClick={() => onZoneSelect(zone.zone)}
                />
              ))}
            </div>
          )}
        </div>

        <div className="panel system-panel">
          <div className="panel-eyebrow">RESOURCE SHORTAGES</div>

          {shortages.length === 0 ? (
            <p className="muted-text">No shortages detected.</p>
          ) : (
            <ul className="shortage-list">
              {shortages.map((item, index) => (
                <li key={`${item.type}-${item.zone}-${index}`}>
                  <span>
                    {item.zone}
                    <br />
                    <small className="muted-text">{describeShortage(item.type)}</small>
                  </span>
                  <strong>{formatText(item.type)}</strong>
                </li>
              ))}
            </ul>
          )}
        </div>
      </section>
    </>
  )
}

export default Dashboard

import Header from '../components/Header'
import StatusMessage from '../components/StatusMessage'
import { useAsync } from '../hooks/useAsync'
import { getFacts } from '../services/api'
import { formatText } from '../lib/format'

const show = (value) => (value === null || value === undefined ? '—' : value)
const label = (value) => formatText(value, '—')

const ZONE_COLUMNS = [
  ['Zone', 'zone'],
  ['Population', 'population'],
  ['Needing evacuation', 'evacuation_population'],
  ['Children', 'children'],
  ['Elderly', 'elderly'],
  ['Disabled', 'disabled'],
  ['Risk level', 'risk_level', label],
  ['Flood level', 'flood_level', label],
  ['Structural damage', 'structural_damage', label],
  ['Population at risk', 'population_at_risk'],
  ['Urgency', 'urgency', label],
  ['Grid position', null, (_v, row) => `${show(row.x)}, ${show(row.y)}`],
]

const MEDICAL_COLUMNS = [
  ['Zone', 'zone'],
  ['Critical', 'critical_cases'],
  ['Serious', 'serious_cases'],
  ['Minor', 'minor_cases'],
]

const HOSPITAL_COLUMNS = [
  ['Hospital', 'name'],
  ['Zone', 'zone'],
  ['Total beds', 'total_capacity'],
  ['Beds free', 'available_capacity'],
  ['Status', 'status', label],
  ['Capability', 'capability', label],
]

const SHELTER_COLUMNS = [
  ['Shelter', 'name'],
  ['Zone', 'zone'],
  ['Total places', 'total_capacity'],
  ['Places free', 'available_capacity'],
  ['Status', 'status', label],
  ['Medical support', 'medical_support', label],
  ['Family friendly', 'family_friendly', label],
  ['Accessibility support', 'accessibility_support', label],
]

const AMBULANCE_COLUMNS = [
  ['Ambulance', 'name'],
  ['Based in', 'zone'],
  ['Status', 'status', label],
  ['Capability', 'capability', label],
  ['Patients', 'capacity'],
]

const ROAD_COLUMNS = [
  ['Road', 'name'],
  ['From', 'from'],
  ['To', 'to'],
  ['Distance', 'distance'],
  ['Status', 'status', label],
  ['Risk', 'risk', label],
  ['Capacity', 'capacity'],
  ['Congestion factor', 'congestion_factor'],
]

function FactsTable({ title, caption, columns, rows }) {
  return (
    <section className="facts-section">
      <h2>{title}</h2>
      {caption && <p className="muted-text facts-caption">{caption}</p>}

      <div className="facts-table-wrap">
        <table className="facts-table">
          <thead>
            <tr>
              {columns.map(([heading]) => (
                <th key={heading} scope="col">
                  {heading}
                </th>
              ))}
            </tr>
          </thead>
          <tbody>
            {rows.map((row, index) => (
              <tr key={`${row.name ?? row.zone}-${index}`}>
                {columns.map(([heading, key, format], column) => {
                  const raw = key ? row[key] : undefined
                  const text = format ? format(raw, row) : show(raw)
                  return column === 0 ? (
                    <th key={heading} scope="row">
                      {text}
                    </th>
                  ) : (
                    <td key={heading}>{text}</td>
                  )
                })}
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </section>
  )
}

function Facts({ onBack }) {
  const { data, error, loading, reload } = useAsync(
    (signal) => getFacts({ signal }),
    [],
  )

  const status = error ? 'offline' : loading ? 'checking' : 'online'

  return (
    <div className="app-shell">
      <Header status={status} />

      <main className="facts-page">
        <button type="button" className="back-button" onClick={onBack}>
          ← Back to Dashboard
        </button>

        {loading && <StatusMessage kind="loading" title="Loading system facts" />}

        {error && (
          <StatusMessage
            kind="error"
            title="Unable to load system facts"
            detail={error.message}
            onRetry={reload}
          />
        )}

        {data && <FactsContent facts={data} />}
      </main>
    </div>
  )
}

function FactsContent({ facts }) {
  const scenario = facts.scenario ?? {}

  return (
    <>
      <section className="facts-heading">
        <div className="eyebrow">
          {formatText(scenario.disaster_type, 'Scenario')} ·{' '}
          {formatText(scenario.disaster_severity, 'Unknown severity')}
        </div>
        <h1>System Facts</h1>
        <p>
          The input facts the reasoning engine starts from, shown exactly as stored. Use them
          to check the dashboard results.
        </p>
        <p className="muted-text">
          {show(scenario.name)} (version {show(scenario.version)}). {show(scenario.description)}
        </p>
        <p className="muted-text">
          This page is read-only. Hospital beds and shelter places are the starting values
          before any resources are assigned to zones. To change a fact, edit{' '}
          <code>expert_system/facts.pl</code> and redeploy.
        </p>
      </section>

      <FactsTable
        title="Zones"
        columns={ZONE_COLUMNS}
        rows={facts.zones ?? []}
      />
      <FactsTable
        title="Medical cases"
        columns={MEDICAL_COLUMNS}
        rows={facts.zones ?? []}
      />
      <FactsTable
        title="Hospitals"
        columns={HOSPITAL_COLUMNS}
        rows={facts.hospitals ?? []}
      />
      <FactsTable
        title="Shelters"
        columns={SHELTER_COLUMNS}
        rows={facts.shelters ?? []}
      />
      <FactsTable
        title="Ambulances"
        columns={AMBULANCE_COLUMNS}
        rows={facts.ambulances ?? []}
      />
      <FactsTable
        title="Roads"
        caption="Route cost is distance times congestion factor, plus penalties for road status and risk."
        columns={ROAD_COLUMNS}
        rows={facts.roads ?? []}
      />
    </>
  )
}

export default Facts

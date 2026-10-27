import Header from '../components/Header'
import RoutePath from '../components/RoutePath'
import StatusMessage from '../components/StatusMessage'
import { useAsync } from '../hooks/useAsync'
import { getZone } from '../services/api'
import { formatText } from '../lib/format'

function DetailCard({ label, value }) {
  return (
    <div className="detail-card">
      <span>{label}</span>
      <strong>{value ?? '—'}</strong>
    </div>
  )
}

function ResourceCard({ label, name, children }) {
  return (
    <div className="resource-card">
      <span>{label}</span>
      <strong>{name || 'None'}</strong>
      {name && children && <small>{children}</small>}
    </div>
  )
}

function ReasoningStep({ number, title, items, final = false, children }) {
  return (
    <div className={`reasoning-step${final ? ' reasoning-final' : ''}`}>
      <div className="reasoning-number">{String(number).padStart(2, '0')}</div>

      <div className="reasoning-step-content">
        <div className="reasoning-step-title">{title}</div>
        {children}
        <div className="reasoning-details">
          {items.map(([label, value]) => (
            <span key={label}>
              {label}: <strong>{value ?? '—'}</strong>
            </span>
          ))}
        </div>
      </div>
    </div>
  )
}

function ZoneDetails({ zoneName, onBack }) {
  const { data: zoneData, error, loading, reload } = useAsync(
    (signal) => getZone(zoneName, { signal }),
    [zoneName],
  )

  const status = error ? 'offline' : loading ? 'checking' : 'online'

  return (
    <div className="app-shell">
      <Header status={status} />

      <main className="zone-details">
        <button type="button" className="back-button" onClick={onBack}>
          ← Back to Dashboard
        </button>

        {loading && (
          <StatusMessage kind="loading" title={`Loading ${zoneName}`} />
        )}

        {error && (
          <StatusMessage
            kind="error"
            title={
              error.status === 404
                ? `Zone "${zoneName}" was not found`
                : 'Unable to load zone response'
            }
            detail={error.message}
            onRetry={error.status === 404 ? undefined : reload}
          />
        )}

        {zoneData && <ZoneContent zoneData={zoneData} zoneName={zoneName} />}
      </main>
    </div>
  )
}

function ZoneContent({ zoneData, zoneName }) {
  const decision = zoneData.decision ?? {}
  const risk = decision.risk ?? {}
  const reasoning = zoneData.explanation?.reasoning ?? {}
  const facts = reasoning.facts?.zone_condition ?? {}
  const medical = reasoning.medical ?? {}
  const evacuation = reasoning.evacuation ?? {}

  const { ambulance, hospital, shelter } = decision

  return (
    <>
      <section className="zone-heading">
        <div>
          <div className="eyebrow">ZONE RESPONSE</div>
          <h1>{zoneData.zone || zoneName}</h1>
          <p>Recommended emergency response for this zone.</p>
        </div>

        <div className="zone-priority">
          <span>PRIORITY SCORE</span>
          <strong>{decision.priority_score ?? '—'}</strong>
        </div>
      </section>

      <section className="decision-banner">
        <div>
          <div className="decision-label">RECOMMENDED ACTION</div>
          <h2>{formatText(decision.action)}</h2>
        </div>

        <div className="decision-risk">
          <span>Risk Level</span>
          <strong>{formatText(risk.level)}</strong>
        </div>
      </section>

      <section className="detail-grid">
        <div className="detail-panel">
          <div className="panel-eyebrow">SITUATION</div>
          <h2>Emergency Assessment</h2>

          <div className="detail-cards">
            <DetailCard label="Risk Level" value={formatText(risk.level)} />
            <DetailCard label="Risk Score" value={risk.score} />
            <DetailCard
              label="Medical Priority"
              value={formatText(decision.medical)}
            />
            <DetailCard
              label="Evacuation Priority"
              value={formatText(decision.evacuation)}
            />
          </div>
        </div>

        <div className="detail-panel">
          <div className="panel-eyebrow">RESOURCES</div>
          <h2>Assigned Resources</h2>

          <div className="resource-list">
            <ResourceCard label="Ambulance" name={ambulance?.name !== 'none' && ambulance?.name}>
              {formatText(ambulance?.capability)} · Capacity {ambulance?.capacity}
              <br />
              Route: {ambulance?.route?.join(' → ') || 'Unavailable'}
            </ResourceCard>

            <ResourceCard label="Hospital" name={hospital?.name !== 'none' && hospital?.name}>
              {formatText(hospital?.status)} · {hospital?.available_capacity} beds free when assigned
              <br />
              {hospital?.patients} patients expected from this zone
            </ResourceCard>

            <ResourceCard label="Shelter" name={shelter?.name !== 'none' && shelter?.name}>
              {formatText(shelter?.status)} · {shelter?.available_capacity} places free when assigned
              <br />
              Medical support: {formatText(shelter?.medical_support)} · Family friendly:{' '}
              {formatText(shelter?.family_friendly)}
            </ResourceCard>
          </div>
        </div>
      </section>

      <section className="reasoning-panel route-panel">
        <div className="panel-eyebrow">ROUTES & MOVEMENT</div>
        <h2>Recommended Routes</h2>

        <div className="route-list">
          <RoutePath label="AMBULANCE" name={ambulance?.name} route={ambulance?.route} />
          <RoutePath label="EVACUATION" name={shelter?.name} route={shelter?.route} />
          <RoutePath label="HOSPITAL" name={hospital?.name} route={hospital?.route} />
        </div>
      </section>

      <section className="detail-grid">
        <div className="detail-panel">
          <div className="panel-eyebrow">MEDICAL</div>
          <h2>Medical Situation</h2>

          <div className="detail-cards">
            <DetailCard label="Critical Cases" value={medical.critical_cases} />
            <DetailCard label="Serious Cases" value={medical.serious_cases} />
            <DetailCard label="Minor Cases" value={medical.minor_cases} />
            <DetailCard label="Total Cases" value={medical.total_cases} />
          </div>
        </div>

        <div className="detail-panel">
          <div className="panel-eyebrow">EVACUATION</div>
          <h2>Evacuation Assessment</h2>

          <div className="detail-cards">
            <DetailCard label="People at Risk" value={evacuation.people} />
            <DetailCard label="Priority" value={formatText(evacuation.priority)} />
          </div>
        </div>
      </section>

      <section className="reasoning-panel">
        <div className="panel-eyebrow">AI REASONING</div>
        <h2>Why This Decision?</h2>

        <div className="reasoning-chain">
          <ReasoningStep
            number={1}
            title="Current Situation"
            items={[
              ['Flood Level', formatText(facts.flood_level)],
              ['Risk Condition', formatText(facts.risk_level)],
              ['Population at Risk', facts.population_at_risk],
              ['Urgency', formatText(facts.urgency)],
            ]}
          />
          <div className="reasoning-arrow" aria-hidden="true">↓</div>

          <ReasoningStep
            number={2}
            title="Medical Assessment"
            items={[
              ['Total Cases', medical.total_cases],
              ['Critical', medical.critical_cases],
              ['Serious', medical.serious_cases],
              ['Minor', medical.minor_cases],
              ['Priority', formatText(medical.priority)],
            ]}
          />
          <div className="reasoning-arrow" aria-hidden="true">↓</div>

          <ReasoningStep
            number={3}
            title="Evacuation Assessment"
            items={[
              ['People Requiring Evacuation', evacuation.people],
              ['Evacuation Priority', formatText(evacuation.priority)],
            ]}
          />
          <div className="reasoning-arrow" aria-hidden="true">↓</div>

          <ReasoningStep
            number={4}
            title="Risk Assessment"
            items={[
              ['Risk Score', risk.score],
              ['Risk Level', formatText(risk.level)],
            ]}
          />
          <div className="reasoning-arrow" aria-hidden="true">↓</div>

          <ReasoningStep
            number={5}
            title="Final Decision"
            final
            items={[['Priority Score', decision.priority_score]]}
          >
            <div className="reasoning-final-action">{formatText(decision.action)}</div>
          </ReasoningStep>
        </div>
      </section>
    </>
  )
}

export default ZoneDetails

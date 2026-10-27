import { formatText } from '../lib/format'

function priorityClassFor(score) {
  if (score >= 40) return 'critical'
  if (score >= 25) return 'high'
  if (score >= 10) return 'medium'
  return 'low'
}

function ZoneCard({ zone, index, onClick }) {
  const priority = zone.priority_score ?? 0
  const priorityClass = priorityClassFor(priority)

  return (
    <button type="button" className="zone-card" onClick={onClick}>
      <div className="zone-number">{String(index + 1).padStart(2, '0')}</div>

      <div className="zone-main">
        <div className="zone-name">{zone.zone}</div>
        <div className={`priority-label ${priorityClass}`}>
          Priority {priority}
        </div>
      </div>

      <div className={`priority-indicator ${priorityClass}`}>
        {formatText(zone.action, 'Monitor')}
      </div>
    </button>
  )
}

export default ZoneCard

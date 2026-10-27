const STATUS_LABELS = {
  online: 'Backend connected',
  checking: 'Connecting',
  offline: 'Backend unavailable',
}

function Header({ status = 'checking' }) {
  return (
    <header className="header">
      <div>
        <div className="brand">AION</div>
        <div className="brand-subtitle">
          AI Emergency Response Decision System
        </div>
      </div>

      <div className={`system-status system-status-${status}`} role="status">
        <span className="status-dot" aria-hidden="true"></span>
        {STATUS_LABELS[status] ?? STATUS_LABELS.checking}
      </div>
    </header>
  )
}

export default Header

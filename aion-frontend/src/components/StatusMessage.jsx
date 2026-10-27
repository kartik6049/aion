/**
 * Consistent loading / error / empty states.
 * `onRetry` renders a retry button; `children` holds secondary actions.
 */
function StatusMessage({ kind, title, detail, onRetry, children }) {
  return (
    <div
      className={`status-message status-message-${kind}`}
      role={kind === 'error' ? 'alert' : 'status'}
    >
      <p className="status-message-title">{title}</p>
      {detail && <p className="status-message-detail">{detail}</p>}
      {(onRetry || children) && (
        <div className="status-message-actions">
          {onRetry && (
            <button type="button" className="action-button" onClick={onRetry}>
              Retry
            </button>
          )}
          {children}
        </div>
      )}
    </div>
  )
}

export default StatusMessage

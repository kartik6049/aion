import React from "react";

function EventLog({ entries = [] }) {
  return (
    <div className="event-log">
      <div className="event-log-header">
        <div>
          <h3>Event Log</h3>
          <p>Recent game events</p>
        </div>

        <span className="event-count">{entries.length}</span>
      </div>

      <div className="event-log-list">
        {entries.length === 0 ? (
          <div className="event-empty">
            <span className="event-empty-icon">○</span>
            <span>No events yet</span>
          </div>
        ) : (
          entries
            .slice()
            .reverse()
            .map((entry, index) => {
              const message =
                typeof entry === "string"
                  ? entry
                  : entry?.message || entry?.text || "Game event";

              const type =
                typeof entry === "object" && entry?.type
                  ? entry.type
                  : "info";

              return (
                <div
                  className={`event-item event-${type}`}
                  key={entry?.id || `${message}-${index}`}
                >
                  <span className="event-dot" />
                  <span className="event-message">{message}</span>
                </div>
              );
            })
        )}
      </div>
    </div>
  );
}

export default EventLog;
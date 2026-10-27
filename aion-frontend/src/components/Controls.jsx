import React from "react";

export default function Controls({ onMove, disabled }) {
  const NAMES = { up: "Move up", down: "Move down", left: "Move left", right: "Move right", wait: "Wait" };
  const button = (label, dir) => (
    <button
      type="button"
      aria-label={NAMES[dir]}
      disabled={disabled}
      onClick={() => onMove(dir)}
    >
      {label}
    </button>
  );

  return (
    <div className="panel">
      <h3>Controls</h3>
      <div className="controls">
        <span />
        {button("↑", "up")}
        <span />
        {button("←", "left")}
        {button("•", "wait")}
        {button("→", "right")}
        <span />
        {button("↓", "down")}
        <span />
        <button
          type="button"
          className="wide"
          disabled={disabled}
          onClick={() => onMove("wait")}
        >
          WAIT / HOLD
        </button>
      </div>
      <div className="hint">
        WAIT is valid only at a safe point · arrow keys also work
      </div>
    </div>
  );
}

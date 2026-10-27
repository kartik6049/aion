import React from "react";

export default function ScorePanel({ humanScore, aiScore }) {
  return (
    <div className="panel">
      <h3>Score</h3>
      <div className="score-row">
        <span className="human-label">Human</span>
        <b>{humanScore}</b>
      </div>
      <div className="score-row">
        <span className="ai-label">AI</span>
        <b>{aiScore}</b>
      </div>
    </div>
  );
}

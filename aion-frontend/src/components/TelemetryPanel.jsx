import React from "react";

export default function TelemetryPanel({ telemetry, collectiveMoves }) {
  return (
    <div className="panel">
      <h3>AI Search Telemetry</h3>
      <div className="stat"><span>algorithm</span><b>Minimax + α-β</b></div>
      <div className="stat"><span>heuristic</span><b>BFS + A*</b></div>
      <div className="stat"><span>depth</span><b>{telemetry.depth ?? 4}</b></div>
      <div className="stat"><span>nodes evaluated</span><b>{telemetry.nodes ?? 0}</b></div>
      <div className="stat"><span>branches pruned</span><b>{telemetry.pruned ?? 0}</b></div>
      <div className="stat"><span>leaf evaluations</span><b>{telemetry.leaves ?? 0}</b></div>
      <div className="stat"><span>AI BFS route</span><b>{telemetry.aiBfs ?? "—"}</b></div>
      <div className="stat"><span>AI A* cost</span><b>{telemetry.aiAStar ?? "—"}</b></div>
      <div className="stat"><span>collective moves</span><b>{collectiveMoves}</b></div>
      <div className="stat"><span>last AI action</span><b>{telemetry.action || "—"}</b></div>
    </div>
  );
}

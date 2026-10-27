import React from "react";
import { N, isEvacuationPosition } from "../lib/gameRules";

export default function Board({ grid, humanPos, aiPos }) {
  const cells = [];

  for (let r = 0; r < N; r++) {
    for (let c = 0; c < N; c++) {
      const cell = grid[r][c];
      const key = `${r},${c}`;

      const hHere = humanPos[0] === r && humanPos[1] === c;
      const aHere = aiPos[0] === r && aiPos[1] === c;

      let token = null;
      if (hHere && aHere) token = <div className="token both">H/A</div>;
      else if (hHere) token = <div className="token human">H</div>;
      else if (aHere) token = <div className="token ai">AI</div>;

      const isEvac = isEvacuationPosition([r, c]);

      cells.push(
        <div
          key={key}
          className={`cell ${cell.type}${isEvac ? " evac" : ""}`}
        >
          {token}
        </div>
      );
    }
  }

  return (
    <div
      className="board"
      style={{ gridTemplateColumns: `repeat(${N}, 1fr)` }}
    >
      {cells}
    </div>
  );
}
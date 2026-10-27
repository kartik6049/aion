import { DIRECTIONS, N, RULES, cellKey, isSafeCell } from "./gameRules";
import { inBounds } from "./pathfinding";

export function isMoveLegal(grid, pos, dir, actionCount = 0, evacuated = false) {
  if (evacuated || actionCount >= RULES.maxActions) return null;
  const delta = DIRECTIONS[dir];
  if (!delta) return null;

  const [dr, dc] = delta;
  const nr = pos[0] + dr;
  const nc = pos[1] + dc;

  if (!inBounds(nr, nc, N)) return null;
  if (grid[nr][nc].type === "wall") return null;

  if (dir === "wait" && !isSafeCell(pos)) return null;

  return [nr, nc];
}

export function legalMoves(grid, pos, actionCount = 0, evacuated = false) {
  if (evacuated || actionCount >= RULES.maxActions) return [];

  const out = [];
  for (const dir of ["up", "down", "left", "right", "wait"]) {
    const next = isMoveLegal(grid, pos, dir, actionCount, evacuated);
    if (next) out.push({ dir, pos: next });
  }
  return out;
}

export function applyCellEffect(state, who, nextPos) {
  const player = state[who];
  const cell = state.grid[nextPos[0]][nextPos[1]];
  const next = {
    ...state,
    [who]: {
      ...player,
      pos: [...nextPos],
      rescued: new Set(player.rescued),
    },
  };

  if (cell.type === "hazard") {
    next[who].score += RULES.hazard;
  }

  if (cell.type === "civilian") {
    const k = cellKey(nextPos);
    if (!next[who].rescued.has(k)) {
      next[who].rescued.add(k);
      next[who].score += RULES.rescue;
    }
  }

  if (cell.type === "evac") {
    next[who].evacuated = true;
  }

  return next;
}

export function canPlayerAct(player) {
  return !player.evacuated && player.actions < RULES.maxActions;
}

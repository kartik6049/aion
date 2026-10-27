import { N, RULES, SPECIAL_CELLS, cellKey } from "./gameRules";
import { bfsPath } from "./pathfinding";

const protectedKeys = new Set(
  Object.values(SPECIAL_CELLS).map(cellKey)
);

function emptyGrid() {
  return Array.from({ length: N }, () =>
    Array.from({ length: N }, () => ({ type: "open" }))
  );
}

function randomCell() {
  return [Math.floor(Math.random() * N), Math.floor(Math.random() * N)];
}

function placeRandom(grid, type, count, blocked = new Set()) {
  let placed = 0;
  let tries = 0;

  while (placed < count && tries < 1000) {
    tries++;
    const pos = randomCell();
    const k = cellKey(pos);

    if (blocked.has(k) || grid[pos[0]][pos[1]].type !== "open") continue;
    grid[pos[0]][pos[1]] = { type };
    placed++;
  }

  return placed === count;
}

function reachableFrom(grid, start, goal) {
  return Boolean(bfsPath(grid, start, goal));
}

function validateStartingBoard(grid) {
  const starts = [
    SPECIAL_CELLS.safeHuman,
    SPECIAL_CELLS.safeAI,
  ];
  const targets = [];

  for (let r = 0; r < N; r++) {
    for (let c = 0; c < N; c++) {
      if (grid[r][c].type === "civilian") targets.push([r, c]);
    }
  }
  targets.push(SPECIAL_CELLS.evacuation);

  for (const start of starts) {
    for (const target of targets) {
      if (!reachableFrom(grid, start, target)) return false;
    }
  }

  // Both players must have at least one actual movement option.
  for (const [r, c] of starts) {
    const exits = [
      [r - 1, c],
      [r + 1, c],
      [r, c - 1],
      [r, c + 1],
    ].filter(
      ([nr, nc]) =>
        nr >= 0 &&
        nr < N &&
        nc >= 0 &&
        nc < N &&
        grid[nr][nc].type !== "wall"
    );

    if (!exits.length) return false;
  }

  return true;
}

export function generateBoard() {
  for (let attempt = 0; attempt < 300; attempt++) {
    const grid = emptyGrid();

    grid[0][0] = { type: "safe" };
    grid[N - 1][0] = { type: "safe" };
    grid[N - 1][N - 1] = { type: "evac" };

    const blocked = new Set(protectedKeys);

    if (!placeRandom(grid, "wall", RULES.initialWalls, blocked)) continue;
    if (!placeRandom(grid, "hazard", RULES.initialHazards, blocked)) continue;
    if (!placeRandom(grid, "civilian", RULES.initialCivilians, blocked)) continue;

    if (validateStartingBoard(grid)) return grid;
  }

  // Deterministic fallback: guarantees a playable connected board.
  const grid = emptyGrid();
  grid[0][0] = { type: "safe" };
  grid[N - 1][0] = { type: "safe" };
  grid[N - 1][N - 1] = { type: "evac" };

  for (let i = 0; i < 6; i++) {
    const r = 1 + Math.floor(i / 3) * 2;
    const c = 2 + (i % 3) * 2;
    if (grid[r]?.[c]?.type === "open") grid[r][c] = { type: "civilian" };
  }

  return grid;
}

export function reshuffleHazards(grid, occupied, count = RULES.initialHazards) {
  const next = grid.map((row) =>
    row.map((cell) => (cell.type === "hazard" ? { type: "open" } : cell))
  );

  const occupiedKeys = new Set(occupied.map(cellKey));
  const blocked = new Set([...protectedKeys, ...occupiedKeys]);

  let placed = 0;
  let tries = 0;

  while (placed < count && tries < 1200) {
    tries++;
    const pos = randomCell();
    const k = cellKey(pos);

    if (blocked.has(k) || next[pos[0]][pos[1]].type !== "open") continue;
    next[pos[0]][pos[1]] = { type: "hazard" };
    placed++;
  }

  return next;
}

export function updateCivilians(grid, humanRescued, aiRescued) {
  const rescuedByEither = new Set([
    ...humanRescued,
    ...aiRescued,
  ]);

  // Copy the board, then clear civilians that were rescued by either player.
  const next = grid.map((row) => row.map((cell) => cell));

  for (let r = 0; r < N; r++) {
    for (let c = 0; c < N; c++) {
      if (
        grid[r][c].type === "civilian" &&
        rescuedByEither.has(`${r},${c}`)
      ) {
        next[r][c] = { type: "open" };
      }
    }
  }

  const occupied = new Set([
    ...protectedKeys,
    ...humanRescued,
    ...aiRescued,
  ]);

  let current = 0;
  for (let r = 0; r < N; r++) {
    for (let c = 0; c < N; c++) {
      if (next[r][c].type === "civilian") current++;
    }
  }

  let tries = 0;
  while (current < RULES.initialCivilians && tries < 1200) {
    tries++;
    const pos = randomCell();
    const k = cellKey(pos);

    if (occupied.has(k) || next[pos[0]][pos[1]].type !== "open") continue;

    // Keep new civilians reasonably away from starts/special cells.
    const nearHuman = Math.abs(pos[0]) + Math.abs(pos[1]) < 3;
    const nearAI = Math.abs(pos[0] - (N - 1)) + Math.abs(pos[1]) < 3;
    if (nearHuman || nearAI) continue;

    next[pos[0]][pos[1]] = { type: "civilian" };
    current++;
  }

  return next;
}

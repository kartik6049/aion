// AION — Disaster Rescue Strategy
export const N = 8;

export const RULES = {
  rescue: 3,
  hazard: -2,
  wait: 0,
  maxActions: 50,
  environmentEveryCollectiveMoves: 2,
  civiliansEveryCollectiveMoves: 10,
  initialWalls: 10,
  initialHazards: 8,
  initialCivilians: 6,
  maxCivilians: 8,
  minimaxDepth: 4,
};

export const START_POSITIONS = {
  human: [0, 0],
  ai: [N - 1, 0],
};

export const SPECIAL_CELLS = {
  safeHuman: [0, 0],
  safeAI: [N - 1, 0],
  evacuation: [N - 1, N - 1],
};

export const MOVE_ORDER = ["up", "down", "left", "right", "wait"];

export const DIRECTIONS = {
  up: [-1, 0],
  down: [1, 0],
  left: [0, -1],
  right: [0, 1],
  wait: [0, 0],
};

export const cellKey = ([r, c]) => `${r},${c}`;

export const samePosition = (a, b) => a[0] === b[0] && a[1] === b[1];

export const isEvacuationPosition = (pos) =>
  pos[0] === SPECIAL_CELLS.evacuation[0] &&
  pos[1] === SPECIAL_CELLS.evacuation[1];

export const isSafeCell = (pos) =>
  (pos[0] === SPECIAL_CELLS.safeHuman[0] && pos[1] === SPECIAL_CELLS.safeHuman[1]) ||
  (pos[0] === SPECIAL_CELLS.safeAI[0] && pos[1] === SPECIAL_CELLS.safeAI[1]);

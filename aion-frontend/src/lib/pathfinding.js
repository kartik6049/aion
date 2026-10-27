import { DIRECTIONS, N } from "./gameRules";

export function inBounds(r, c, size = N) {
  return r >= 0 && r < size && c >= 0 && c < size;
}

export function neighbors(r, c, grid) {
  const out = [];
  for (const [dr, dc] of Object.values(DIRECTIONS).filter(
    ([dr, dc]) => !(dr === 0 && dc === 0)
  )) {
    const nr = r + dr;
    const nc = c + dc;
    if (inBounds(nr, nc, grid.length) && grid[nr][nc].type !== "wall") {
      out.push([nr, nc]);
    }
  }
  return out;
}

export function manhattanDistance(a, b) {
  return Math.abs(a[0] - b[0]) + Math.abs(a[1] - b[1]);
}

export function bfsPath(grid, start, goal) {
  if (!start || !goal) return null;
  const key = ([r, c]) => `${r},${c}`;
  const startKey = key(start);
  const goalKey = key(goal);
  const queue = [start];
  const visited = new Set([startKey]);
  const previous = new Map();

  while (queue.length) {
    const current = queue.shift();
    if (key(current) === goalKey) break;

    for (const next of neighbors(current[0], current[1], grid)) {
      const k = key(next);
      if (!visited.has(k)) {
        visited.add(k);
        previous.set(k, current);
        queue.push(next);
      }
    }
  }

  if (!visited.has(goalKey)) return null;

  const path = [goal];
  let cursor = goalKey;
  while (cursor !== startKey) {
    const prev = previous.get(cursor);
    if (!prev) return null;
    path.push(prev);
    cursor = key(prev);
  }
  return path.reverse();
}

export function aStarPath(grid, start, goal) {
  if (!start || !goal) return null;

  const key = ([r, c]) => `${r},${c}`;
  const startKey = key(start);
  const goalKey = key(goal);
  const heuristic = (pos) => manhattanDistance(pos, goal);
  const movementCost = (pos) => (grid[pos[0]][pos[1]].type === "hazard" ? 3 : 1);

  const open = [{ pos: start, g: 0, f: heuristic(start) }];
  const gScore = new Map([[startKey, 0]]);
  const previous = new Map();
  const closed = new Set();

  while (open.length) {
    open.sort((a, b) => a.f - b.f);
    const current = open.shift();
    const currentKey = key(current.pos);

    if (closed.has(currentKey)) continue;
    closed.add(currentKey);

    if (currentKey === goalKey) {
      const path = [goal];
      let cursor = currentKey;
      while (cursor !== startKey) {
        const prev = previous.get(cursor);
        if (!prev) return null;
        path.push(prev);
        cursor = key(prev);
      }
      return path.reverse();
    }

    for (const next of neighbors(current.pos[0], current.pos[1], grid)) {
      const nextKey = key(next);
      const tentative = current.g + movementCost(next);

      if (!gScore.has(nextKey) || tentative < gScore.get(nextKey)) {
        gScore.set(nextKey, tentative);
        previous.set(nextKey, current.pos);
        open.push({
          pos: next,
          g: tentative,
          f: tentative + heuristic(next),
        });
      }
    }
  }

  return null;
}

export function pathLength(path) {
  return path ? Math.max(0, path.length - 1) : Infinity;
}

export function pathCost(grid, path) {
  if (!path || path.length < 2) return 0;
  let cost = 0;
  for (let i = 1; i < path.length; i++) {
    cost += grid[path[i][0]][path[i][1]].type === "hazard" ? 3 : 1;
  }
  return cost;
}

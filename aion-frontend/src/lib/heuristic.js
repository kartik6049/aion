import { RULES, N, cellKey, isEvacuationPosition } from "./gameRules";
import { legalMoves } from "./gameValidator";
import {
  aStarPath,
  bfsPath,
  manhattanDistance,
  pathCost,
  pathLength,
} from "./pathfinding";

function civilianTargets(grid) {
  const targets = [];
  for (let r = 0; r < N; r++) {
    for (let c = 0; c < N; c++) {
      if (grid[r][c].type === "civilian") targets.push([r, c]);
    }
  }
  return targets;
}

function remainingTargets(grid, rescued) {
  return civilianTargets(grid).filter(([r, c]) => !rescued.has(cellKey([r, c])));
}

function routeMetrics(grid, pos, rescued) {
  const targets = remainingTargets(grid, rescued);
  if (!targets.length) {
    const bfs = bfsPath(grid, pos, [N - 1, N - 1]);
    const astar = aStarPath(grid, pos, [N - 1, N - 1]);
    return {
      bfsDistance: pathLength(bfs),
      aStarCost: pathCost(grid, astar),
      target: [N - 1, N - 1],
    };
  }

  let best = null;

  for (const target of targets) {
    const bfs = bfsPath(grid, pos, target);
    const astar = aStarPath(grid, pos, target);
    if (!bfs || !astar) continue;

    const candidate = {
      bfsDistance: pathLength(bfs),
      aStarCost: pathCost(grid, astar),
      target,
    };

    if (
      !best ||
      candidate.aStarCost < best.aStarCost ||
      (candidate.aStarCost === best.aStarCost &&
        candidate.bfsDistance < best.bfsDistance)
    ) {
      best = candidate;
    }
  }

  return best || {
    bfsDistance: Infinity,
    aStarCost: Infinity,
    target: null,
  };
}

function hazardRisk(grid, pos) {
  let risk = 0;
  for (let r = Math.max(0, pos[0] - 1); r <= Math.min(N - 1, pos[0] + 1); r++) {
    for (let c = Math.max(0, pos[1] - 1); c <= Math.min(N - 1, pos[1] + 1); c++) {
      if (grid[r][c].type === "hazard") risk++;
    }
  }
  return risk;
}

// 0..1 weight for how much evacuating is worth to this player right now.
function evacuationWeight(state, player) {
  if (remainingTargets(state.grid, player.rescued).length === 0) return 1;

  const used = Math.min(1, player.actions / RULES.maxActions);
  return used * used;
}

export function evaluateState(state, forAI = true) {
  const ai = state.ai;
  const human = state.human;

  const aiRoute = routeMetrics(state.grid, ai.pos, ai.rescued);
  const humanRoute = routeMetrics(state.grid, human.pos, human.rescued);

  const aiMobility = legalMoves(
    state.grid,
    ai.pos,
    ai.actions,
    ai.evacuated
  ).length;

  const humanMobility = legalMoves(
    state.grid,
    human.pos,
    human.actions,
    human.evacuated
  ).length;

  let value = 0;

  value += (ai.score - human.score) * 5;
  value += (human.rescued.size - ai.rescued.size) * 3;

  if (Number.isFinite(aiRoute.bfsDistance) && Number.isFinite(humanRoute.bfsDistance)) {
    value += (humanRoute.bfsDistance - aiRoute.bfsDistance) * 0.9;
  }

  if (Number.isFinite(aiRoute.aStarCost) && Number.isFinite(humanRoute.aStarCost)) {
    value += (humanRoute.aStarCost - aiRoute.aStarCost) * 0.8;
  }

  value += (aiMobility - humanMobility) * 0.35;
  value += (human.actions - ai.actions) * 0.08;
  value += (hazardRisk(state.grid, human.pos) - hazardRisk(state.grid, ai.pos)) * 0.45;

  // Evacuating earns no points and ends a player's actions, so it is only
  // attractive once there is little left to gain: the bonus grows as the
  // player's remaining actions run out, or when no civilians remain.
  const aiEvacWeight = evacuationWeight(state, ai);
  const humanEvacWeight = evacuationWeight(state, human);

  if (ai.evacuated) value += 18 * aiEvacWeight;
  if (human.evacuated) value -= 18 * humanEvacWeight;

  if (isEvacuationPosition(ai.pos)) value += 8 * aiEvacWeight;
  if (isEvacuationPosition(human.pos)) value -= 8 * humanEvacWeight;

  // Small distance-to-evacuation term when civilians are exhausted.
  if (remainingTargets(state.grid, ai.rescued).length === 0) {
    value += (manhattanDistance(human.pos, [N - 1, N - 1]) -
      manhattanDistance(ai.pos, [N - 1, N - 1])) * 0.25;
  }

  return forAI ? value : -value;
}

export function getRouteTelemetry(state) {
  const aiRoute = routeMetrics(state.grid, state.ai.pos, state.ai.rescued);
  const humanRoute = routeMetrics(state.grid, state.human.pos, state.human.rescued);

  return {
    aiBfs: Number.isFinite(aiRoute.bfsDistance) ? aiRoute.bfsDistance : "—",
    aiAStar: Number.isFinite(aiRoute.aStarCost) ? aiRoute.aStarCost : "—",
    humanBfs: Number.isFinite(humanRoute.bfsDistance) ? humanRoute.bfsDistance : "—",
    humanAStar: Number.isFinite(humanRoute.aStarCost) ? humanRoute.aStarCost : "—",
  };
}

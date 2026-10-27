import { RULES, MOVE_ORDER } from "./gameRules";
import { legalMoves, applyCellEffect, isMoveLegal } from "./gameValidator";
import { evaluateState, getRouteTelemetry } from "./heuristic";

function clonePlayer(player) {
  return {
    ...player,
    pos: [...player.pos],
    rescued: new Set(player.rescued),
  };
}

export function applyMove(state, who, dir) {
  const player = state[who];
  const nextPos = isMoveLegal(
    state.grid,
    player.pos,
    dir,
    player.actions,
    player.evacuated
  );

  if (!nextPos) return null;

  const next = {
    ...state,
    human: clonePlayer(state.human),
    ai: clonePlayer(state.ai),
  };

  next[who].actions += 1;

  const updated = applyCellEffect(next, who, nextPos);
  return updated;
}

function orderMoves(state, who, moves) {
  return [...moves].sort((a, b) => {
    const aState = applyMove(state, who, a.dir);
    const bState = applyMove(state, who, b.dir);

    const aScore = aState ? evaluateState(aState, true) : -Infinity;
    const bScore = bState ? evaluateState(bState, true) : -Infinity;

    const aiOrder = MOVE_ORDER.indexOf(a.dir) - MOVE_ORDER.indexOf(b.dir);

    if (who === "ai") {
      return bScore - aScore || aiOrder;
    }
    return aScore - bScore || aiOrder;
  });
}

function minimax(state, depth, alpha, beta, maximizing, telemetry) {
  telemetry.nodes++;

  const aiCanAct = !state.ai.evacuated && state.ai.actions < RULES.maxActions;
  const humanCanAct = !state.human.evacuated && state.human.actions < RULES.maxActions;

  if (depth === 0 || (!aiCanAct && !humanCanAct)) {
    telemetry.leaves++;
    return { score: evaluateState(state, true) };
  }

  const who = maximizing ? "ai" : "human";
  const player = state[who];

  if (player.evacuated || player.actions >= RULES.maxActions) {
    return minimax(state, depth, alpha, beta, !maximizing, telemetry);
  }

  const moves = legalMoves(
    state.grid,
    player.pos,
    player.actions,
    player.evacuated
  );

  if (!moves.length) {
    return minimax(state, depth - 1, alpha, beta, !maximizing, telemetry);
  }

  const ordered = orderMoves(state, who, moves);
  let bestDir = ordered[0].dir;

  if (maximizing) {
    let best = -Infinity;

    for (const move of ordered) {
      const next = applyMove(state, "ai", move.dir);
      if (!next) continue;

      const result = minimax(next, depth - 1, alpha, beta, false, telemetry);

      if (
        result.score > best ||
        (result.score === best &&
          MOVE_ORDER.indexOf(move.dir) < MOVE_ORDER.indexOf(bestDir))
      ) {
        best = result.score;
        bestDir = move.dir;
      }

      alpha = Math.max(alpha, best);

      if (beta <= alpha) {
        telemetry.pruned++;
        break;
      }
    }

    return { score: best, dir: bestDir };
  }

  let best = Infinity;

  for (const move of ordered) {
    const next = applyMove(state, "human", move.dir);
    if (!next) continue;

    const result = minimax(next, depth - 1, alpha, beta, true, telemetry);

    if (
      result.score < best ||
      (result.score === best &&
        MOVE_ORDER.indexOf(move.dir) < MOVE_ORDER.indexOf(bestDir))
    ) {
      best = result.score;
      bestDir = move.dir;
    }

    beta = Math.min(beta, best);

    if (beta <= alpha) {
      telemetry.pruned++;
      break;
    }
  }

  return { score: best, dir: bestDir };
}

export function decideAIAction(state, depth = RULES.minimaxDepth) {
  const telemetry = {
    nodes: 0,
    pruned: 0,
    leaves: 0,
  };

  const result = minimax(
    state,
    depth,
    -Infinity,
    Infinity,
    true,
    telemetry
  );

  return {
    dir: result.dir || "wait",
    score: result.score,
    depth,
    nodes: telemetry.nodes,
    pruned: telemetry.pruned,
    leaves: telemetry.leaves,
    route: getRouteTelemetry(state),
  };
}

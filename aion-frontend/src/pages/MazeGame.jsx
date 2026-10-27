import React, { useCallback, useEffect, useRef, useState } from "react";
import "./MazeGame.css";

import {
  RULES,
  START_POSITIONS,
  cellKey,
  isEvacuationPosition,
} from "../lib/gameRules";

import {
  generateBoard,
  reshuffleHazards,
  updateCivilians,
} from "../lib/boardGenerator";

import { isMoveLegal } from "../lib/gameValidator";
import { decideAIAction } from "../lib/minimax";

import Board from "../components/Board";
import ScorePanel from "../components/ScorePanel";
import TelemetryPanel from "../components/TelemetryPanel";
import EventLog from "../components/EventLog";
import Controls from "../components/Controls";


function createPlayer(pos) {
  return {
    pos: [...pos],
    score: 0,
    actions: 0,
    rescued: new Set(),
    evacuated: false,
  };
}


function freshState() {
  return {
    grid: generateBoard(),
    human: createPlayer(START_POSITIONS.human),
    ai: createPlayer(START_POSITIONS.ai),
    collectiveMoves: 0,
    gameOver: false,
    winner: null,
  };
}


function bothPlayersDone(state) {
  const humanDone =
    state.human.evacuated ||
    state.human.actions >= RULES.maxActions;

  const aiDone =
    state.ai.evacuated ||
    state.ai.actions >= RULES.maxActions;

  return humanDone && aiDone;
}


function resolveWinner(state) {
  if (state.ai.score > state.human.score) {
    return "ai";
  }

  if (state.human.score > state.ai.score) {
    return "human";
  }

  return "draw";
}


export default function MazeGame() {
  const [state, setState] = useState(freshState);
  const [telemetry, setTelemetry] = useState({});

  const [log, setLog] = useState([
    "Validated disaster grid generated. Human acts first.",
  ]);

  /*
   * IMPORTANT:
   * stateRef always contains the latest game state.
   *
   * This allows handleMove() and aiTurn() to read the current
   * state without putting side effects inside setState() updaters.
   */
  const stateRef = useRef(state);

  /*
   * Controls whether the human is currently allowed to act.
   *
   * false = Human turn
   * true  = AI thinking / AI turn
   */
  const aiThinking = useRef(false);

  const aiTimer = useRef(null);

  /*
   * Lets aiTurn schedule its own next turn without referring to itself
   * while it is still being defined.
   */
  const aiTurnRef = useRef(null);


  /*
   * Keep the state reference synchronized with React state.
   */
  useEffect(() => {
    stateRef.current = state;
  }, [state]);


  /*
   * Add an event to the event log.
   */
  const pushLog = useCallback((message) => {
    setLog((prev) => [message, ...prev].slice(0, 40));
  }, []);


  /*
   * Determine whether the game should finish.
   */
  const finishIfNeeded = useCallback(
    (next) => {
      if (bothPlayersDone(next)) {
        const winner = resolveWinner(next);

        pushLog(`Game over: ${winner.toUpperCase()}.`);

        return {
          ...next,
          gameOver: true,
          winner,
        };
      }

      /*
       * If one player reaches evacuation, that player stops acting.
       * The remaining player continues until reaching evacuation
       * or reaching the maximum action count.
       */
      return next;
    },
    [pushLog]
  );


  /*
   * Dynamic environment update.
   *
   * Runs after every required number of collective moves.
   */
  const performEnvironmentUpdate = useCallback(
    (next) => {
      /*
       * Dynamic changes require both players to still be active.
       * This keeps the timing rule well-defined after one player
       * has evacuated.
       */
      if (
        next.human.evacuated ||
        next.ai.evacuated ||
        next.collectiveMoves %
          RULES.environmentEveryCollectiveMoves !==
          0
      ) {
        return next;
      }

      const grid = reshuffleHazards(
        next.grid,
        [next.human.pos, next.ai.pos],
        RULES.initialHazards
      );

      pushLog("Environment shifted: hazards relocated.");

      return {
        ...next,
        grid,
      };
    },
    [pushLog]
  );


  /*
   * Civilian update.
   *
   * Completed rescues are cleared and new civilians can be placed
   * according to the board generator rules.
   */
  const performCivilianUpdate = useCallback(
    (next) => {
      if (
        next.human.evacuated ||
        next.ai.evacuated ||
        next.collectiveMoves %
          RULES.civiliansEveryCollectiveMoves !==
          0
      ) {
        return next;
      }

      const grid = updateCivilians(
        next.grid,
        next.human.rescued,
        next.ai.rescued
      );

      pushLog(
        "Civilian update: completed rescues cleared and new targets placed."
      );

      return {
        ...next,
        grid,
      };
    },
    [pushLog]
  );


  /*
   * ============================================================
   * AI TURN
   * ============================================================
   *
   * IMPORTANT:
   * There is NO setState(prev => ...) updater here.
   *
   * We read the latest state from stateRef, calculate the complete
   * AI result, then commit that result with setState().
   *
   * The aiThinking lock is released ONLY after the AI state has
   * been completely calculated and committed.
   */
  const aiTurn = useCallback(() => {
    const prev = stateRef.current;

    /*
     * Safety check.
     */
    if (prev.gameOver) {
      aiThinking.current = false;
      return;
    }


    /*
     * If AI has already finished, there is no AI action to perform.
     */
    if (
      prev.ai.evacuated ||
      prev.ai.actions >= RULES.maxActions
    ) {
      const done = finishIfNeeded(prev);

      stateRef.current = done;
      setState(done);

      aiThinking.current = false;

      return;
    }


    /*
     * Ask Minimax + Alpha-Beta for the AI decision.
     */
    const decision = decideAIAction(
      prev,
      RULES.minimaxDepth
    );


    /*
     * Clone the state before modifying it.
     *
     * This prevents mutation of the current state.
     */
    let next = {
      ...prev,

      human: {
        ...prev.human,
        pos: [...prev.human.pos],
        rescued: new Set(prev.human.rescued),
      },

      ai: {
        ...prev.ai,
        pos: [...prev.ai.pos],
        rescued: new Set(prev.ai.rescued),
      },
    };


    /*
     * Validate the AI-selected move.
     */
    const move = isMoveLegal(
      next.grid,
      next.ai.pos,
      decision.dir,
      next.ai.actions,
      next.ai.evacuated
    );


    /*
     * No legal AI move.
     */
    if (!move) {
      pushLog("AI had no legal strategic move.");

      const done = finishIfNeeded(next);

      stateRef.current = done;
      setState(done);

      /*
       * AI turn is now finished.
       */
      aiThinking.current = false;

      return;
    }


    /*
     * Apply the AI movement.
     */
    const cell = next.grid[move[0]][move[1]];

    next.ai.pos = move;
    next.ai.actions += 1;


    /*
     * Hazard scoring.
     */
    if (cell.type === "hazard") {
      next.ai.score += RULES.hazard;

      pushLog(
        `AI entered a hazard (${RULES.hazard}).`
      );
    }


    /*
     * Civilian rescue.
     */
    if (cell.type === "civilian") {
      const k = cellKey(move);

      if (!next.ai.rescued.has(k)) {
        next.ai.rescued.add(k);

        next.ai.score += RULES.rescue;

        pushLog(
          `AI rescued a civilian (+${RULES.rescue}).`
        );
      }
    }


    /*
     * Evacuation.
     */
    if (isEvacuationPosition(move)) {
      next.ai.evacuated = true;

      pushLog(
        "AI reached the evacuation point."
      );
    }


    /*
     * One human action + one AI action =
     * one collective move.
     */
    next.collectiveMoves += 1;


    /*
     * Dynamic environment update.
     */
    next = performEnvironmentUpdate(next);


    /*
     * Civilian update.
     */
    next = performCivilianUpdate(next);


    /*
     * Update AI telemetry.
     */
    setTelemetry({
      ...decision.route,
      depth: decision.depth,
      nodes: decision.nodes,
      pruned: decision.pruned,
      leaves: decision.leaves,
      action: decision.dir,
    });


    /*
     * Check whether the game has finished.
     */
    const done = finishIfNeeded(next);


    /*
     * Synchronize the ref immediately.
     *
     * This is important because React state updates are asynchronous.
     */
    stateRef.current = done;
    function humanDone(s) {
      return s.human.evacuated || s.human.actions >= RULES.maxActions;
    }

    /*
     * Commit the complete AI move.
     */
    setState(done);

    if (!done.gameOver && humanDone(done)){
      //Human can't act anymore
      aiThinking.current = true;
      aiTimer.current = setTimeout(() =>{
        aiTimer.current = null;
        aiTurnRef.current?.();
      },600);
    } else {
      aiThinking.current = false;
      aiTimer.current = null;
    }
  }, [
    finishIfNeeded,
    performCivilianUpdate,
    performEnvironmentUpdate,
    pushLog,
  ]);


  useEffect(() => {
    aiTurnRef.current = aiTurn;
  }, [aiTurn]);


  /*
   * ============================================================
   * HUMAN TURN
   * ============================================================
   *
   * IMPORTANT:
   * No state updater function is used here.
   *
   * We calculate the next state outside setState(), then commit it.
   * This keeps the function safe under React StrictMode.
   */
  const handleMove = useCallback(
    (dir) => {
      /*
       * If AI is thinking, ignore human input.
       */
      if (aiThinking.current) {
        return;
      }


      /*
       * Always read the latest state from the ref.
       */
      const prev = stateRef.current;

      /*
       * Game already finished.
       */
      if (prev.gameOver) {
        return;
      }


      /*
       * Human already evacuated.
       */
      if (prev.human.evacuated) {
        pushLog("Human has already evacuated.");
        return;
      }


      /*
       * Human action limit reached.
       */
      if (prev.human.actions >= RULES.maxActions) {
        pushLog("Human action limit reached.");

        const done = finishIfNeeded(prev);

        stateRef.current = done;
        setState(done);

        return;
      }


      /*
       * Validate human movement.
       */
      const move = isMoveLegal(
        prev.grid,
        prev.human.pos,
        dir,
        prev.human.actions,
        prev.human.evacuated
      );


      /*
       * Invalid movement.
       */
      if (!move) {
        pushLog(
          dir === "wait"
            ? "WAIT is only allowed at a safe point."
            : "Move blocked."
        );

        return;
      }


      /*
       * Clone the state and human player.
       */
      const next = {
        ...prev,

        human: {
          ...prev.human,
          pos: move,
          actions: prev.human.actions + 1,
          rescued: new Set(prev.human.rescued),
        },
      };


      /*
       * Get the destination cell.
       */
      const cell = prev.grid[move[0]][move[1]];


      /*
       * Hazard scoring.
       */
      if (cell.type === "hazard") {
        next.human.score += RULES.hazard;

        pushLog(
          `You entered a hazard (${RULES.hazard}).`
        );
      }


      /*
       * Civilian rescue.
       */
      if (cell.type === "civilian") {
        const k = cellKey(move);

        if (!next.human.rescued.has(k)) {
          next.human.rescued.add(k);

          next.human.score += RULES.rescue;

          pushLog(
            `You rescued a civilian (+${RULES.rescue}).`
          );
        }
      }


      /*
       * Evacuation.
       */
      if (isEvacuationPosition(move)) {
        next.human.evacuated = true;

        pushLog(
          "You reached the evacuation point."
        );
      }


      /*
       * Check whether the game has ended.
       *
       * If both players are done, AI does not need another turn.
       */
      const finished = finishIfNeeded(next);


      /*
       * Immediately synchronize the ref.
       */
      stateRef.current = finished;


      /*
       * Commit the human move.
       */
      setState(finished);


      /*
       * If the game ended, do not schedule AI.
       */
      if (finished.gameOver) {
        return;
      }


      /*
       * ========================================================
       * START AI TURN
       * ========================================================
       *
       * These are side effects, so they are intentionally OUTSIDE
       * setState().
       */

      aiThinking.current = true;


      /*
       * Clear any unexpected previous timer before creating
       * the new one.
       */
      if (aiTimer.current) {
        clearTimeout(aiTimer.current);
      }


      /*
       * Give the AI a small visible thinking delay.
       */
      aiTimer.current = setTimeout(() => {
        aiTimer.current = null;
        aiTurn();
      }, 600);
    },
    [aiTurn, finishIfNeeded, pushLog]
  );


  /*
   * ============================================================
   * CLEANUP
   * ============================================================
   */
  useEffect(() => {
    return () => {
      if (aiTimer.current) {
        clearTimeout(aiTimer.current);
        aiTimer.current = null;
      }

      aiThinking.current = false;
    };
  }, []);


  /*
   * ============================================================
   * KEYBOARD CONTROLS
   * ============================================================
   */
  useEffect(() => {
    const map = {
      ArrowUp: "up",
      ArrowDown: "down",
      ArrowLeft: "left",
      ArrowRight: "right",
      " ": "wait",
    };


    const onKeyDown = (event) => {
      const dir = map[event.key];

      if (!dir) {
        return;
      }

      event.preventDefault();

      handleMove(dir);
    };


    window.addEventListener("keydown", onKeyDown);


    return () => {
      window.removeEventListener("keydown", onKeyDown);
    };
  }, [handleMove]);


  /*
   * ============================================================
   * RESTART
   * ============================================================
   */
  const restart = useCallback(() => {
    /*
     * Cancel any pending AI action.
     */
    if (aiTimer.current) {
      clearTimeout(aiTimer.current);
      aiTimer.current = null;
    }


    /*
     * Unlock human controls.
     */
    aiThinking.current = false;


    /*
     * Generate completely fresh game state.
     */
    const fresh = freshState();


    /*
     * Synchronize the state ref immediately.
     */
    stateRef.current = fresh;


    /*
     * Commit new state.
     */
    setState(fresh);


    /*
     * Clear telemetry.
     */
    setTelemetry({});


    /*
     * Reset event log.
     */
    setLog([
      "Validated disaster grid generated. Human acts first.",
    ]);
  }, []);


  /*
   * ============================================================
   * GAME-OVER BANNER
   * ============================================================
   */
  const bannerText =
    !state.gameOver
      ? null
      : state.winner === "ai"
      ? `AI WINS — ${state.ai.score} to ${state.human.score}`
      : state.winner === "human"
      ? `HUMAN WINS — ${state.human.score} to ${state.ai.score}`
      : `DRAW — ${state.human.score} to ${state.ai.score}`;


  /*
   * ============================================================
   * RENDER
   * ============================================================
   */
  return (
    <div className="wrap">

      <header className="maze-header">
        <div className="maze-eyebrow">
          AION . AI GAME LAB
        </div>

        <h1>
          Disaster Rescue Strategy
        </h1>

        <p>
          BFS · A* · Heuristic Evaluation · Minimax + α-β
        </p>
      </header>


      {bannerText && (
        <div
          id="banner"
          role="status"
          className={`banner banner-${state.winner}`}
          style={{ display: "block" }}
        >
          {bannerText}

          <button
            type="button"
            onClick={restart}
            style={{ marginLeft: 10 }}
          >
            Play again
          </button>
        </div>
      )}


      <div className="layout">

        <div>
          <Board
            grid={state.grid}
            humanPos={state.human.pos}
            aiPos={state.ai.pos}
          />


          <div
            className="legend"
            style={{ marginTop: 10 }}
          >
            <span>
              <i className="sw sw-wall" />
              wall
            </span>

            <span>
              <i className="sw sw-hazard" />
              hazard (-2)
            </span>

            <span>
              <i className="sw sw-civilian" />
              civilian (+3)
            </span>

            <span>
              <i className="sw sw-safe" />
              safe point
            </span>

            <span>
              <i className="sw sw-evac" />
              evacuation
            </span>

            <span>
              <i className="sw sw-human" />
              you
            </span>

            <span>
              <i className="sw sw-ai" />
              AI
            </span>
          </div>
        </div>


        <div>

          <ScorePanel
            humanScore={state.human.score}
            aiScore={state.ai.score}
          />


          <Controls
            onMove={handleMove}
            disabled={state.gameOver}
          />


          <TelemetryPanel
            telemetry={telemetry}
            collectiveMoves={state.collectiveMoves}
          />


          <EventLog entries={log} />

        </div>

      </div>
    </div>
  );
}
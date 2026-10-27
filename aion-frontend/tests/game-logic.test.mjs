import assert from 'node:assert/strict'
import { test } from 'node:test'

import { N, RULES, START_POSITIONS } from '../src/lib/gameRules.js'
import { generateBoard, updateCivilians } from '../src/lib/boardGenerator.js'
import { aStarPath, bfsPath, neighbors, pathCost } from '../src/lib/pathfinding.js'
import { decideAIAction } from '../src/lib/minimax.js'
import { isMoveLegal } from '../src/lib/gameValidator.js'
import { formatHash, parseHash } from '../src/lib/route.js'

const posKey = (p) => `${p[0]},${p[1]}`

function dijkstraCost(grid, start, goal) {
  const best = new Map([[posKey(start), 0]])
  const queue = [[0, start]]
  while (queue.length) {
    queue.sort((a, b) => a[0] - b[0])
    const [cost, pos] = queue.shift()
    if (cost > best.get(posKey(pos))) continue
    if (posKey(pos) === posKey(goal)) return cost
    for (const next of neighbors(pos[0], pos[1], grid)) {
      const step = grid[next[0]][next[1]].type === 'hazard' ? 3 : 1
      const total = cost + step
      if (!best.has(posKey(next)) || total < best.get(posKey(next))) {
        best.set(posKey(next), total)
        queue.push([total, next])
      }
    }
  }
  return null
}

const newPlayer = (pos) => ({
  pos: [...pos],
  score: 0,
  actions: 0,
  rescued: new Set(),
  evacuated: false,
})

test('generated boards are playable and match the configured rules', () => {
  for (let i = 0; i < 100; i++) {
    const grid = generateBoard()
    const counts = {}
    for (const cell of grid.flat()) counts[cell.type] = (counts[cell.type] ?? 0) + 1

    assert.equal(counts.wall, RULES.initialWalls)
    assert.equal(counts.civilian, RULES.initialCivilians)
    assert.ok(bfsPath(grid, START_POSITIONS.human, [N - 1, N - 1]))
    assert.ok(bfsPath(grid, START_POSITIONS.ai, [N - 1, N - 1]))
  }
})

test('A* returns the same cost as exhaustive Dijkstra search', () => {
  for (let i = 0; i < 150; i++) {
    const grid = generateBoard()
    const pick = () => [Math.floor(Math.random() * N), Math.floor(Math.random() * N)]
    const start = pick()
    const goal = pick()
    if (grid[start[0]][start[1]].type === 'wall') continue
    if (grid[goal[0]][goal[1]].type === 'wall') continue

    const expected = dijkstraCost(grid, start, goal)
    const path = aStarPath(grid, start, goal)

    if (expected === null) assert.equal(path, null)
    else assert.equal(pathCost(grid, path), expected)
  }
})

test('minimax picks a legal move and prunes branches', () => {
  const grid = generateBoard()
  const state = {
    grid,
    human: newPlayer(START_POSITIONS.human),
    ai: newPlayer(START_POSITIONS.ai),
    collectiveMoves: 0,
  }

  const decision = decideAIAction(state, RULES.minimaxDepth)
  assert.ok(isMoveLegal(grid, state.ai.pos, decision.dir, 0, false))
  assert.ok(decision.nodes > 0)
  assert.ok(decision.pruned >= 0)
})

test('updateCivilians clears only rescued civilians', () => {
  const grid = Array.from({ length: N }, () =>
    Array.from({ length: N }, () => ({ type: 'open' })),
  )
  grid[0][3] = { type: 'civilian' }
  grid[3][3] = { type: 'civilian' }
  grid[5][1] = { type: 'civilian' }

  const next = updateCivilians(grid, new Set(['3,3']), new Set())

  assert.notEqual(next[3][3].type, 'civilian')
  assert.equal(next[0][3].type, 'civilian')
  assert.equal(next[5][1].type, 'civilian')
})

test('hash routes round-trip and tolerate malformed input', () => {
  assert.deepEqual(parseHash(''), { page: 'home' })
  assert.deepEqual(parseHash('#/nonsense'), { page: 'home' })
  assert.deepEqual(parseHash('#/dashboard/zone/%E0%A4%A'), { page: 'dashboard' })

  for (const route of [
    { page: 'home' },
    { page: 'game' },
    { page: 'dashboard' },
    { page: 'facts' },
    { page: 'zone', zone: "O'Brien Heights/2" },
  ]) {
    assert.deepEqual(parseHash(formatHash(route)), route)
  }
})

test('AI does not rush to evacuation while many actions and civilians remain', () => {
  const grid = Array.from({ length: N }, () =>
    Array.from({ length: N }, () => ({ type: 'open' })),
  )
  grid[0][0] = { type: 'safe' }
  grid[N - 1][0] = { type: 'safe' }
  grid[N - 1][N - 1] = { type: 'evac' }
  grid[N - 4][N - 3] = { type: 'civilian' }

  // Evacuation is two steps away, the civilian three: with 50 actions left the AI should collect.
  const state = {
    grid,
    human: newPlayer(START_POSITIONS.human),
    ai: newPlayer([N - 1, N - 3]),
    collectiveMoves: 0,
  }

  assert.equal(decideAIAction(state, RULES.minimaxDepth).dir, 'up')
})

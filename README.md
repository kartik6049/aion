# AION Decision & Strategy Lab

Two modules behind one React front end:

* **Emergency Response** – a Prolog expert system ranks disaster zones and allocates
  ambulances, hospitals and shelters, with a rule trace explaining each decision.
* **AI Game Lab** – a rescue game whose AI uses BFS, A*, a heuristic evaluation and
  minimax with alpha-beta pruning (runs entirely in the browser).

## Architecture

```
aion-frontend/  React + Vite UI
  src/pages/        Home, Dashboard, ZoneDetails, GameLab / MazeGame
  src/components/   Header, ZoneCard, RoutePath, StatusMessage, game panels
  src/hooks/        useHashRoute (deep links, back button), useAsync (cancelable loads)
  src/services/     api.js – typed errors, timeout, cancellation
  src/lib/          game engine (rules, pathfinding, minimax) + route/format helpers

expert_system/  Prolog engine + Python bridge
  facts.pl            scenario data (zones, roads, hospitals, shelters, ambulances)
  rules.pl            scoring and classification rules (risk, medical priority, evacuation)
  search.pl           road graph, BFS, route cost/risk
  astar.pl            A* with Manhattan heuristic
  resource_engine.pl  ambulance / hospital / shelter selection
  decision_engine.pl  per-zone decision and priority score
  explanation.pl      rule-trace data
  response_planner.pl city-wide plan: ordering, metrics
  aion_controller.pl  entry points; Prolog terms -> JSON
  prolog_bridge.py    runs swipl, parses JSON, caches until a .pl file changes
  app.py              FastAPI routes (thin)
  tests/test_aion.pl  Prolog regression tests
  test_bridge.py      bridge/API tests
```

Each `.pl` file loads its dependencies with `ensure_loaded`, so every file is read once.

## Run

```bash
# Backend (needs SWI-Prolog 9+ on PATH)
cd expert_system
python -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
uvicorn app:app --port 8000

# Frontend
cd aion-frontend
cp .env.example .env     # optional
npm install
npm run dev
```

Environment variables: `SWIPL_PATH`, `AION_PROLOG_TIMEOUT` (seconds, default 30),
`AION_CORS_ORIGINS` (comma-separated), `VITE_API_BASE_URL`.

## Deploy

* **API** – build `expert_system/Dockerfile` and run it on any container host (Render, Fly.io,
  Railway). Set `AION_CORS_ORIGINS` to the exact URL of the deployed frontend. Check
  `GET /api/health` after deploying.
* **Frontend** – set `VITE_API_BASE_URL` to the API's public HTTPS URL, run `npm run build`, and
  publish `aion-frontend/dist` on any static host (Vercel, Netlify, Cloudflare Pages). Hash
  routing needs no rewrite rules. `VITE_*` values are baked in at build time, so rebuild when the
  API URL changes.

The image installs SWI-Prolog from Debian's package; the tests in this repo were run against
SWI-Prolog 9.2.9, so run the Prolog tests inside the image once (`swipl -q -g run_tests -t halt tests/test_aion.pl`
needs the `tests` folder, which the image leaves out).

## Test

```bash
cd expert_system
swipl -q -g run_tests -t halt tests/test_aion.pl   # Prolog rules, search, JSON
python -m unittest -v test_bridge                  # bridge (+ HTTP when fastapi is installed)

cd ../aion-frontend
npm test                                           # game logic and routing helpers
npm run lint && npm run build
```

## API

| Route | Result |
| --- | --- |
| `GET /api/health` | engine reachable |
| `GET /api/plan` | compact plan, one entry per zone, highest priority first |
| `GET /api/zone/{zone}` | decision + explanation for one zone (404 unknown, 400 invalid name) |
| `GET /api/system` | disaster, metrics, shortages, resource inventory |
| `GET /api/resources` | per-zone allocation overview |

Engine failures return `503` with a generic message; details go to the server log.

**Contract change:** in `explanation.resources.hospital` and `.shelter` several keys were
named for something other than the value they carried. They now match the data:
`supported_zones`→`route`, `distance`→`cost`, `emergency_capacity`→`available_capacity`,
`total_capacity`→`capacity`, `current_patients`→`patients`, `location`/`destination`→
`zone`/`hospital_zone` (`shelter_zone`), `current_occupancy`→`people`,
`food_support`→`family_friendly`, `water_support`→`accessibility_support`;
`explanation.resources.ambulance.location`→`zone`. The UI did not use these fields.

## Allocation

`decision_engine.pl` allocates zones once per run, in descending priority score. Each zone's
ambulance, hospital beds and shelter places are committed before the next zone is considered,
so a resource is never assigned beyond its capacity (an ambulance serves one zone). A zone left
without a resource is reported as a shortage. Hospital and shelter figures in a decision show the
space that was free when that zone was assigned.

## Known limitations

* `operator_override` is honoured for the final action only; ambulance overrides are not wired in.
* Shelter capacity is not tied to a zone: any shelter reachable by road may be used.

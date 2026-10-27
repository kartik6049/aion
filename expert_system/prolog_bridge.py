"""Bridge between the API layer and the SWI-Prolog reasoning engine.

Every call starts `swipl`, loads aion_controller.pl, runs one controller
predicate and parses the JSON it prints on stdout. The engine's facts are
static, so results are cached until a .pl file changes on disk.

Details of failures (stderr, file paths) are logged here and are never put
in the exception messages that the API returns to clients.
"""

import json
import logging
import os
import re
import subprocess
import threading
from pathlib import Path
from typing import Any, Dict, Tuple

logger = logging.getLogger("aion.prolog")

ENGINE_DIR = Path(__file__).resolve().parent
CONTROLLER = ENGINE_DIR / "aion_controller.pl"
SWIPL = os.environ.get("SWIPL_PATH", "swipl")
TIMEOUT_SECONDS = float(os.environ.get("AION_PROLOG_TIMEOUT", "30"))
MAX_CACHE_ENTRIES = 64

# Zone names are ASCII words separated by spaces, hyphens or underscores.
_ZONE_PATTERN = re.compile(r"^[A-Za-z0-9][A-Za-z0-9 _-]{0,63}$")


class PrologError(RuntimeError):
    """The engine failed. The message is safe to show to API clients."""


class InvalidZoneName(ValueError):
    """The zone name cannot be passed to Prolog safely."""


class ZoneNotFound(LookupError):
    """The engine does not know the requested zone."""


_cache: Dict[Tuple[str, float], Any] = {}
_lock = threading.Lock()


def _engine_fingerprint() -> float:
    """Newest modification time of any engine source file."""
    return max(path.stat().st_mtime for path in ENGINE_DIR.glob("*.pl"))


def _execute(goal: str) -> Any:
    command = [
        SWIPL,
        "-q",
        "-s",
        str(CONTROLLER),
        "-g",
        goal,
        "-t",
        "halt",
    ]

    try:
        result = subprocess.run(
            command,
            cwd=ENGINE_DIR,
            capture_output=True,
            text=True,
            encoding="utf-8",
            timeout=TIMEOUT_SECONDS,
        )
    except FileNotFoundError as exc:
        logger.error("SWI-Prolog executable %r not found", SWIPL)
        raise PrologError("The reasoning engine is not installed.") from exc
    except subprocess.TimeoutExpired as exc:
        logger.error("Prolog goal %r timed out after %ss", goal, TIMEOUT_SECONDS)
        raise PrologError("The reasoning engine timed out.") from exc

    if result.returncode != 0:
        logger.error(
            "Prolog goal %r exited with %s: %s",
            goal,
            result.returncode,
            result.stderr.strip(),
        )
        raise PrologError("The reasoning engine failed to produce a result.")

    output = result.stdout.strip()
    if not output:
        logger.error("Prolog goal %r produced no output: %s", goal, result.stderr.strip())
        raise PrologError("The reasoning engine returned no data.")

    try:
        return json.loads(output)
    except json.JSONDecodeError as exc:
        logger.error("Prolog goal %r produced invalid JSON: %.500s", goal, output)
        raise PrologError("The reasoning engine returned invalid data.") from exc


def run_goal(goal: str) -> Any:
    """Run a controller goal, using the cache while the sources are unchanged."""
    try:
        key = (goal, _engine_fingerprint())
    except (OSError, ValueError) as exc:  # missing sources
        logger.error("Cannot read engine sources in %s", ENGINE_DIR)
        raise PrologError("The reasoning engine sources are unavailable.") from exc

    with _lock:
        if key in _cache:
            return _cache[key]

        data = _execute(goal)

        if len(_cache) >= MAX_CACHE_ENTRIES:
            _cache.clear()
        _cache[key] = data
        return data


def clear_cache() -> None:
    with _lock:
        _cache.clear()


def get_plan() -> Any:
    return run_goal("aion_json_result")


def get_system() -> Any:
    return run_goal("aion_system_json")


def get_facts() -> Any:
    return run_goal("aion_facts_json")


def get_health() -> Any:
    return run_goal("aion_health_check")


def get_zone(zone: str) -> Any:
    if not _ZONE_PATTERN.match(zone):
        raise InvalidZoneName(zone)

    quoted = zone.replace("\\", "\\\\").replace("'", "\\'")
    data = run_goal(f"aion_zone_response('{quoted}')")

    if isinstance(data, dict) and data.get("error") == "zone_not_found":
        raise ZoneNotFound(zone)

    return data

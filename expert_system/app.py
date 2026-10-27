import logging
import os
from typing import Any, Dict, List

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware

import prolog_bridge as engine

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("aion.api")

API_VERSION = "2.1.0"

app = FastAPI(
    title="AION API",
    description="AI Emergency Response Decision System API",
    version=API_VERSION,
)

# Comma-separated list, e.g. AION_CORS_ORIGINS="https://aion.example.org"
DEFAULT_ORIGINS = "http://localhost:5173,http://127.0.0.1:5173"
allowed_origins: List[str] = [
    origin.strip()
    for origin in os.environ.get("AION_CORS_ORIGINS", DEFAULT_ORIGINS).split(",")
    if origin.strip()
]

app.add_middleware(
    CORSMiddleware,
    allow_origins=allowed_origins,
    allow_methods=["GET"],
    allow_headers=["*"],
)


def call_engine(operation):
    """Run an engine operation, translating engine failures to HTTP 5xx."""
    try:
        return operation()
    except engine.PrologError as exc:
        # The detailed cause is already logged by the bridge.
        raise HTTPException(status_code=503, detail=str(exc))


def compact_zone(zone_data: Dict[str, Any]) -> Dict[str, Any]:
    """Reduce a detailed zone response to what the dashboard list needs."""
    decision = zone_data.get("decision", {})

    return {
        "zone": zone_data.get("zone"),
        "risk": decision.get("risk", {}),
        "medical": decision.get("medical"),
        "evacuation": decision.get("evacuation"),
        "priority_score": decision.get("priority_score"),
        "action": decision.get("action"),
        "resources": decision.get("resources", {}),
    }


def zone_entries(full_plan: Dict[str, Any]) -> List[Dict[str, Any]]:
    return [zone for zone in full_plan.get("plan", []) if isinstance(zone, dict)]


@app.get("/")
def root():
    return {
        "system": "AION",
        "name": "AI Emergency Response Decision System",
        "status": "active",
        "version": API_VERSION,
    }


@app.get("/api/health")
def health_check():
    try:
        engine.get_health()
    except engine.PrologError as exc:
        return {
            "status": "degraded",
            "prolog": "unavailable",
            "aion": "error",
            "message": str(exc),
        }

    return {"status": "healthy", "prolog": "connected", "aion": "operational"}


@app.get("/api/plan")
def get_plan():
    zones = [compact_zone(zone) for zone in zone_entries(call_engine(engine.get_plan))]
    return {"plan": zones, "total_zones": len(zones)}


@app.get("/api/zone/{zone}")
def get_zone(zone: str):
    try:
        return call_engine(lambda: engine.get_zone(zone))
    except engine.InvalidZoneName:
        raise HTTPException(status_code=400, detail="Invalid zone name.")
    except engine.ZoneNotFound:
        raise HTTPException(status_code=404, detail=f"Zone '{zone}' not found.")


@app.get("/api/system")
def get_system():
    return call_engine(engine.get_system)


@app.get("/api/facts")
def get_facts():
    return call_engine(engine.get_facts)


@app.get("/api/resources")
def get_resources():
    resources = []

    for zone in zone_entries(call_engine(engine.get_plan)):
        decision = zone.get("decision", {})
        resources.append(
            {
                "zone": zone.get("zone"),
                "ambulance": decision.get("ambulance"),
                "hospital": decision.get("hospital"),
                "shelter": decision.get("shelter"),
                "resource_status": decision.get("resources"),
            }
        )

    return {"resources": resources, "total_zones": len(resources)}

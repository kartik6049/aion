"""Integration tests for the Python <-> Prolog bridge and the API handlers.

Run from the expert_system directory (needs `swipl` on PATH):
    python -m unittest -v test_bridge

The HTTP-level tests run only when FastAPI is installed.
"""

import shutil
import unittest

import prolog_bridge as engine

HAVE_SWIPL = shutil.which(engine.SWIPL) is not None

try:
    from fastapi.testclient import TestClient

    import app as api_module

    HAVE_FASTAPI = True
except ImportError:
    HAVE_FASTAPI = False


@unittest.skipUnless(HAVE_SWIPL, "swipl is not installed")
class BridgeTests(unittest.TestCase):
    def setUp(self):
        engine.clear_cache()

    def test_plan_lists_every_zone_in_priority_order(self):
        zones = engine.get_plan()["plan"]
        self.assertEqual(len(zones), 10)
        scores = [z["decision"]["priority_score"] for z in zones]
        self.assertEqual(scores, sorted(scores, reverse=True))

    def test_system_summary_matches_plan(self):
        system = engine.get_system()
        self.assertEqual(system["metrics"]["total_zones"], 10)
        self.assertEqual(system["priority_order"][0], engine.get_plan()["plan"][0]["zone"])

    def test_zone_detail_includes_explanation(self):
        data = engine.get_zone("Midtown")
        self.assertEqual(data["zone"], "Midtown")
        self.assertIn("reasoning", data["explanation"])

    def test_facts_cover_every_zone_and_resource(self):
        facts = engine.get_facts()
        plan_zones = [z["zone"] for z in engine.get_plan()["plan"]]
        self.assertEqual(sorted(z["zone"] for z in facts["zones"]), sorted(plan_zones))
        for key in ("hospitals", "shelters", "ambulances", "roads"):
            self.assertTrue(facts[key], key)
        for zone in facts["zones"]:
            self.assertNotIn(None, zone.values(), zone["zone"])
        # every facts value the plan reports must match the stored fact
        midtown = engine.get_zone("Midtown")["explanation"]["reasoning"]
        stored = next(z for z in facts["zones"] if z["zone"] == "Midtown")
        self.assertEqual(midtown["medical"]["critical_cases"], stored["critical_cases"])
        self.assertEqual(midtown["evacuation"]["people"], stored["evacuation_population"])

    def test_unknown_zone_raises_zone_not_found(self):
        with self.assertRaises(engine.ZoneNotFound):
            engine.get_zone("Atlantis")

    def test_hostile_zone_names_are_rejected_before_reaching_prolog(self):
        for name in ["", "x'); halt. %", "Mid\ntown", "a" * 65, "Zöne", "../etc"]:
            with self.subTest(name=name):
                with self.assertRaises(engine.InvalidZoneName):
                    engine.get_zone(name)

    def test_results_are_cached_until_sources_change(self):
        first = engine.get_plan()
        self.assertIs(engine.get_plan(), first)

    def test_missing_swipl_is_reported_without_internal_details(self):
        original = engine.SWIPL
        engine.SWIPL = "swipl-does-not-exist"
        engine.clear_cache()
        try:
            with self.assertRaises(engine.PrologError) as ctx:
                engine.get_plan()
            self.assertNotIn("swipl-does-not-exist", str(ctx.exception))
        finally:
            engine.SWIPL = original
            engine.clear_cache()


@unittest.skipUnless(HAVE_SWIPL and HAVE_FASTAPI, "swipl and fastapi are required")
class ApiTests(unittest.TestCase):
    def setUp(self):
        engine.clear_cache()
        self.client = TestClient(api_module.app)

    def test_health(self):
        self.assertEqual(self.client.get("/api/health").json()["status"], "healthy")

    def test_plan_is_compact(self):
        body = self.client.get("/api/plan").json()
        self.assertEqual(body["total_zones"], 10)
        self.assertNotIn("explanation", body["plan"][0])
        self.assertIn("priority_score", body["plan"][0])

    def test_facts_endpoint(self):
        body = self.client.get("/api/facts").json()
        self.assertEqual(len(body["zones"]), 10)
        self.assertIn("roads", body)

    def test_zone_status_codes(self):
        self.assertEqual(self.client.get("/api/zone/Midtown").status_code, 200)
        self.assertEqual(self.client.get("/api/zone/Atlantis").status_code, 404)
        self.assertEqual(self.client.get("/api/zone/bad%27name").status_code, 400)

    def test_errors_do_not_leak_internals(self):
        original = engine.SWIPL
        engine.SWIPL = "swipl-does-not-exist"
        engine.clear_cache()
        try:
            response = self.client.get("/api/plan")
            self.assertEqual(response.status_code, 503)
            self.assertNotIn("swipl-does-not-exist", response.text)
        finally:
            engine.SWIPL = original
            engine.clear_cache()


if __name__ == "__main__":
    unittest.main()

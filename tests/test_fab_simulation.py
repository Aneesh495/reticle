"""
Integration tests: End-to-end multi-cycle cleanroom fab digital twin simulation.
"""

import unittest
import sys
import os

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "python")))

from reticle.fab_twin import CleanroomFabTwin
from reticle.telemetry import TelemetryPublisher


class TestFabSimulation(unittest.TestCase):
    def test_long_run_simulation(self) -> None:
        twin = CleanroomFabTwin(seed=999)
        pub = TelemetryPublisher(twin)

        # Execute 500 simulation steps
        for step_idx in range(500):
            twin.step(dt=0.5)

        metrics = twin.get_summary_metrics()
        self.assertAlmostEqual(metrics["sim_time_sec"], 250.0, places=1)
        self.assertGreater(metrics["completed_transport_jobs"], 0)
        self.assertGreater(metrics["total_wafers_processed"], 0)
        self.assertGreater(metrics["tool_utilization_percent"], 0.0)

        # Check telemetry snapshot export
        snapshot = pub.generate_snapshot()
        self.assertIn("metrics", snapshot)
        self.assertIn("tools", snapshot)
        self.assertIn("vehicles", snapshot)
        self.assertEqual(len(snapshot["tools"]), 24)
        self.assertEqual(len(snapshot["vehicles"]), 20)


if __name__ == "__main__":
    unittest.main()

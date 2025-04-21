"""
Unit tests for AMHS monorail track routing, vehicle kinematics, and job dispatching.
"""

import unittest
import sys
import os

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "python")))

from reticle.fab_twin import CleanroomFabTwin, TransportJob


class TestOHTRouting(unittest.TestCase):
    def setUp(self) -> None:
        self.twin = CleanroomFabTwin(seed=789)

    def test_fleet_initialization(self) -> None:
        self.assertEqual(len(self.twin.vehicles), 20)
        for v in self.twin.vehicles:
            self.assertEqual(v.state, "IDLE")
            self.assertGreater(v.battery_soc, 90.0)

    def test_job_dispatch_lifecycle(self) -> None:
        job = TransportJob(
            job_id=9001,
            carrier_id="FOUP-010",
            from_node=17,
            to_node=101,
            priority=80,
        )
        self.twin.jobs.append(job)
        self.assertEqual(job.status, "PENDING")

        # Step simulation to trigger dispatch matching
        self.twin.step(dt=1.0)

        # Job should be matched and vehicle dispatched
        self.assertIn(job.status, ("ASSIGNED", "COMPLETED"))
        assigned_veh = None
        for v in self.twin.vehicles:
            if v.assigned_job_id == 9001:
                assigned_veh = v
                break

        if job.status == "ASSIGNED":
            self.assertIsNotNone(assigned_veh)

    def test_battery_depletion(self) -> None:
        initial_soc = self.twin.vehicles[0].battery_soc
        # Step simulation 100 seconds
        for _ in range(200):
            self.twin.step(dt=0.5)

        avg_battery = sum(v.battery_soc for v in self.twin.vehicles) / len(self.twin.vehicles)
        self.assertLess(avg_battery, initial_soc)


if __name__ == "__main__":
    unittest.main()

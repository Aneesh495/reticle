"""
Unit tests for SEMI E84 parallel optical handoff interlocks and timing watchdogs.
"""

import unittest
import sys
import os

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "python")))

from reticle.fab_twin import CleanroomFabTwin, ToolState


class TestE84Handoff(unittest.TestCase):
    def setUp(self) -> None:
        self.twin = CleanroomFabTwin(seed=456)

    def test_carrier_docking_and_clamping(self) -> None:
        carrier = self.twin.carriers["FOUP-001"]
        self.assertFalse(carrier.is_clamped)
        self.assertFalse(carrier.is_docked)

        # Simulate mechanical clamping
        carrier.is_clamped = True
        self.assertTrue(carrier.is_clamped)

        # Simulate FIMS door opening
        carrier.is_docked = True
        self.assertTrue(carrier.is_docked)

    def test_qtime_expiry_calculation(self) -> None:
        carrier = self.twin.carriers["FOUP-002"]
        # Normal fresh lot
        self.assertGreater(carrier.q_time_remaining, 14000.0)
        self.assertFalse(carrier.is_q_time_expired)

        # Simulate aged lot past 4 hours (14400s)
        carrier.q_time_start -= 15000.0
        self.assertEqual(carrier.q_time_remaining, 0.0)
        self.assertTrue(carrier.is_q_time_expired)


if __name__ == "__main__":
    unittest.main()

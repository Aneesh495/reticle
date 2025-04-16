"""
Unit tests for SEMI E30 GEM state models, variables, collection events, and alarms.
"""

import unittest
import sys
import os

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "python")))

from reticle.fab_twin import CleanroomFabTwin, ToolState, ToolType


class TestGEMStates(unittest.TestCase):
    def setUp(self) -> None:
        self.twin = CleanroomFabTwin(seed=123)

    def test_equipment_tool_catalog(self) -> None:
        self.assertEqual(len(self.twin.tools), 24)
        # 12 litho scanners + 8 etchers + 4 CVD chambers
        litho_count = sum(1 for t in self.twin.tools.values() if t.tool_type == ToolType.LITHO_SCANNER)
        etch_count = sum(1 for t in self.twin.tools.values() if t.tool_type == ToolType.PLASMA_ETCH)
        cvd_count = sum(1 for t in self.twin.tools.values() if t.tool_type == ToolType.CVD_CHAMBER)

        self.assertEqual(litho_count, 12)
        self.assertEqual(etch_count, 8)
        self.assertEqual(cvd_count, 4)

    def test_processing_state_advancement(self) -> None:
        scanner = self.twin.tools["SCANNER-01"]
        self.assertEqual(scanner.state, ToolState.IDLE)

        # Assign carrier and start processing
        scanner.current_carrier_id = "FOUP-TEST"
        scanner.state = ToolState.PROCESSING
        scanner.process_duration = 10.0

        # Step 5 seconds
        self.twin.step(dt=5.0)
        self.assertEqual(scanner.state, ToolState.PROCESSING)
        self.assertAlmostEqual(scanner.process_progress, 5.0, places=1)

        # Step another 6 seconds (total 11s > 10s)
        self.twin.step(dt=6.0)
        # Completes processing, transitions to UNLOADING then IDLE on next tick
        self.assertIn(scanner.state, (ToolState.UNLOADING, ToolState.IDLE))
        self.assertEqual(scanner.wafers_processed, 25)

    def test_alarm_logging(self) -> None:
        self.assertEqual(len(self.twin.alarm_log), 0)
        self.twin.post_alarm("CRITICAL", "ArF Laser Pulse Energy Instability")
        self.assertEqual(len(self.twin.alarm_log), 1)
        self.assertEqual(self.twin.alarm_log[0][1], "CRITICAL")


if __name__ == "__main__":
    unittest.main()

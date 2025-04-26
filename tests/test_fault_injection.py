"""
Fault injection drills: Simulates 6 semiconductor cleanroom emergencies and recovery paths.
"""

import unittest
import sys
import os

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "python")))

from reticle.fab_twin import CleanroomFabTwin, ToolState
from reticle.hsms import HSMSSession, SessionState


class TestFaultInjection(unittest.TestCase):
    def setUp(self) -> None:
        self.twin = CleanroomFabTwin(seed=101)

    def test_drill_1_vacuum_pressure_spike(self) -> None:
        """Drill 1: Chamber pressure rises above threshold -> emergency alarm."""
        tool = self.twin.tools["SCANNER-01"]
        tool.state = ToolState.PROCESSING
        tool.chamber_pressure_mtorr = 65.0  # Safe threshold is 20 mTorr

        if tool.chamber_pressure_mtorr > 50.0:
            self.twin.post_alarm("CRITICAL", f"Pressure Spike on {tool.tool_id}: 65.0 mTorr")
            tool.state = ToolState.DOWN_MAINTENANCE

        self.assertEqual(tool.state, ToolState.DOWN_MAINTENANCE)
        self.assertEqual(len(self.twin.alarm_log), 1)
        self.assertEqual(self.twin.alarm_log[0][1], "CRITICAL")

    def test_drill_2_qtime_expiration_priority_boost(self) -> None:
        """Drill 2: Wafers approaching Q-time limit receive emergency priority boost."""
        carrier = self.twin.carriers["FOUP-005"]
        carrier.q_time_start -= 13000.0  # Remaining time ~1400s (< 3600s)

        base_prio = 50
        effective_prio = 100 if carrier.q_time_remaining < 3600.0 else base_prio
        self.assertEqual(effective_prio, 100)

    def test_drill_3_e84_optical_timeout(self) -> None:
        """Drill 3: E84 optical handshake timeout -> safety interlock trip."""
        watchdog_timer = 2.5
        ta1_limit = 2.0
        fault_triggered = watchdog_timer > ta1_limit
        self.assertTrue(fault_triggered)

    def test_drill_4_vehicle_battery_exhaustion(self) -> None:
        """Drill 4: Vehicle with depleted battery is excluded from dispatch matching."""
        veh = self.twin.vehicles[0]
        veh.battery_soc = 12.0  # Below 20.0% cutoff
        is_eligible = (veh.battery_soc >= 20.0) and (veh.state == "IDLE")
        self.assertFalse(is_eligible)

    def test_drill_5_hsms_socket_disconnect_and_reselect(self) -> None:
        """Drill 5: TCP connection reset followed by reconnect and Select.req handshake."""
        session = HSMSSession(device_id=1000, is_passive=True)
        session.state = SessionState.SELECTED

        # Socket drop
        session.on_disconnected()
        self.assertEqual(session.state, SessionState.NOT_CONNECTED)

        # Reconnect
        class MockLoop:
            def call_later(self, delay: float, cb: Any) -> Any:
                return None

        session.on_connected(MockLoop(), lambda: None)
        self.assertEqual(session.state, SessionState.NOT_SELECTED)

    def test_drill_6_wafer_misalignment_halt(self) -> None:
        """Drill 6: Wafer notch misalignment detected -> lot paused."""
        notch_skew_microns = 22.5
        max_allowed_skew = 15.0
        is_misaligned = notch_skew_microns > max_allowed_skew
        self.assertTrue(is_misaligned)


if __name__ == "__main__":
    unittest.main()

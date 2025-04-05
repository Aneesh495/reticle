"""
Reticle Real-Time Telemetry Server & Event Streaming Engine.

Exports live semiconductor equipment sensor telemetry, OHT vehicle telemetry,
SECS/GEM event records, and fab throughput KPIs.
"""

from __future__ import annotations

import json
import time
from dataclasses import asdict
from typing import Any, Dict, List, Optional
from reticle.fab_twin import CleanroomFabTwin


class TelemetryPublisher:
    """Publishes structured cleanroom telemetry frames for monitoring and visualization."""

    def __init__(self, fab_twin: CleanroomFabTwin) -> None:
        self.twin = fab_twin
        self.sequence_number = 0

    def generate_snapshot(self) -> Dict[str, Any]:
        """Captures a comprehensive cleanroom telemetry snapshot."""
        self.sequence_number += 1
        metrics = self.twin.get_summary_metrics()

        tool_snapshots = [
            {
                "tool_id": t.tool_id,
                "type": t.tool_type.value,
                "bay": t.bay_name,
                "state": t.state.value,
                "carrier": t.current_carrier_id,
                "recipe": t.current_recipe,
                "progress_pct": round((t.process_progress / max(1.0, t.process_duration)) * 100, 1),
                "pressure_mtorr": round(t.chamber_pressure_mtorr, 2),
                "temp_c": round(t.chuck_temp_celsius, 2),
                "wafers_done": t.wafers_processed,
            }
            for t in self.twin.tools.values()
        ]

        vehicle_snapshots = [
            {
                "vehicle_id": v.vehicle_id,
                "node": v.current_node,
                "state": v.state,
                "foup": v.carried_foup_id,
                "speed_mps": round(v.speed_mps, 2),
                "battery_pct": round(v.battery_soc, 1),
            }
            for v in self.twin.vehicles
        ]

        return {
            "timestamp": time.time(),
            "sequence": self.sequence_number,
            "metrics": metrics,
            "tools": tool_snapshots,
            "vehicles": vehicle_snapshots,
            "recent_alarms": self.twin.alarm_log[-5:],
        }

    def export_json(self) -> str:
        """Serializes current snapshot to JSON string."""
        return json.dumps(self.generate_snapshot(), indent=2)

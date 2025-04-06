"""
Reticle Interactive ANSI Terminal Primary Flight Display / Fab HUD.

Renders real-time cleanroom status, equipment bay matrices, vehicle speeds,
furnace Q-time gauges, and SECS/GEM communications health in terminal console.
"""

from __future__ import annotations

import os
import sys
from typing import Dict, Any
from reticle.fab_twin import CleanroomFabTwin, ToolState


class FabDashboard:
    """Renders ANSI formatted cleanroom status display."""

    @staticmethod
    def render(twin: CleanroomFabTwin) -> str:
        metrics = twin.get_summary_metrics()

        lines = [
            "\033[1;36m========================================================================================\033[0m",
            "\033[1;37m RETICLE CLEANROOM STATUS DISPLAY | 300MM WAFER FAB & AMHS FLEET TELEMETRY           \033[0m",
            "\033[1;36m========================================================================================\033[0m",
            f" Sim Time: \033[1;33m{metrics['sim_time_sec']:>7.1f}s\033[0m | "
            f"Tools: \033[1;32m{metrics['active_processing_tools']:>2d}/{metrics['total_tools']:<2d} ({metrics['tool_utilization_percent']:>5.1f}%)\033[0m | "
            f"Fleet: \033[1;32m{metrics['moving_vehicles']:>2d}/{metrics['total_vehicles']:<2d} ({metrics['fleet_utilization_percent']:>5.1f}%)\033[0m | "
            f"Wafers: \033[1;35m{metrics['total_wafers_processed']:>6d}\033[0m",
            "----------------------------------------------------------------------------------------",
            "\033[1;34m[EQUIPMENT BAYS & CHAMBER STATUS]\033[0m",
        ]

        # Bay 1: Photolithography immersion scanners
        litho_tools = [t for t in twin.tools.values() if t.bay_name == "LITHO-BAY"]
        litho_status_parts = []
        for t in litho_tools[:6]:
            color = "\033[1;32m" if t.state == ToolState.PROCESSING else "\033[0;37m"
            state_abbr = "BUSY" if t.state == ToolState.PROCESSING else "IDLE"
            litho_status_parts.append(f"{t.tool_id[-3:]}:{color}{state_abbr}\033[0m")
        lines.append("  Litho Immersion Bay: " + " | ".join(litho_status_parts))

        # Bay 2: Plasma etch tools
        etch_tools = [t for t in twin.tools.values() if t.bay_name == "ETCH-BAY"]
        etch_status_parts = []
        for t in etch_tools[:6]:
            color = "\033[1;32m" if t.state == ToolState.PROCESSING else "\033[0;37m"
            state_abbr = "BUSY" if t.state == ToolState.PROCESSING else "IDLE"
            etch_status_parts.append(f"{t.tool_id[-3:]}:{color}{state_abbr}\033[0m")
        lines.append("  Plasma Etch Bay:     " + " | ".join(etch_status_parts))

        # Bay 3: CVD chambers
        cvd_tools = [t for t in twin.tools.values() if t.bay_name == "CVD-BAY"]
        cvd_status_parts = []
        for t in cvd_tools:
            color = "\033[1;32m" if t.state == ToolState.PROCESSING else "\033[0;37m"
            state_abbr = "BUSY" if t.state == ToolState.PROCESSING else "IDLE"
            cvd_status_parts.append(f"{t.tool_id[-3:]}:{color}{state_abbr}\033[0m")
        lines.append("  Chemical Vapor Bay:  " + " | ".join(cvd_status_parts))

        lines.extend([
            "----------------------------------------------------------------------------------------",
            "\033[1;34m[OVERHEAD HOIST TRANSPORT (OHT) FLEET DISPATCH]\033[0m",
        ])

        veh_parts = []
        for v in twin.vehicles[:10]:
            v_color = "\033[1;33m" if v.state.startswith("TRAVEL") else "\033[0;37m"
            veh_parts.append(f"V{v.vehicle_id:02d}:N{v.current_node:<3d}{v_color}[{v.state[:6]}]\033[0m")
        lines.append("  " + " ".join(veh_parts[:5]))
        lines.append("  " + " ".join(veh_parts[5:10]))

        lines.extend([
            "----------------------------------------------------------------------------------------",
            f" Completed Transport Missions: \033[1;32m{metrics['completed_transport_jobs']:<5d}\033[0m | "
            f"Average Vehicle Battery SoC: \033[1;32m{metrics['average_battery_soc']:>5.1f}%\033[0m | "
            f"Active Alarms: \033[1;32m{len(twin.alarm_log):<2d}\033[0m",
            "\033[1;36m========================================================================================\033[0m",
        ])

        return "\n".join(lines)

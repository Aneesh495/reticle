"""
Reticle Synthetic 300mm Semiconductor Wafer Fab Digital Twin.

Simulates a high-volume semiconductor manufacturing facility:
- 12 Twin-Scan photolithography immersion scanners
- 8 Plasma dielectric and conductor etch chambers
- 4 Chemical vapor deposition (CVD) chambers
- 20 Overhead Hoist Transport (OHT) monorail vehicles
- 4 Automated stockers with 256 total FOUP capacity
- 100 Production wafer lots with furnace Q-time tracking
"""

from __future__ import annotations

import random
import time
from dataclasses import dataclass, field
from enum import Enum
from typing import Dict, List, Optional, Tuple, Any


class ToolType(Enum):
    LITHO_SCANNER = "LITHO_SCANNER"
    PLASMA_ETCH = "PLASMA_ETCH"
    CVD_CHAMBER = "CVD_CHAMBER"
    METROLOGY = "METROLOGY"


class ToolState(Enum):
    IDLE = "IDLE"
    LOADING = "LOADING"
    PROCESSING = "PROCESSING"
    UNLOADING = "UNLOADING"
    DOWN_MAINTENANCE = "DOWN_MAINTENANCE"


@dataclass
class EquipmentTool:
    tool_id: str
    tool_type: ToolType
    bay_name: str
    track_node_id: int
    state: ToolState = ToolState.IDLE
    current_carrier_id: Optional[str] = None
    current_recipe: Optional[str] = None
    process_progress: float = 0.0
    process_duration: float = 30.0
    chamber_pressure_mtorr: float = 15.0
    chuck_temp_celsius: float = 23.5
    wafers_processed: int = 0


@dataclass
class OHTVehicle:
    vehicle_id: int
    current_node: int
    speed_mps: float = 0.0
    state: str = "IDLE"
    carried_foup_id: Optional[str] = None
    battery_soc: float = 98.0
    assigned_job_id: Optional[int] = None
    target_node: Optional[int] = None


@dataclass
class FOUPCarrier:
    carrier_id: str
    lot_id: str
    recipe_name: str
    wafer_count: int = 25
    current_location: str = "STOCKER-1"
    q_time_start: float = field(default_factory=time.time)
    q_time_limit_sec: float = 14400.0  # 4 hours max before furnace oxide oxidation
    is_clamped: bool = False
    is_docked: bool = False

    @property
    def q_time_remaining(self) -> float:
        elapsed = time.time() - self.q_time_start
        return max(0.0, self.q_time_limit_sec - elapsed)

    @property
    def is_q_time_expired(self) -> bool:
        return self.q_time_remaining <= 0.0


@dataclass
class TransportJob:
    job_id: int
    carrier_id: str
    from_node: int
    to_node: int
    priority: int
    status: str = "PENDING"
    assigned_vehicle: Optional[int] = None


class CleanroomFabTwin:
    """Master digital twin coordinating tools, AMHS vehicles, stockers, and lots."""

    def __init__(self, seed: int = 42) -> None:
        random.seed(seed)
        self.sim_time: float = 0.0
        self.tools: Dict[str, EquipmentTool] = {}
        self.vehicles: List[OHTVehicle] = []
        self.carriers: Dict[str, FOUPCarrier] = {}
        self.jobs: List[TransportJob] = []
        self.completed_jobs_count: int = 0
        self.total_wafers_exposed: int = 0
        self.total_tool_busy_seconds: float = 0.0
        self.alarm_log: List[Tuple[float, str, str]] = []

        self._init_fab_equipment()
        self._init_fleet()
        self._init_carriers()

    def _init_fab_equipment(self) -> None:
        # 12 Twin-Scan Photolithography Scanners
        for i in range(1, 13):
            t_id = f"SCANNER-{i:02d}"
            node = 100 + i
            self.tools[t_id] = EquipmentTool(
                tool_id=t_id,
                tool_type=ToolType.LITHO_SCANNER,
                bay_name="LITHO-BAY",
                track_node_id=node,
                process_duration=25.0,
            )

        # 8 Plasma Etchers
        for i in range(1, 9):
            t_id = f"ETCHER-{i:02d}"
            node = 200 + i
            self.tools[t_id] = EquipmentTool(
                tool_id=t_id,
                tool_type=ToolType.PLASMA_ETCH,
                bay_name="ETCH-BAY",
                track_node_id=node,
                process_duration=35.0,
            )

        # 4 CVD Chambers
        for i in range(1, 5):
            t_id = f"CVD-{i:02d}"
            node = 300 + i
            self.tools[t_id] = EquipmentTool(
                tool_id=t_id,
                tool_type=ToolType.CVD_CHAMBER,
                bay_name="CVD-BAY",
                track_node_id=node,
                process_duration=40.0,
            )

    def _init_fleet(self) -> None:
        for i in range(1, 21):
            start_node = (i % 12) + 101
            self.vehicles.append(OHTVehicle(vehicle_id=i, current_node=start_node))

    def _init_carriers(self) -> None:
        self.carriers = {}
        for i in range(1, 101):
            c_id = f"FOUP-{i:03d}"
            lot_id = f"LOT-3NM-FINFET-{i:03d}"
            recipe = "RECIPE-DUAL-DAMASCENE" if i % 2 == 0 else "RECIPE-IMMERSION-ARF"
            carrier = FOUPCarrier(carrier_id=c_id, lot_id=lot_id, recipe_name=recipe)
            self.carriers[c_id] = carrier

    def post_alarm(self, severity: str, text: str) -> None:
        self.alarm_log.append((self.sim_time, severity, text))

    def step(self, dt: float = 0.5) -> None:
        """Advance physical cleanroom simulation by dt seconds."""
        self.sim_time += dt

        # Step 1: Advance equipment tool processing cycles
        for tool in self.tools.values():
            if tool.state == ToolState.PROCESSING:
                tool.process_progress += dt
                self.total_tool_busy_seconds += dt
                # Dynamic chamber sensor noise
                tool.chamber_pressure_mtorr = 15.0 + random.uniform(-0.4, 0.4)
                tool.chuck_temp_celsius = 23.5 + random.uniform(-0.15, 0.15)

                if tool.process_progress >= tool.process_duration:
                    tool.state = ToolState.UNLOADING
                    tool.process_progress = 0.0
                    tool.wafers_processed += 25
                    self.total_wafers_exposed += 25

            elif tool.state == ToolState.UNLOADING:
                # Trigger transport job back to stocker or next bay
                if tool.current_carrier_id:
                    self.jobs.append(
                        TransportJob(
                            job_id=len(self.jobs) + 1001,
                            carrier_id=tool.current_carrier_id,
                            from_node=tool.track_node_id,
                            to_node=17,  # Central Stocker
                            priority=60,
                        )
                    )
                    tool.current_carrier_id = None
                tool.state = ToolState.IDLE

        # Step 2: Feed idle tools from stocker carriers
        idle_tools = [t for t in self.tools.values() if t.state == ToolState.IDLE]
        available_carriers = [c for c in self.carriers.values() if c.current_location.startswith("STOCKER")]

        for tool in idle_tools[:4]:
            if available_carriers:
                c = available_carriers.pop(0)
                c.current_location = f"TRANSIT-{tool.tool_id}"
                self.jobs.append(
                    TransportJob(
                        job_id=len(self.jobs) + 1001,
                        carrier_id=c.carrier_id,
                        from_node=17,
                        to_node=tool.track_node_id,
                        priority=85 if c.q_time_remaining < 3600 else 50,
                    )
                )

        # Step 3: Match pending jobs to idle OHT vehicles
        pending = [j for j in self.jobs if j.status == "PENDING"]
        idle_vehs = [v for v in self.vehicles if v.state == "IDLE"]

        for job in pending:
            if idle_vehs:
                veh = idle_vehs.pop(0)
                veh.state = "TRAVEL_EMPTY"
                veh.assigned_job_id = job.job_id
                veh.target_node = job.from_node
                job.status = "ASSIGNED"
                job.assigned_vehicle = veh.vehicle_id

        # Step 4: Step vehicle kinematics and mission progress
        for veh in self.vehicles:
            if veh.state == "TRAVEL_EMPTY":
                veh.speed_mps = min(4.0, veh.speed_mps + (1.0 * dt))
                veh.battery_soc = max(0.0, veh.battery_soc - (0.005 * dt))
                veh.current_node = veh.target_node or veh.current_node
                veh.state = "HOIST_DOWN"
            elif veh.state == "HOIST_DOWN":
                veh.speed_mps = 0.0
                job_match = [j for j in self.jobs if j.job_id == veh.assigned_job_id]
                if job_match:
                    job = job_match[0]
                    veh.carried_foup_id = job.carrier_id
                    veh.target_node = job.to_node
                    veh.state = "TRAVEL_LOADED"
            elif veh.state == "TRAVEL_LOADED":
                veh.speed_mps = min(4.0, veh.speed_mps + (1.0 * dt))
                veh.battery_soc = max(0.0, veh.battery_soc - (0.008 * dt))
                veh.current_node = veh.target_node or veh.current_node
                veh.state = "HOIST_DELIVER"
            elif veh.state == "HOIST_DELIVER":
                veh.speed_mps = 0.0
                delivered_carrier = veh.carried_foup_id
                veh.carried_foup_id = None
                veh.state = "IDLE"
                job_match = [j for j in self.jobs if j.job_id == veh.assigned_job_id]
                if job_match:
                    job = job_match[0]
                    job.status = "COMPLETED"
                    self.completed_jobs_count += 1
                    # Dock carrier into tool or return to stocker
                    if job.to_node == 17:
                        # Returned to central stocker
                        if delivered_carrier and delivered_carrier in self.carriers:
                            self.carriers[delivered_carrier].current_location = "STOCKER-1"
                    else:
                        dest_tools = [t for t in self.tools.values() if t.track_node_id == job.to_node]
                        if dest_tools:
                            target_tool = dest_tools[0]
                            target_tool.current_carrier_id = delivered_carrier
                            target_tool.state = ToolState.PROCESSING
                            if delivered_carrier and delivered_carrier in self.carriers:
                                self.carriers[delivered_carrier].current_location = target_tool.tool_id
                veh.assigned_job_id = None

    def get_summary_metrics(self) -> Dict[str, Any]:
        active_tools_count = sum(1 for t in self.tools.values() if t.state == ToolState.PROCESSING)
        moving_vehs_count = sum(1 for v in self.vehicles if v.state.startswith("TRAVEL"))
        avg_battery = sum(v.battery_soc for v in self.vehicles) / max(1, len(self.vehicles))
        duty_cycle = (self.total_tool_busy_seconds / max(1.0, self.sim_time * len(self.tools))) * 100
        return {
            "sim_time_sec": round(self.sim_time, 1),
            "total_tools": len(self.tools),
            "active_processing_tools": active_tools_count,
            "tool_utilization_percent": round(duty_cycle, 1),
            "instant_active_percent": round((active_tools_count / max(1, len(self.tools))) * 100, 1),
            "total_vehicles": len(self.vehicles),
            "moving_vehicles": moving_vehs_count,
            "fleet_utilization_percent": round((moving_vehs_count / max(1, len(self.vehicles))) * 100, 1),
            "average_battery_soc": round(avg_battery, 1),
            "completed_transport_jobs": self.completed_jobs_count,
            "total_wafers_processed": self.total_wafers_exposed,
        }

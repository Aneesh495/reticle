"""
Reticle Unified Command Line Interface.

Provides CLI commands for cleanroom simulation, HSMS communications,
conformance testing, benchmarks, and typography linting.
"""

from __future__ import annotations

import argparse
import os
import subprocess
import sys
import time
from reticle.fab_twin import CleanroomFabTwin
from reticle.telemetry import TelemetryPublisher
from reticle.visualizer import FabDashboard


def cmd_emulate(args: argparse.Namespace) -> int:
    """Runs cleanroom digital twin emulation with real-time ANSI status display."""
    twin = CleanroomFabTwin(seed=args.seed)
    print("\033[2J\033[H", end="")  # Clear terminal screen

    steps = args.steps
    dt = args.dt
    display_interval = args.interval

    for step_idx in range(steps):
        twin.step(dt=dt)
        if step_idx % display_interval == 0:
            print("\033[H", end="")
            print(FabDashboard.render(twin))
            if not args.fast:
                time.sleep(dt * 0.1)

    print("\nSimulation complete.")
    metrics = twin.get_summary_metrics()
    print(f"Total simulated time: {metrics['sim_time_sec']}s")
    print(f"Completed transport jobs: {metrics['completed_transport_jobs']}")
    print(f"Total wafers exposed: {metrics['total_wafers_processed']}")
    return 0


def cmd_telemetry(args: argparse.Namespace) -> int:
    """Exports a live telemetry snapshot in JSON format."""
    twin = CleanroomFabTwin(seed=args.seed)
    for _ in range(20):
        twin.step(dt=0.5)
    pub = TelemetryPublisher(twin)
    print(pub.export_json())
    return 0


def cmd_test(args: argparse.Namespace) -> int:
    """Executes the complete multi-language verification suite."""
    repo_root = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))

    print("=== Step 1: C17 Fastpath Unit Tests ===")
    c_res = subprocess.run(["make", "-C", repo_root, "test-c"])
    if c_res.returncode != 0:
        return c_res.returncode

    print("\n=== Step 2: Python Conformance & Integration Tests ===")
    py_res = subprocess.run([sys.executable, "-m", "unittest", "discover", "-s", os.path.join(repo_root, "tests")])
    if py_res.returncode != 0:
        return py_res.returncode

    print("\n=== Step 3: Zero Em Dash Typography Linter ===")
    lint_res = subprocess.run([sys.executable, os.path.join(repo_root, "tools", "lint_no_em_dash.py")])
    return lint_res.returncode


def cmd_lint(args: argparse.Namespace) -> int:
    """Runs the zero em dash typography linter."""
    repo_root = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
    return subprocess.run([sys.executable, os.path.join(repo_root, "tools", "lint_no_em_dash.py")]).returncode


def main() -> int:
    parser = argparse.ArgumentParser(
        prog="reticle",
        description="Cleanroom Semiconductor Material Control System & SECS/GEM Engine",
    )
    subparsers = parser.add_subparsers(dest="command", required=True)

    # Subcommand: emulate
    emu_parser = subparsers.add_parser("emulate", help="Run cleanroom fab digital twin simulation")
    emu_parser.add_argument("steps", type=int, nargs="?", default=100, help="Simulation steps to execute")
    emu_parser.add_argument("dt", type=float, nargs="?", default=0.5, help="Simulation time step in seconds")
    emu_parser.add_argument("-i", "--interval", dest="interval", type=int, default=2, help="HUD refresh interval")
    emu_parser.add_argument("-f", "--fast", dest="fast", action="store_true", help="Run at maximum speed")
    emu_parser.add_argument("-s", "--seed", dest="seed", type=int, default=42, help="Random seed")
    emu_parser.set_defaults(func=cmd_emulate)

    # Subcommand: telemetry
    tel_parser = subparsers.add_parser("telemetry", help="Export cleanroom telemetry snapshot as JSON")
    tel_parser.add_argument("-s", "--seed", dest="seed", type=int, default=42, help="Random seed")
    tel_parser.set_defaults(func=cmd_telemetry)

    # Subcommand: test
    test_parser = subparsers.add_parser("test", help="Execute full verification test suite")
    test_parser.set_defaults(func=cmd_test)

    # Subcommand: lint
    lint_parser = subparsers.add_parser("lint", help="Verify zero em dash typography invariant")
    lint_parser.set_defaults(func=cmd_lint)

    args = parser.parse_args()
    return args.func(args)


if __name__ == "__main__":
    sys.exit(main())

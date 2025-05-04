"""
Benchmark: Measures AMHS fleet scalability with 20, 50, and 100 vehicles.
"""

from __future__ import annotations

import os
import sys
import time

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "python")))

from reticle.fab_twin import CleanroomFabTwin, OHTVehicle


def benchmark_fleet_scale(vehicle_count: int, steps: int = 500) -> None:
    twin = CleanroomFabTwin(seed=42)
    # Scale fleet size
    twin.vehicles = [OHTVehicle(vehicle_id=i, current_node=(i % 12) + 101) for i in range(1, vehicle_count + 1)]

    start = time.perf_counter()
    for _ in range(steps):
        twin.step(dt=0.5)
    elapsed = time.perf_counter() - start

    steps_per_sec = steps / elapsed
    step_latency_us = (elapsed / steps) * 1e6
    print(
        f"Fleet Scale: {vehicle_count:>3d} vehicles | "
        f"{steps_per_sec:>7.1f} steps/sec | "
        f"Step Latency: {step_latency_us:>6.1f} us/step | "
        f"Elapsed: {elapsed:.3f}s"
    )


def run_benchmarks() -> None:
    print("=== Reticle AMHS Fleet Scalability Benchmark ===")
    for count in (20, 50, 100):
        benchmark_fleet_scale(count, steps=300)


if __name__ == "__main__":
    run_benchmarks()

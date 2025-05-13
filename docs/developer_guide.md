# Reticle Developer Guide

This guide describes how to build, test, benchmark, and deploy **Reticle**.

---

## 1. Prerequisites and Environment

Reticle requires:
- **C Compiler**: Apple Clang or GCC supporting standard C17 (`-std=c17`).
- **Python**: Python 3.9 or newer (standard library only; zero external dependencies required for core execution).
- **Make**: GNU Make or BSD Make.
- **Red Language**: (Optional) Red binary toolchain for running native Red scripts.

---

## 2. Building the C17 Fastpath Library

To compile the high-performance C17 shared library (`lib/libreticle_fastpath.dylib` on macOS or `lib/libreticle_fastpath.so` on Linux):

```bash
make all
```

To run C fastpath unit verification:

```bash
make test-c
```

---

## 3. Running the Verification Test Suite

Reticle includes a comprehensive multi-tier test suite covering C fastpath routines, SECS/GEM conformance, AMHS routing, E84 optical handshakes, and fault injection drills:

```bash
# Run all C and Python tests
make test

# Or execute Python tests directly via unittest discovery
python3 -m unittest discover -s tests
```

---

## 4. Running the Cleanroom Fab Digital Twin

To launch the real-time cleanroom digital twin with the interactive ANSI terminal status dashboard:

```bash
python3 python/reticle/cli.py emulate 100 0.5
```

Positional parameters:
- `steps`: Number of simulation steps to run (default: 100).
- `dt`: Time step duration in seconds (default: 0.5).
- `--no-delay`: Run at full CPU speed without wall-clock pacing.
- `--seed INT`: Seed for reproducible simulation results (default: 42).

To export a live cleanroom telemetry snapshot as JSON:

```bash
python3 python/reticle/cli.py telemetry
```

---

## 5. Running Performance Benchmarks

Reticle includes automated throughput and latency benchmarks:

```bash
# C17 fastpath latency and CRC-32C throughput
python3 benchmarks/bench_fastpath.py

# SECS-II item encoding and decoding messages/sec
python3 benchmarks/bench_secs_throughput.py

# AMHS vehicle fleet scalability (20, 50, 100 vehicles)
python3 benchmarks/bench_oht_scalability.py
```

---

## 6. Code Style and Typography Linter

Reticle strictly enforces the zero em dash typography invariant across all source code, documentation, comments, and commit messages:

```bash
make lint
# Or directly:
python3 tools/lint_no_em_dash.py
```

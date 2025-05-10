# Reticle Architecture Specification

This document details the layered architectural components, subsystem interactions, and dataflow topologies within **Reticle**.

---

## 1. System Block Diagram

```mermaid
flowchart TD
    subgraph FabHost ["Manufacturing Execution System (MES) & Fab Host"]
        MES["Cleanroom Host Dispatcher"]
        RecipeMgr["Recipe Server (SECS Stream 7)"]
        TraceLogger["EDA / Fault Detection Logger (SECS Stream 6)"]
    end

    subgraph ProtocolCore ["SECS/GEM & HSMS-SS Protocol Engine"]
        HSMS["HSMS Socket Driver (SEMI E37)"]
        ItemCodec["SECS-II Item Encoder & SML Parser (SEMI E5)"]
        GEMState["GEM State Machines (SEMI E30)"]
        Spool["Non-Volatile Spooling Queue"]
    end

    subgraph AMHS_MCS ["Material Control System (MCS) & Fleet Dispatcher"]
        Dispatcher["Multi-Objective Priority Dispatcher"]
        Router["Space-Time Reservation Router"]
        Deadlock["Banker's Loop Cycle Detector"]
        Stocker["Automated Stocker Manager"]
    end

    subgraph PhysicalHandoff ["Carrier & Substrate Physical Interlocks"]
        E84["E84 Optical Signal Transceiver"]
        E87["E87 Carrier Management System"]
        E90["E90 Substrate Wafer Tracker"]
    end

    subgraph Equipment ["Fab Cleanroom Hardware & OHT Fleet"]
        Scanners["Twin-Scan Litho Immersion Scanners"]
        Etchers["Plasma Etch Chambers"]
        OHT["Overhead Hoist Transport Vehicles"]
    end

    MES -->|HSMS TCP 5000| HSMS
    RecipeMgr -->|S7F3 / S7F5| ItemCodec
    HSMS --> ItemCodec
    ItemCodec --> GEMState
    GEMState --> Dispatcher
    GEMState --> Spool

    Dispatcher --> Router
    Router --> Deadlock
    Dispatcher --> Stocker

    Dispatcher --> E87
    E87 --> E84
    E84 --> E90

    E84 -->|Optical PIO| Scanners
    E84 -->|Optical PIO| Etchers
    Router -->|Monorail Waypoints| OHT
```

---

## 2. Multi-Language Architectural Cohesion

Reticle is partitioned into focused, cooperating layers:

1. **Red Subsystem (`red/`)**:
   - The heart of Reticle. Implements homoiconic symbolic dialects (`parse-dsl.red`), SEMI E5 SECS-II item trees, SEMI E30 GEM state models, and the AMHS space-time reservation graph solver.
   - Leverages Red's native `parse` PEG engine for declarative SML grammar compilation and pattern matching.
   - Red files start with standard Red headers and are structured for native compilation or direct evaluation.

2. **C17 Fastpath Library (`include/`, `src/`)**:
   - Hardware-level zero-copy HSMS header framing (`fastpath.h`, `fastpath.c`).
   - Bitwise SIMD-optimized Castagnoli CRC-32C and CCITT CRC-16 implementations.
   - 64-bit spatial bitboard reservation grid enabling sub-microsecond collision avoidance queries.

3. **Python Cleanroom Digital Twin (`python/reticle/`)**:
   - High-fidelity physical emulation of 24 processing chambers, 20 OHT vehicles, 4 automated stockers, and 100 wafer production lots.
   - Real-time cleanroom telemetry server and interactive ANSI Primary Flight Display dashboard.
   - Comprehensive test harness covering unit tests, integration tests, and fault injection drills.

---

## 3. SEMI E84 Optical Handoff Timing Diagram

```mermaid
sequenceDiagram
    participant OHT as OHT Vehicle (Active)
    participant LP as Load Port (Passive)

    Note over OHT,LP: Approach & Alignment Phase
    OHT->>LP: VALID = 1, CS_0 = 1, AM_AVBL = 1
    Note over LP: Verify optical path & open shutter doors (max 2.0s TA1)
    LP->>OHT: READY = 1

    Note over OHT,LP: Physical Transfer Phase (max 60.0s TP1)
    OHT->>LP: TR_REQ = 1, BUSY = 1
    Note over OHT: Lower vertical hoist & clamp/unclamp FOUP
    OHT->>LP: TR_REQ = 0, BUSY = 0
    OHT->>LP: COMPT = 1

    Note over OHT,LP: Completion & Release Phase
    Note over LP: Clamp FOUP & verify kinematic seating (max 2.0s TP3)
    LP->>OHT: READY = 0
    Note over OHT: Deassert optical handshake (max 2.0s TD1)
    OHT->>LP: VALID = 0, CS_0 = 0, COMPT = 0
```

---

## 4. Verification and Conformance Strategy

Reticle maintains a rigorous verification matrix across five critical invariants:
1. **Zero Em Dash Invariant**: Verified continuously via `tools/lint_no_em_dash.py`.
2. **SECS-II Format Invariance**: Bidirectional roundtrip equality for all SEMI E5 data types.
3. **E37 Watchdog Determinism**: Guaranteed socket teardown on T7 expiry and reply abort on T3 timeout.
4. **Collision and Deadlock Freedom**: Space-time reservation tables and Banker's loop invariant guarantee zero track collisions and zero monorail deadlocks.
5. **Furnace Q-Time Protection**: Automated priority escalation ensures wafer lots never exceed cleanroom oxide oxidation limits.

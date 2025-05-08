# Cleanroom AMHS Monorail Routing & OHT Dispatching

This document outlines the algorithms and mathematical formulations governing automated material handling in **Reticle**.

---

## 1. Space-Time Monorail Reservation Graphs

Cleanroom Overhead Hoist Transport (OHT) vehicles drive along ceiling-mounted monorail tracks. Because tracks are single-lane and unidirectional, head-to-tail collisions and merge conflicts must be prevented dynamically.

### 1.1 Discrete Time-Window Representation

Let the cleanroom track network be modeled as a directed graph $G = (V, E)$, where:
- $V = \{v_1, v_2, \dots, v_n\}$ represents physical waypoints, merge nodes, diverge nodes, and equipment load ports.
- $E = \{e_1, e_2, \dots, e_m\}$ represents directed track segments.

Each segment $e \in E$ has:
- Physical length $L_e$ (meters)
- Maximum velocity limit $v_{\max}(e)$ (meters per second)
- Traversing duration $\Delta t_e = L_e / v_{\max}(e)$

A reservation on segment $e$ for vehicle $k$ is an interval:
$$R_e^k = [t_{\text{enter}}, t_{\text{exit}})$$

Two vehicles $j$ and $k$ are conflict-free on segment $e$ if and only if their reservation intervals are completely disjoint:
$$R_e^j \cap R_e^k = \emptyset \quad \forall j \neq k$$

### 1.2 C17 Hardware Fastpath Bitboard Implementation

To achieve sub-microsecond collision checks, Reticle implements a 64-bit spatial bitboard grid in C17. The forward planning horizon is divided into discrete minor cycles $\tau = 100\text{ ms}$:
- Each 64-bit word represents 6.4 seconds of time reservation for a single segment.
- A collision check over interval $[t_a, t_b]$ is computed using a bitwise AND mask:

$$\text{Collision} = (\text{Grid}[e][w] \ \& \ \text{Mask}(t_a, t_b)) \neq 0$$

This operation executes in constant $O(1)$ time per 64-tick window.

---

## 2. Monorail Loop Deadlock Avoidance: Banker's Invariant

Closed monorail loops in wafer fabs are prone to circular wait deadlocks: if $N$ vehicles simultaneously occupy all $N$ consecutive segments of a closed loop, no vehicle can advance.

### 2.1 Capacity Limit Rule

For any detected closed directed cycle $C = (e_1, e_2, \dots, e_k)$ of length $k$:
- Total capacity is $C_{\text{cap}} = k$ segments.
- Maximum permitted concurrent vehicles is strictly constrained by Banker's invariant:

$$N_{\text{veh}}(C) \le k - 1$$

At all times, at least one empty segment bubble is guaranteed to exist on every closed loop. This ensures that circular wait graphs remain acyclic and vehicles can always advance forward.

---

## 3. Multi-Objective Transport Job Dispatching

Transport jobs are dispatched using a priority-weighted utility scoring function:

$$\text{Score}(J, V) = w_{\text{prio}} \cdot P(J) + w_{\text{dist}} \cdot \frac{1}{1 + D(V, J)} + w_{\text{qtime}} \cdot Q(J) + w_{\text{soc}} \cdot \text{SoC}(V)$$

Where:
- $P(J)$: Base job priority (10 = Low, 50 = Normal, 80 = High, 100 = Critical).
- $D(V, J)$: Topological graph distance from vehicle current node to pick-up load port.
- $Q(J)$: Furnace Queue Time urgency factor. Silicon wafers exposed to ambient cleanroom air after chemical oxide stripping must enter diffusion furnaces before native oxide exceeds 0.2 nm (typically within 4 hours). If $T_{\text{remain}} < 3600\text{ s}$, $Q(J)$ spikes exponentially to preempt standard traffic.
- $\text{SoC}(V)$: Vehicle battery or supercapacitor State of Charge. Vehicles with $\text{SoC} < 20\%$ are automatically routed to regenerative charging sidings.

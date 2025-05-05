# SEMI Protocol Standards Specification

This document details the semiconductor equipment communication and automated material handling standards implemented in **Reticle**.

---

## 1. SEMI E37 and E37.1: High-Speed SECS Message Services (HSMS-SS)

HSMS defines the TCP/IP-based wire protocol used in modern 300mm wafer fabs, replacing legacy RS-232 serial SECS-I links.

### 1.1 Wire Message Framing

Every HSMS message consists of a 4-byte message length prefix followed by a 10-byte header and an optional SECS-II data payload:

```
+---------------------------+---------------------------+---------------------------+
| 4-Byte Message Length     | 10-Byte Header            | SECS-II Payload (Variable)|
| Big-Endian uint32         | Transport & Routing       | SEMI E5 Typed Data Items  |
+---------------------------+---------------------------+---------------------------+
```

### 1.2 10-Byte Header Format

| Byte Offset | Field Name | Description |
|---|---|---|
| 0..1 | Session ID | 16-bit Device ID or Session ID |
| 2 | Stream | Stream number (bits 0..6). Bit 7 is the Wait Bit (W-bit) |
| 3 | Function | Function number (0..255) |
| 4 | P-Type | Presentation Type (0 = SECS-II) |
| 5 | S-Type | Session message subtype (0 = Data, 1..9 = Control) |
| 6..9 | System Bytes | 32-bit transaction identifier |

### 1.3 Control Message Subtypes (S-Type)

- `SType = 0 (Data)`: Primary or secondary SECS data transaction.
- `SType = 1 (Select.req)`: Request to establish an active session.
- `SType = 2 (Select.rsp)`: Session establishment acknowledgement.
- `SType = 3 (Deselect.req)`: Request to tear down the active session.
- `SType = 4 (Deselect.rsp)`: Deselect acknowledgement.
- `SType = 5 (Linktest.req)`: Keepalive heartbeat ping.
- `SType = 6 (Linktest.rsp)`: Heartbeat ping reply with matching system bytes.
- `SType = 7 (Reject.req)`: Protocol rejection for unsupported message type.
- `SType = 9 (Separate.req)`: Orderly unilateral disconnection.

### 1.4 Protocol Watchdog Timers

- **T3 (Reply Timeout, default 45s)**: Maximum time a host or equipment will wait for a secondary response after sending a primary message with W-bit asserted.
- **T5 (Connection Separation Timeout, default 10s)**: Minimum delay between successive TCP connection attempts.
- **T6 (Control Transaction Timeout, default 5s)**: Maximum wait time for Select.rsp, Deselect.rsp, or Linktest.rsp.
- **T7 (NOT SELECTED Timeout, default 10s)**: Maximum time a TCP socket may stay connected without receiving a valid Select.req handshake before automatic socket abort.
- **T8 (Network Inter-character Timeout, default 5s)**: Maximum time between consecutive incoming packet bytes.

---

## 2. SEMI E5: SECS-II Item Representation

SECS-II defines typed data items packed hierarchically:

### 2.1 Format Codes

- `000000b (0)`: List of items
- `001000b (8)`: Unstructured binary bytes
- `001001b (9)`: 1-byte boolean flag
- `010000b (16)`: 7-bit ASCII string
- `011001b (25)`: 1-byte signed integer (I1)
- `011010b (26)`: 2-byte signed integer (I2)
- `011100b (28)`: 4-byte signed integer (I4)
- `100000b (32)`: 8-byte floating point (F8)
- `100001b (33)`: 4-byte floating point (F4)
- `101001b (41)`: 1-byte unsigned integer (U1)
- `101010b (42)`: 2-byte unsigned integer (U2)
- `101100b (44)`: 4-byte unsigned integer (U4)

---

## 3. SEMI E84: Parallel Optical Carrier Handoff

SEMI E84 specifies the physical parallel optical sensor handshake between an Overhead Hoist Transport (OHT) vehicle (Active entity) and an Equipment Load Port (Passive entity).

### 3.1 Optical Signal Bitmasks

#### Active Signals (OHT Vehicle):
- `VALID (Bit 0)`: Optical optical path aligned and transceiver powered
- `CS_0 (Bit 1)`: Carrier stage select bit 0
- `CS_1 (Bit 2)`: Carrier stage select bit 1
- `AM_AVBL (Bit 3)`: Automated material handling vehicle present and ready
- `TR_REQ (Bit 4)`: Transfer request
- `BUSY (Bit 5)`: Physical hoist in downward or upward vertical motion
- `COMPT (Bit 6)`: Transfer complete confirmation

#### Passive Signals (Equipment Load Port):
- `L_REQ (Bit 0)`: Load request (equipment requesting incoming wafer carrier)
- `U_REQ (Bit 1)`: Unload request (equipment requesting finished wafer carrier pickup)
- `READY (Bit 2)`: Shutter doors open and mechanical docking pins prepared
- `HO_AVBL (Bit 3)`: Handoff port available and in automatic mode
- `ES (Bit 4)`: Emergency stop sensor loop active
- `VA (Bit 5)`: Vehicle optical presence confirmation

### 3.2 Handshake Timing Interlocks

```
OHT Vehicle (Active)                           Load Port (Passive)
--------------------                           -------------------
VALID = 1, CS0 = 1, AM_AVBL = 1
                                  ------>
                                                Verify optical path
                                                Open shutter doors
                                  <------       READY = 1
Assert TR_REQ = 1, BUSY = 1
Lower vertical hoist
Unclamp FOUP onto pins
Raise hoist to rail height
Drop TR_REQ = 0, BUSY = 0
Assert COMPT = 1
                                  ------>
                                                Clamp FOUP
                                                Drop READY = 0
                                  <------
Deassert VALID = 0, CS0 = 0, COMPT = 0
                                  ------>
                                                Handoff sequence complete
```

---

## 4. SEMI E87 and SEMI E90: Carrier Management and Substrate Tracking

- **SEMI E87 (CMS)**: Verifies 300mm FOUP barcode/RFID tags, tracks carrier access state (NotAccessed, InAccess, CarrierComplete), and validates 25-shelf wafer maps against cross-slotting and double-slotting defects.
- **SEMI E90**: Tracks individual silicon wafers through atmospheric equipment front-end modules (EFEM), laser notch pre-aligners, vacuum loadlocks, core transfer robots, and exposure/etch chucks.

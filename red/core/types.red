Red [
    Title: "Reticle Core Types and SEMI Data Definitions"
    Author: "Aneesh"
    File: %types.red
    Tabs: 4
]

;; ----------------------------------------------------------------------------
;; Reticle: Semiconductor Material Control System & SECS/GEM Engine
;; Module: Core Types & Constants
;;
;; Provides foundational symbolic structures, enumerations, format codes,
;; and bitmask definitions for SEMI E5, E30, E37, E84, and E87 standards.
;; ----------------------------------------------------------------------------

reticle-core: context [

    ;; ------------------------------------------------------------------------
    ;; SECS-II (SEMI E5) Item Format Codes
    ;; The format byte uses the upper 6 bits for format classification and
    ;; the lower 2 bits for length byte count (1, 2, or 3 bytes).
    ;; ------------------------------------------------------------------------
    format-list:       0   ; 000000b: List of items
    format-binary:     8   ; 001000b: Unstructured binary bytes
    format-boolean:    9   ; 001001b: Single byte boolean (0 = false, non-zero = true)
    format-ascii:     16   ; 010000b: ISO 646 7-bit ASCII string
    format-jis8:      17   ; 010001b: 8-bit Katakana or JIS character set
    format-i8:        24   ; 011000b: 8-byte signed integer (big-endian)
    format-i1:        25   ; 011001b: 1-byte signed integer
    format-i2:        26   ; 011010b: 2-byte signed integer
    format-i4:        28   ; 011100b: 4-byte signed integer
    format-f8:        32   ; 100000b: 8-byte IEEE 754 double precision float
    format-f4:        33   ; 100001b: 4-byte IEEE 754 single precision float
    format-u8:        40   ; 101000b: 8-byte unsigned integer
    format-u1:        41   ; 101001b: 1-byte unsigned integer
    format-u2:        42   ; 101010b: 2-byte unsigned integer
    format-u4:        44   ; 101100b: 4-byte unsigned integer

    ;; Format name to numeric code mapping
    format-names: [
        'L        0
        'LIST     0
        'B        8
        'BINARY   8
        'BOOLEAN  9
        'BOOL     9
        'A       16
        'ASCII   16
        'J       17
        'JIS8    17
        'I8      24
        'I1      25
        'I2      26
        'I4      28
        'F8      32
        'F4      33
        'U8      40
        'U1      41
        'U2      42
        'U4      44
    ]

    ;; ------------------------------------------------------------------------
    ;; HSMS (SEMI E37) Protocol Types & Control Message Subtypes (SType)
    ;; ------------------------------------------------------------------------
    p-type-secs2:          0   ; P-Type = 0 for standard SECS-II encoding
    
    stype-data:            0   ; Primary or secondary SECS data transaction
    stype-select-req:      1   ; Session establishment request
    stype-select-rsp:      2   ; Session establishment response
    stype-deselect-req:    3   ; Session teardown request
    stype-deselect-rsp:    4   ; Session teardown response
    stype-linktest-req:    5   ; Heartbeat keepalive ping request
    stype-linktest-rsp:    6   ; Heartbeat keepalive ping response
    stype-reject-req:      7   ; Protocol violation rejection notification
    stype-separate-req:    9   ; Orderly unilateral disconnect request

    ;; HSMS Select Response Status Codes
    select-status-success:          0
    select-status-already-active:   1
    select-status-not-ready:        2
    select-status-connect-exhaust:  3

    ;; HSMS Reject Reason Codes
    reject-reason-stype-not-supported: 1
    reject-reason-p-type-not-supported: 2
    reject-reason-transaction-not-open: 3
    reject-reason-not-selected:         4

    ;; ------------------------------------------------------------------------
    ;; GEM E30 State Model Constants
    ;; ------------------------------------------------------------------------
    comm-state-disabled:                 'DISABLED
    comm-state-enabled-not-communicating: 'WAIT-BIT-1
    comm-state-wait-cra:                 'WAIT-CRA
    comm-state-communicating:            'COMMUNICATING

    control-state-offline-equipment:     'OFFLINE-EQUIPMENT
    control-state-offline-attempt:       'OFFLINE-ATTEMPT-ONLINE
    control-state-offline-host:          'OFFLINE-HOST
    control-state-online-local:          'ONLINE-LOCAL
    control-state-online-remote:         'ONLINE-REMOTE

    process-state-init:                  'INIT
    process-state-idle:                  'IDLE
    process-state-setup:                 'SETUP
    process-state-ready:                 'READY
    process-state-executing:             'EXECUTING
    process-state-pause:                 'PAUSED
    process-state-stopping:              'STOPPING
    process-state-aborting:              'ABORTING

    ;; ------------------------------------------------------------------------
    ;; SEMI E84 Parallel Optical Carrier Handoff Signals (Bitmasks)
    ;; ------------------------------------------------------------------------
    ;; Active side signals (driven by OHT vehicle)
    sig-valid:    1    ; Optical transceiver optical link valid
    sig-cs0:      2    ; Carrier stage select bit 0
    sig-cs1:      4    ; Carrier stage select bit 1
    sig-am-avbl:  8    ; Automated material handling vehicle available
    sig-tr-req:  16    ; Transfer request
    sig-busy:    32    ; Vehicle hoist / arm in motion
    sig-compt:   64    ; Transfer complete confirmation

    ;; Passive side signals (driven by Equipment Load Port)
    sig-l-req:    1    ; Load request
    sig-u-req:    2    ; Unload request
    sig-ready:    4    ; Load port mechanical shutters open and ready
    sig-ho-avbl:  8    ; Handoff interface enabled and ready
    sig-es:      16    ; Emergency stop sensor active (low active)
    sig-va:      32    ; Vehicle present optical confirmation

    ;; ------------------------------------------------------------------------
    ;; SEMI E87 Carrier Management System (CMS) Enums
    ;; ------------------------------------------------------------------------
    carrier-id-not-read:    'NOT-READ
    carrier-id-waiting:     'WAITING-FOR-HOST
    carrier-id-ok:          'ID-VERIFIED-OK
    carrier-id-failed:      'ID-VERIFICATION-FAILED

    carrier-access-not:     'NOT-ACCESSED
    carrier-access-in:      'IN-ACCESS
    carrier-access-done:    'CARRIER-COMPLETE
    carrier-access-stopped: 'CARRIER-STOPPED

    slot-state-empty:       'EMPTY
    slot-state-occupied:    'OCCUPIED
    slot-state-double:      'DOUBLE-SLOTTED
    slot-state-cross:       'CROSS-SLOTTED

    ;; ------------------------------------------------------------------------
    ;; AMHS Overhead Hoist Transport (OHT) Vehicle States
    ;; ------------------------------------------------------------------------
    oht-state-idle:          'IDLE
    oht-state-travel-empty:  'TRAVEL-EMPTY
    oht-state-dock-load:     'DOCKING-LOAD
    oht-state-hoist-down:    'HOISTING-DOWN
    oht-state-clamp:         'CLAMPING
    oht-state-hoist-up:      'HOISTING-UP
    oht-state-travel-loaded: 'TRAVEL-LOADED
    oht-state-dock-unload:   'DOCKING-UNLOAD
    oht-state-unclamp:       'UNCLAMPING
    oht-state-charging:      'CHARGING
    oht-state-fault:         'FAULT-ESTOP

    ;; ------------------------------------------------------------------------
    ;; Utility Constructor Functions
    ;; ------------------------------------------------------------------------
    make-secs-item: function [
        "Construct a symbolic typed SECS-II item block"
        format [word!]
        value
    ][
        reduce [format value]
    ]

    make-hsms-header: function [
        "Construct a 10-byte symbolic HSMS header descriptor"
        session-id [integer!]
        stream     [integer!]
        function   [integer!]
        p-type     [integer!]
        s-type     [integer!]
        system-byte [integer!]
    ][
        context [
            session: session-id
            s: stream
            f: function
            p: p-type
            stype: s-type
            sys-id: system-byte
            w-bit: (stream > 0) and ((function and 1) = 1) ; Wait bit true on odd functions
        ]
    ]

    make-carrier-info: function [
        "Construct a FOUP carrier tracking structure"
        carrier-id [string!]
        slot-count [integer!]
    ][
        slots: make block! slot-count
        loop slot-count [append slots slot-state-empty]
        context [
            id: carrier-id
            capacity: slot-count
            id-status: carrier-id-not-read
            access-status: carrier-access-not
            wafer-map: slots
            q-time-start: 0
            q-time-limit: 14400 ; 4 hours max before furnace oxide oxidation
        ]
    ]
]

Red [
    Title: "Reticle SEMI E84 Handshake Diagnostics and Timeout Supervisor"
    Author: "Aneesh"
    File: %diagnostics.red
    Tabs: 4
]

;; ----------------------------------------------------------------------------
;; Reticle: Semiconductor Material Control System & SECS/GEM Engine
;; Module: SEMI E84 Timeout Diagnostics & Fault Interlock Recovery
;;
;; Supervises the strict physical timing limits specified in SEMI E84:
;; - TA1: Time from VALID & CS on to READY on (max 2.0s)
;; - TA2: Time from READY on to TR_REQ on (max 2.0s)
;; - TA3: Time from TR_REQ on to BUSY on (max 2.0s)
;; - TP1: Maximum allowable physical hoist motion duration (max 60.0s)
;; - TP2: Time from BUSY off to COMPT on (max 2.0s)
;; - TP3: Time from COMPT on to READY off (max 2.0s)
;; - TD1: Time from READY off to VALID off (max 2.0s)
;; ----------------------------------------------------------------------------

#include %../core/types.red
#include %interlock.red

reticle-e84-diagnostics: context [

    ;; Maximum allowed duration thresholds (seconds)
    ta1-limit:  2.0
    ta2-limit:  2.0
    ta3-limit:  2.0
    tp1-limit: 60.0
    tp2-limit:  2.0
    tp3-limit:  2.0
    td1-limit:  2.0

    ;; Active timeout stopwatch
    watchdog-timer: 0.0
    active-timeout-id: none
    fault-latched?: false
    fault-reason: none

    ;; Reset diagnostic watchdog
    reset: does [
        watchdog-timer: 0.0
        active-timeout-id: none
        fault-latched?: false
        fault-reason: none
    ]

    ;; Arm watchdog for a specific phase
    arm-watchdog: function [
        timeout-phase [word!]
    ][
        active-timeout-id: timeout-phase
        watchdog-timer: 0.0
        fault-latched?: false
    ]

    ;; Disarm active watchdog
    disarm-watchdog: does [
        active-timeout-id: none
        watchdog-timer: 0.0
    ]

    ;; Advance watchdog timer and detect timeout faults
    step-watchdog: function [
        dt [number!]
        return: [logic!] ; Returns true if safe, false if timeout fault occurred
    ][
        if none? active-timeout-id [return true]

        watchdog-timer: watchdog-timer + dt
        limit: 2.0

        switch active-timeout-id [
            TA1 [limit: ta1-limit]
            TA2 [limit: ta2-limit]
            TA3 [limit: ta3-limit]
            TP1 [limit: tp1-limit]
            TP2 [limit: tp2-limit]
            TP3 [limit: tp3-limit]
            TD1 [limit: td1-limit]
        ]

        if watchdog-timer > limit [
            fault-latched?: true
            fault-reason: rejoin ["E84 Timeout Violation on " active-timeout-id " after " watchdog-timer "s"]
            reticle-e84-interlock/current-step: 'FAULT
            reticle-e84-interlock/fault-message: fault-reason
            return false
        ]
        true
    ]

    ;; Clear latched fault after operator intervention or reset command
    clear-fault: does [
        reset
        reticle-e84-interlock/reset
    ]
]

Red [
    Title: "Reticle SEMI E30 Alarm Registry & State Machine"
    Author: "Aneesh"
    File: %alarms.red
    Tabs: 4
]

;; ----------------------------------------------------------------------------
;; Reticle: Semiconductor Material Control System & SECS/GEM Engine
;; Module: SEMI E30 Alarm Management & Severity Matrix
;;
;; Manages alarm state transitions (SET / CLEAR), enable/disable masking,
;; severity ranking, and automated S5F1 alarm notifications.
;; ----------------------------------------------------------------------------

#include %../core/types.red
#include %../secs/s5-alarms.red

reticle-gem-alarms: context [

    ;; Alarm Severity Constants
    severity-critical: 'CRITICAL ; Immediate emergency stop
    severity-major:    'MAJOR    ; Halts current lot processing
    severity-minor:    'MINOR    ; Continues lot with degraded performance
    severity-warning:  'WARNING  ; Advisory notification

    ;; Alarm Definitions Table: [alid name enabled? is-set? severity text]
    alarm-table: copy [
        501 "VacuumChamberPressureLeak"   true false 'CRITICAL "Chamber pressure rose above 50 mTorr threshold"
        502 "ChuckOverTemperature"        true false 'MAJOR    "Chuck thermal sensor exceeded 28.0 Celsius"
        503 "LaserIlluminationFault"      true false 'CRITICAL "ArF excimer 193nm pulse energy unstable"
        504 "E84HandshakeTimeout"         true false 'MAJOR    "E84 parallel optical transceiver timed out"
        505 "WaferMisalignmentDetected"   true false 'WARNING  "Pre-aligner optical notch detection skew > 15 um"
        506 "FOUPDoorInterlockFailure"    true false 'CRITICAL "FIMS port door seal mechanical interlock broken"
    ]

    ;; Outbound alarm message queue
    alarm-queue: copy []

    ;; Set an alarm condition (transition from CLEAR to SET)
    set-alarm: function [
        alid [integer!]
        return: [block!] ; S5F1 message or empty if disabled/already set
    ][
        idx: 1
        s5f1: copy []
        while [idx <= length? alarm-table] [
            if alarm-table/:idx = alid [
                enabled?: alarm-table/(idx + 2)
                is-set?: alarm-table/(idx + 3)
                altx: alarm-table/(idx + 5)

                if all [enabled? not is-set?] [
                    alarm-table/(idx + 3): true ; Mark as SET
                    ;; ALCD has bit 7 set to 1 (128) for Alarm Set
                    s5f1: reticle-secs-s5/build-s5f1 128 alid altx
                    append/only alarm-queue s5f1
                ]
                break
            ]
            idx: idx + 6
        ]
        s5f1
    ]

    ;; Clear an alarm condition (transition from SET to CLEAR)
    clear-alarm: function [
        alid [integer!]
        return: [block!] ; S5F1 message or empty
    ][
        idx: 1
        s5f1: copy []
        while [idx <= length? alarm-table] [
            if alarm-table/:idx = alid [
                enabled?: alarm-table/(idx + 2)
                is-set?: alarm-table/(idx + 3)
                altx: alarm-table/(idx + 5)

                if all [enabled? is-set?] [
                    alarm-table/(idx + 3): false ; Mark as CLEAR
                    ;; ALCD has bit 7 set to 0 for Alarm Clear
                    s5f1: reticle-secs-s5/build-s5f1 0 alid altx
                    append/only alarm-queue s5f1
                ]
                break
            ]
            idx: idx + 6
        ]
        s5f1
    ]

    ;; Enable or disable an alarm (S5F3)
    set-alarm-enabled: function [
        alid     [integer!]
        enabled? [logic!]
    ][
        idx: 1
        while [idx <= length? alarm-table] [
            if alarm-table/:idx = alid [
                alarm-table/(idx + 2): enabled?
                break
            ]
            idx: idx + 6
        ]
    ]

    ;; List active alarm records for S5F6
    get-active-alarms: function [
        return: [block!]
    ][
        active-list: copy []
        foreach [alid name en set-flag sev txt] alarm-table [
            if set-flag [
                append/only active-list reduce [128 alid txt]
            ]
        ]
        active-list
    ]
]

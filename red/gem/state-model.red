Red [
    Title: "Reticle SEMI E30 GEM State Models"
    Author: "Aneesh"
    File: %state-model.red
    Tabs: 4
]

;; ----------------------------------------------------------------------------
;; Reticle: Semiconductor Material Control System & SECS/GEM Engine
;; Module: SEMI E30 GEM State Models
;;
;; Enforces the three core GEM state machines:
;; 1. Communications State Model:
;;    - DISABLED
;;    - ENABLED (NOT COMMUNICATING, WAIT CRA, COMMUNICATING)
;; 2. Control State Model:
;;    - OFFLINE (EQUIPMENT OFFLINE, ATTEMPT ONLINE, HOST OFFLINE)
;;    - ONLINE (ONLINE LOCAL, ONLINE REMOTE)
;; 3. Processing State Model:
;;    - INIT -> IDLE -> SETUP -> READY -> EXECUTING -> PAUSED -> STOPPING -> IDLE
;; ----------------------------------------------------------------------------

#include %../core/types.red

reticle-gem-state: context [

    ;; ------------------------------------------------------------------------
    ;; Current State Variables
    ;; ------------------------------------------------------------------------
    comm-state:    reticle-core/comm-state-disabled
    control-state: reticle-core/control-state-offline-equipment
    process-state: reticle-core/process-state-init

    ;; State change callback listeners
    on-comm-change: copy []
    on-control-change: copy []
    on-process-change: copy []

    ;; ------------------------------------------------------------------------
    ;; Communications State Transitions
    ;; ------------------------------------------------------------------------
    enable-comm: does [
        if comm-state = reticle-core/comm-state-disabled [
            comm-state: reticle-core/comm-state-enabled-not-communicating
        ]
    ]

    disable-comm: does [
        comm-state: reticle-core/comm-state-disabled
        ;; When communications is disabled, control transitions offline
        set-control-state reticle-core/control-state-offline-equipment
    ]

    set-communicating: does [
        comm-state: reticle-core/comm-state-communicating
    ]

    ;; ------------------------------------------------------------------------
    ;; Control State Transitions
    ;; ------------------------------------------------------------------------
    set-control-state: function [
        new-state [word!]
        return: [logic!]
    ][
        old-state: control-state
        control-state: new-state
        true
    ]

    request-online: function [
        remote? [logic!]
        return: [logic!]
    ][
        if comm-state <> reticle-core/comm-state-communicating [
            return false ; Cannot go online if not communicating
        ]
        target: either remote? [
            reticle-core/control-state-online-remote
        ][
            reticle-core/control-state-online-local
        ]
        set-control-state target
    ]

    request-offline: function [
        host-initiated? [logic!]
        return: [logic!]
    ][
        target: either host-initiated? [
            reticle-core/control-state-offline-host
        ][
            reticle-core/control-state-offline-equipment
        ]
        set-control-state target
    ]

    ;; ------------------------------------------------------------------------
    ;; Processing State Transitions
    ;; ------------------------------------------------------------------------
    set-process-state: function [
        new-state [word!]
        return: [logic!]
    ][
        old-state: process-state
        process-state: new-state
        true
    ]

    start-processing: does [
        if find [READY IDLE] process-state [
            set-process-state reticle-core/process-state-executing
        ]
    ]

    pause-processing: does [
        if process-state = reticle-core/process-state-executing [
            set-process-state reticle-core/process-state-pause
        ]
    ]

    resume-processing: does [
        if process-state = reticle-core/process-state-pause [
            set-process-state reticle-core/process-state-executing
        ]
    ]

    stop-processing: does [
        if find [EXECUTING PAUSED SETUP READY] process-state [
            set-process-state reticle-core/process-state-stopping
            ;; After stop sequence finishes, transitions to IDLE
            set-process-state reticle-core/process-state-idle
        ]
    ]

    abort-processing: does [
        set-process-state reticle-core/process-state-aborting
        set-process-state reticle-core/process-state-idle
    ]
]

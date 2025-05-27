Red [
    Title: "Reticle SECS-II Stream 16 Process & Control Job Handlers"
    Author: "Aneesh"
    File: %s16-jobs.red
    Tabs: 4
]

;; ----------------------------------------------------------------------------
;; Reticle: Semiconductor Material Control System & SECS/GEM Engine
;; Module: Stream 16 (Process Job & Control Job Management) Handlers
;;
;; Coordinates multi-wafer batch execution per SEMI E40 and SEMI E94:
;; - Process Job (PJob) creation, scheduling, recipe binding, and lifecycle
;; - Control Job (CJob) carrier assignment and process order sequencing
;; - Dynamic state transitions (QUEUED, SETTING UP, WAITING FOR START,
;;   EXECUTING, PAUSED, STOPPING, ABORTING, COMPLETED)
;; ----------------------------------------------------------------------------

#include %../core/types.red
#include %../core/item-encoder.red

reticle-secs-s16: context [

    ;; PJob State Machine Enums
    pjob-state-queued:      'QUEUED
    pjob-state-setting-up:  'SETTING-UP
    pjob-state-wait-start:  'WAITING-FOR-START
    pjob-state-executing:   'EXECUTING
    pjob-state-paused:      'PAUSED
    pjob-state-completed:   'COMPLETED
    pjob-state-aborted:     'ABORTED

    ;; Build S16F1: Process Job Multi-Create Request
    build-s16f1: function [
        data-id    [integer!]
        pjob-id    [string!]
        recipe-id  [string!]
        wafers     [block!] ; List of [carrier-id slot-id]
        return:    [block!]
    ][
        wafer-items: copy []
        foreach [c-id s-id] wafers [
            append/only wafer-items reduce ['L reduce [
                reduce ['A c-id]
                reduce ['U1 s-id]
            ]]
        ]

        reduce ['L reduce [
            reduce ['U4 data-id]
            reduce ['L reduce [
                reduce ['L reduce [
                    reduce ['A pjob-id]
                    reduce ['A recipe-id]
                    reduce ['L wafer-items]
                ]]
            ]]
        ]]
    ]

    ;; Build S16F2: Process Job Multi-Create Acknowledge
    build-s16f2: function [
        ack-code [integer!] ; 0 = Accepted
        errors   [block!]
        return:  [block!]
    ][
        err-items: copy []
        foreach err errors [
            append/only err-items reduce ['L reduce [
                reduce ['A first err]
                reduce ['B to-binary to-char (second err)]
            ]]
        ]

        reduce ['L reduce [
            reduce ['B to-binary to-char (ack-code and 255)]
            reduce ['L err-items]
        ]]
    ]

    ;; Build S16F3: Process Job Command Send
    build-s16f3: function [
        data-id      [integer!]
        command-name [string!] ; "Start", "Pause", "Resume", "Cancel", "Abort", "Stop"
        pjob-ids     [block!]  ; List of strings
        return:      [block!]
    ][
        id-items: copy []
        foreach id pjob-ids [
            append/only id-items reduce ['A id]
        ]

        reduce ['L reduce [
            reduce ['U4 data-id]
            reduce ['A command-name]
            reduce ['L id-items]
        ]]
    ]

    ;; Build S16F4: Process Job Command Acknowledge
    build-s16f4: function [
        ack-code [integer!]
        errors   [block!]
        return:  [block!]
    ][
        err-items: copy []
        foreach err errors [
            append/only err-items reduce ['L reduce [
                reduce ['A first err]
                reduce ['B to-binary to-char (second err)]
            ]]
        ]

        reduce ['L reduce [
            reduce ['B to-binary to-char (ack-code and 255)]
            reduce ['L err-items]
        ]]
    ]

    ;; Build S16F11: Control Job Create Request
    build-s16f11: function [
        cjob-id      [string!]
        carrier-id   [string!]
        pjob-list    [block!] ; List of PJob ID strings
        return:      [block!]
    ][
        pjob-items: copy []
        foreach pj pjob-list [
            append/only pjob-items reduce ['A pj]
        ]

        reduce ['L reduce [
            reduce ['A cjob-id]
            reduce ['A carrier-id]
            reduce ['L pjob-items]
        ]]
    ]

    ;; Build S16F12: Control Job Create Acknowledge
    build-s16f12: function [
        ack-code [integer!]
        return:  [block!]
    ][
        reduce ['B to-binary to-char (ack-code and 255)]
    ]
]

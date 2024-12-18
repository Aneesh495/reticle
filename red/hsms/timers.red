Red [
    Title: "Reticle SEMI E37 HSMS Timers & Watchdog Supervisor"
    Author: "Aneesh"
    File: %timers.red
    Tabs: 4
]

;; ----------------------------------------------------------------------------
;; Reticle: Semiconductor Material Control System & SECS/GEM Engine
;; Module: SEMI E37 Protocol Watchdog Timers
;;
;; Manages the five mandatory SEMI E37 timers:
;; - T3: Reply Timeout (time host/equipment waits for secondary reply)
;; - T5: Connection Separation Timeout (minimum inter-connect spacing)
;; - T6: Control Transaction Timeout (timeout for Select/Linktest rsp)
;; - T7: NOT SELECTED Timeout (socket abort timeout if Select.req missing)
;; - T8: Network Inter-character Timeout (packet framing timeout)
;; ----------------------------------------------------------------------------

reticle-hsms-timers: context [

    ;; Default timer limits (in seconds)
    default-t3: 45.0
    default-t5: 10.0
    default-t6:  5.0
    default-t7: 10.0
    default-t8:  5.0

    ;; Active timer instances dictionary: maps [timer-id -> object]
    active-timers: copy []

    ;; Create a new timer context
    make-timer: function [
        timer-id [word! integer!]
        duration [number!]
        callback [block!]
        return: [object!]
    ][
        context [
            id: timer-id
            timeout: duration
            elapsed: 0.0
            expired?: false
            running?: true
            action: callback
        ]
    ]

    ;; Start a named timer
    start: function [
        timer-id [word! integer!]
        duration [number!]
        callback [block!]
    ][
        stop timer-id ; Stop previous instance if exists
        tm: make-timer timer-id duration callback
        append active-timers tm
        tm
    ]

    ;; Cancel/stop an active timer
    stop: function [
        timer-id [word! integer!]
    ][
        remove-each tm active-timers [tm/id = timer-id]
    ]

    ;; Advance time and trigger expired callbacks
    tick: function [
        dt [number!]
        return: [block!] ; List of expired timer IDs
    ][
        expired-list: copy []
        foreach tm active-timers [
            if tm/running? [
                tm/elapsed: tm/elapsed + dt
                if tm/elapsed >= tm/timeout [
                    tm/running?: false
                    tm/expired?: true
                    append expired-list tm/id
                    do tm/action
                ]
            ]
        ]
        ;; Clean up expired timers
        remove-each tm active-timers [tm/expired?]
        expired-list
    ]

    ;; Check if a timer is currently active
    is-running?: function [
        timer-id [word! integer!]
        return: [logic!]
    ][
        found: false
        foreach tm active-timers [
            if all [tm/id = timer-id tm/running?] [found: true break]
        ]
        found
    ]
]

Red [
    Title: "Reticle HSMS Session State Machine"
    Author: "Aneesh"
    File: %session.red
    Tabs: 4
]

;; ----------------------------------------------------------------------------
;; Reticle: Semiconductor Material Control System & SECS/GEM Engine
;; Module: SEMI E37 HSMS Session State Machine
;;
;; Enforces the formal HSMS-SS connection and selection lifecycle:
;; - NOT CONNECTED
;; - NOT SELECTED (TCP established, waiting for Select.req before T7 expiry)
;; - SELECTED (fully operational for SECS-II SxFy data exchange)
;; ----------------------------------------------------------------------------

#include %header.red
#include %timers.red

reticle-hsms-session: context [

    ;; Session States
    state-not-connected: 'NOT-CONNECTED
    state-not-selected:  'NOT-SELECTED
    state-selected:      'SELECTED

    ;; Session Context Variables
    current-state: state-not-connected
    device-id: 1000
    is-passive?: true ; True for equipment / listener, False for host / initiator
    last-error: none

    ;; Handshake response queue
    outgoing-queue: copy []

    ;; Reset session state
    reset: does [
        current-state: state-not-connected
        last-error: none
        clear outgoing-queue
        reticle-hsms-timers/stop 'T7
        reticle-hsms-timers/stop 'T6
    ]

    ;; Event: TCP connection established
    on-tcp-connected: function [
        as-passive [logic!]
    ][
        is-passive?: as-passive
        current-state: state-not-selected
        if is-passive? [
            ;; Equipment starts T7 timer (typically 10s). If Select.req is not
            ;; received before T7 expires, equipment must disconnect the socket.
            reticle-hsms-timers/start 'T7 reticle-hsms-timers/default-t7 [
                reticle-hsms-session/on-t7-timeout
            ]
        ]
    ]

    ;; Event: TCP connection disconnected
    on-tcp-disconnected: does [
        current-state: state-not-connected
        reticle-hsms-timers/stop 'T7
        reticle-hsms-timers/stop 'T6
    ]

    ;; Event: T7 timer expired without Select.req
    on-t7-timeout: does [
        last-error: "T7 NOT SELECTED timeout expired. Disconnecting socket."
        current-state: state-not-connected
    ]

    ;; Event: Inbound HSMS control message received
    process-control-message: function [
        hdr [object!]
        return: [object!] ; Response object or none
    ][
        s-type: hdr/s-type
        sys-bytes: hdr/system-bytes
        res: none

        switch s-type [
            1 [ ;; Select.req
                either current-state = state-selected [
                    ;; Already selected: reply with status 1
                    res: reticle-hsms-header/pack hdr/session 0 0 false 0 2 sys-bytes
                ][
                    ;; Transition to SELECTED, cancel T7 timer
                    reticle-hsms-timers/stop 'T7
                    current-state: state-selected
                    ;; Reply Select.rsp with status 0 (success)
                    res: reticle-hsms-header/pack hdr/session 0 0 false 0 2 sys-bytes
                ]
            ]
            2 [ ;; Select.rsp
                if current-state = state-not-selected [
                    reticle-hsms-timers/stop 'T6
                    current-state: state-selected
                ]
            ]
            3 [ ;; Deselect.req
                current-state: state-not-selected
                ;; Reply Deselect.rsp with status 0
                res: reticle-hsms-header/pack hdr/session 0 0 false 0 4 sys-bytes
            ]
            4 [ ;; Deselect.rsp
                current-state: state-not-selected
            ]
            5 [ ;; Linktest.req
                ;; Reply Linktest.rsp with identical system bytes
                res: reticle-hsms-header/pack hdr/session 0 0 false 0 6 sys-bytes
            ]
            6 [ ;; Linktest.rsp
                reticle-hsms-timers/stop 'T6
            ]
            7 [ ;; Reject.req
                last-error: "Received Reject.req notification from peer."
            ]
            9 [ ;; Separate.req
                current-state: state-not-connected
            ]
        ]
        res
    ]

    ;; Validate whether a data message can be legally processed
    can-send-data?: does [
        current-state = state-selected
    ]
]

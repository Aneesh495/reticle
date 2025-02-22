Red [
    Title: "Reticle SEMI E84 Optical Carrier Handoff Interlock"
    Author: "Aneesh"
    File: %interlock.red
    Tabs: 4
]

;; ----------------------------------------------------------------------------
;; Reticle: Semiconductor Material Control System & SECS/GEM Engine
;; Module: SEMI E84 Carrier Handoff State Machine
;;
;; Enforces the formal bidirectional handshake sequence for FOUP loading
;; and unloading between OHT vehicles (Active) and Equipment Load Ports (Passive).
;; ----------------------------------------------------------------------------

#include %../core/types.red
#include %signals.red

reticle-e84-interlock: context [

    ;; Handshake Step Enumeration
    step-idle:               'IDLE
    step-approach:           'APPROACH
    step-wait-ready:         'WAIT-READY
    step-transfer-active:    'TRANSFER-ACTIVE
    step-wait-port-ack:      'WAIT-PORT-ACK
    step-complete-handshake: 'COMPLETE-HANDSHAKE
    step-fault:              'FAULT

    current-step: step-idle
    mode: 'LOAD ; 'LOAD or 'UNLOAD
    current-foup-id: none
    fault-message: none

    ;; Reset interlock to idle
    reset: does [
        current-step: step-idle
        fault-message: none
        reticle-e84-signals/reset
    ]

    ;; Initiate a Load sequence (OHT delivering FOUP to Load Port)
    initiate-load: function [
        foup-name [string!]
    ][
        mode: 'LOAD
        current-foup-id: foup-name
        current-step: step-approach

        ;; Active asserts: VALID, CS_0 (stage select), AM_AVBL
        active-bits: reticle-e84-signals/pack-active true true false true false false false
        reticle-e84-signals/update-active active-bits 0.050
    ]

    ;; Initiate an Unload sequence (OHT retrieving FOUP from Load Port)
    initiate-unload: function [
        foup-name [string!]
    ][
        mode: 'UNLOAD
        current-foup-id: foup-name
        current-step: step-approach

        ;; Active asserts: VALID, CS_0, AM_AVBL
        active-bits: reticle-e84-signals/pack-active true true false true false false false
        reticle-e84-signals/update-active active-bits 0.050
    ]

    ;; Equipment load port response simulation
    simulate-port-response: function [
        port-ready? [logic!]
    ][
        either mode = 'LOAD [
            ;; Passive asserts: HO_AVBL, L_REQ, and READY when shutters open
            p-bits: reticle-e84-signals/pack-passive true false port-ready? true false true
            reticle-e84-signals/update-passive p-bits 0.050
        ][
            ;; Unload: Passive asserts: HO_AVBL, U_REQ, and READY
            p-bits: reticle-e84-signals/pack-passive false true port-ready? true false true
            reticle-e84-signals/update-passive p-bits 0.050
        ]
    ]

    ;; Step the interlock sequence
    step-handshake: function [
        dt [number!]
        return: [word!] ; Current step
    ][
        switch current-step [
            APPROACH [
                ;; Check if equipment is asserting READY
                if reticle-e84-signals/is-passive-set? reticle-core/sig-ready [
                    current-step: step-transfer-active
                    ;; Assert TR_REQ and BUSY as hoist begins lowering
                    active-bits: reticle-e84-signals/pack-active true true false true true true false
                    reticle-e84-signals/update-active active-bits 0.050
                ]
            ]
            TRANSFER-ACTIVE [
                ;; Physical hoist motion simulated: transition to COMPT
                current-step: step-wait-port-ack
                ;; Deassert TR_REQ and BUSY, assert COMPT
                active-bits: reticle-e84-signals/pack-active true true false true false false true
                reticle-e84-signals/update-active active-bits 0.050
            ]
            WAIT-PORT-ACK [
                ;; Equipment detects COMPT and drops READY to acknowledge
                simulate-port-response false ; Shutter close, drop READY
                if not reticle-e84-signals/is-passive-set? reticle-core/sig-ready [
                    current-step: step-complete-handshake
                    ;; Deassert all active signals
                    active-bits: reticle-e84-signals/pack-active false false false false false false false
                    reticle-e84-signals/update-active active-bits 0.050
                ]
            ]
            COMPLETE-HANDSHAKE [
                current-step: step-idle
            ]
        ]
        current-step
    ]
]

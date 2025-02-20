Red [
    Title: "Reticle SEMI E84 Optical Signal Transceiver"
    Author: "Aneesh"
    File: %signals.red
    Tabs: 4
]

;; ----------------------------------------------------------------------------
;; Reticle: Semiconductor Material Control System & SECS/GEM Engine
;; Module: SEMI E84 Parallel Optical I/O Signal Transceiver
;;
;; Manages active and passive optical bitfields, bitmask packing/unpacking,
;; and 50 ms debounce filtering for cleanroom carrier handoff sensors.
;; ----------------------------------------------------------------------------

#include %../core/types.red

reticle-e84-signals: context [

    ;; Debounce threshold in seconds (cleanroom optical flutter filter)
    debounce-duration: 0.050 ; 50 ms

    ;; Active Transceiver State (OHT Vehicle)
    active-raw-bits: 0
    active-debounced-bits: 0
    active-timer: 0.0

    ;; Passive Transceiver State (Equipment Load Port)
    passive-raw-bits: 0
    passive-debounced-bits: 0
    passive-timer: 0.0

    ;; Reset signals to safe idle state
    reset: does [
        active-raw-bits: 0
        active-debounced-bits: 0
        active-timer: 0.0
        passive-raw-bits: 0
        passive-debounced-bits: 0
        passive-timer: 0.0
    ]

    ;; Pack active signals into an 8-bit integer
    pack-active: function [
        valid   [logic!]
        cs0     [logic!]
        cs1     [logic!]
        am-avbl [logic!]
        tr-req  [logic!]
        busy    [logic!]
        compt   [logic!]
        return: [integer!]
    ][
        b: 0
        if valid   [b: b or reticle-core/sig-valid]
        if cs0     [b: b or reticle-core/sig-cs0]
        if cs1     [b: b or reticle-core/sig-cs1]
        if am-avbl [b: b or reticle-core/sig-am-avbl]
        if tr-req  [b: b or reticle-core/sig-tr-req]
        if busy    [b: b or reticle-core/sig-busy]
        if compt   [b: b or reticle-core/sig-compt]
        b
    ]

    ;; Pack passive signals into an 8-bit integer
    pack-passive: function [
        l-req   [logic!]
        u-req   [logic!]
        ready   [logic!]
        ho-avbl [logic!]
        es      [logic!]
        va      [logic!]
        return: [integer!]
    ][
        b: 0
        if l-req   [b: b or reticle-core/sig-l-req]
        if u-req   [b: b or reticle-core/sig-u-req]
        if ready   [b: b or reticle-core/sig-ready]
        if ho-avbl [b: b or reticle-core/sig-ho-avbl]
        if es      [b: b or reticle-core/sig-es]
        if va      [b: b or reticle-core/sig-va]
        b
    ]

    ;; Update raw active input and apply debounce filter
    update-active: function [
        new-bits [integer!]
        dt       [number!]
    ][
        either new-bits = active-raw-bits [
            active-timer: active-timer + dt
            if active-timer >= debounce-duration [
                active-debounced-bits: new-bits
            ]
        ][
            active-raw-bits: new-bits
            active-timer: 0.0
        ]
    ]

    ;; Update raw passive input and apply debounce filter
    update-passive: function [
        new-bits [integer!]
        dt       [number!]
    ][
        either new-bits = passive-raw-bits [
            passive-timer: passive-timer + dt
            if passive-timer >= debounce-duration [
                passive-debounced-bits: new-bits
            ]
        ][
            passive-raw-bits: new-bits
            passive-timer: 0.0
        ]
    ]

    ;; Check if specific active signal is asserted (debounced)
    is-active-set?: function [
        bitmask [integer!]
        return: [logic!]
    ][
        (active-debounced-bits and bitmask) = bitmask
    ]

    ;; Check if specific passive signal is asserted (debounced)
    is-passive-set?: function [
        bitmask [integer!]
        return: [logic!]
    ][
        (passive-debounced-bits and bitmask) = bitmask
    ]
]

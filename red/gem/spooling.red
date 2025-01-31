Red [
    Title: "Reticle SEMI E30 Message Spooling Engine"
    Author: "Aneesh"
    File: %spooling.red
    Tabs: 4
]

;; ----------------------------------------------------------------------------
;; Reticle: Semiconductor Material Control System & SECS/GEM Engine
;; Module: SEMI E30 Offline Message Spooling Engine
;;
;; Preserves critical collection events and alarm history during communications
;; outages with bounded memory queues and deterministic unspooling replay.
;; ----------------------------------------------------------------------------

#include %../core/types.red

reticle-gem-spooling: context [

    ;; Spool States
    spool-state-inactive:   'INACTIVE
    spool-state-spooling:   'SPOOLING
    spool-state-unspooling: 'UNSPOOLING

    current-state: spool-state-inactive
    max-spool-depth: 1000
    spool-queue: copy []
    total-spooled-count: 0
    overflow-policy: 'DISCARD-OLDEST

    ;; Activate spooling when communications drop
    activate-spooling: does [
        current-state: spool-state-spooling
    ]

    ;; Enqueue a message into spool
    enqueue: function [
        msg [block!]
        return: [logic!]
    ][
        if current-state <> spool-state-spooling [return false]

        if (length? spool-queue) >= max-spool-depth [
            either overflow-policy = 'DISCARD-OLDEST [
                take spool-queue ; Remove oldest
            ][
                return false ; Reject newest
            ]
        ]

        append/only spool-queue msg
        total-spooled-count: total-spooled-count + 1
        true
    ]

    ;; Begin unspooling when communications are restored
    begin-unspooling: does [
        if not empty? spool-queue [
            current-state: spool-state-unspooling
        ]
    ]

    ;; Dequeue next message for transmission
    pop-next: function [
        return: [block!]
    ][
        either empty? spool-queue [
            current-state: spool-state-inactive
            none
        ][
            take spool-queue
        ]
    ]

    ;; Purge all spooled messages
    purge: does [
        clear spool-queue
        current-state: spool-state-inactive
    ]

    ;; Get current depth of spool buffer
    depth?: does [
        length? spool-queue
    ]
]

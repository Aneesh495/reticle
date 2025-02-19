Red [
    Title: "Reticle AMHS Cleanroom Automated Stocker & Buffer Storage"
    Author: "Aneesh"
    File: %stocker.red
    Tabs: 4
]

;; ----------------------------------------------------------------------------
;; Reticle: Semiconductor Material Control System & SECS/GEM Engine
;; Module: Cleanroom Automated Stocker & Buffer Storage Management
;;
;; Manages high-density cleanroom wafer stockers:
;; - Internal vertical carousel and robotic crane storage slots
;; - Cleanroom Side-Track Buffers (STB) and Overhead Buffers (OHB)
;; - Inbound staging, lot retrieval, and empty FOUP inventory balancing
;; ----------------------------------------------------------------------------

#include %../core/types.red

reticle-amhs-stocker: context [

    ;; Stocker Storage Slot Structure: [slot-id carrier-id status lot-name recipe-name]
    slot-state-empty:     'EMPTY
    slot-state-occupied:  'OCCUPIED
    slot-state-reserved:  'RESERVED

    stockers: copy []

    ;; Create an automated cleanroom stocker instance
    make-stocker: function [
        stocker-id [integer!]
        name-str   [string!]
        slot-count [integer!]
        port-node  [integer!]
        return:    [object!]
    ][
        slots: make block! slot-count
        loop slot-count [
            append/only slots reduce [
                (length? slots + 1) ; slot-id
                none                ; carrier-id
                slot-state-empty    ; status
                none                ; lot-name
                none                ; recipe-name
            ]
        ]

        context [
            id: stocker-id
            name: name-str
            capacity: slot-count
            load-port-node: port-node
            storage-slots: slots
            inbound-queue: copy []
            outbound-queue: copy []
        ]
    ]

    ;; Initialize default fab stockers
    init-stockers: does [
        clear stockers
        append stockers make-stocker 1 "STOCKER-LITHO-CENTRAL" 64 17
        append stockers make-stocker 2 "STOCKER-ETCH-CENTRAL"  64 18
    ]

    ;; Allocate an empty storage slot for an incoming FOUP carrier
    allocate-slot: function [
        stk-id     [integer!]
        carrier-id [string!]
        lot-id     [string!]
        recipe     [string!]
        return:    [integer!] ; Allocated slot ID or -1 if full
    ][
        stk: none
        foreach s stockers [if s/id = stk-id [stk: s break]]
        if none? stk [return -1]

        allocated-id: -1
        foreach slot stk/storage-slots [
            if slot/3 = slot-state-empty [
                slot/2: carrier-id
                slot/3: slot-state-occupied
                slot/4: lot-id
                slot/5: recipe
                allocated-id: slot/1
                break
            ]
        ]
        allocated-id
    ]

    ;; Release a storage slot when FOUP is retrieved for processing
    release-slot: function [
        stk-id     [integer!]
        carrier-id [string!]
        return:    [logic!]
    ][
        stk: none
        foreach s stockers [if s/id = stk-id [stk: s break]]
        if none? stk [return false]

        released?: false
        foreach slot stk/storage-slots [
            if slot/2 = carrier-id [
                slot/2: none
                slot/3: slot-state-empty
                slot/4: none
                slot/5: none
                released?: true
                break
            ]
        ]
        released?
    ]

    ;; Count occupied slots in a stocker
    occupied-count: function [
        stk-id [integer!]
        return: [integer!]
    ][
        stk: none
        foreach s stockers [if s/id = stk-id [stk: s break]]
        if none? stk [return 0]

        cnt: 0
        foreach slot stk/storage-slots [
            if slot/3 = slot-state-occupied [cnt: cnt + 1]
        ]
        cnt
    ]
]

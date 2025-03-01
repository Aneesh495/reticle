Red [
    Title: "Reticle SEMI E87 Wafer Slot Map Verification"
    Author: "Aneesh"
    File: %slot-map.red
    Tabs: 4
]

;; ----------------------------------------------------------------------------
;; Reticle: Semiconductor Material Control System & SECS/GEM Engine
;; Module: SEMI E87 25-Slot Wafer Map Verification & Defect Detection
;;
;; Validates wafer presence and orientation across 25 FOUP shelf positions:
;; - EMPTY: Slot shelf vacant
;; - CORRECTLY OCCUPIED: Single wafer seated flat on alignment teeth
;; - DOUBLE SLOTTED: Two wafer substrates erroneously placed in single slot
;; - CROSS SLOTTED: Wafer resting diagonally across two adjacent slot shelves
;; ----------------------------------------------------------------------------

#include %../core/types.red

reticle-e87-slotmap: context [

    ;; Standard 300mm FOUP slot capacity
    foup-slot-capacity: 25

    ;; Create an empty 25-slot map
    make-empty-map: function [
        return: [block!]
    ][
        map: make block! foup-slot-capacity
        loop foup-slot-capacity [append map reticle-core/slot-state-empty]
        map
    ]

    ;; Create a fully occupied 25-slot map (normal production lot)
    make-full-map: function [
        return: [block!]
    ][
        map: make block! foup-slot-capacity
        loop foup-slot-capacity [append map reticle-core/slot-state-occupied]
        map
    ]

    ;; Set individual slot condition
    set-slot: function [
        slot-map [block!]
        slot-idx [integer!]
        state    [word!]
    ][
        if all [slot-idx >= 1 slot-idx <= foup-slot-capacity] [
            slot-map/:slot-idx: state
        ]
    ]

    ;; Validate slot map integrity: checks for double-slotting or cross-slotting
    validate-slotmap: function [
        slot-map [block!]
        return:  [block!] ; [is-valid? defect-count defect-descriptions]
    ][
        defects: copy []
        idx: 1
        foreach slot slot-map [
            if slot = reticle-core/slot-state-double [
                append defects rejoin ["Double-slotted wafer detected at slot " idx]
            ]
            if slot = reticle-core/slot-state-cross [
                append defects rejoin ["Cross-slotted tilted wafer detected at slot " idx]
            ]
            idx: idx + 1
        ]

        is-valid?: empty? defects
        reduce [is-valid? (length? defects) defects]
    ]

    ;; Count occupied wafers in slot map
    count-wafers: function [
        slot-map [block!]
        return:  [integer!]
    ][
        cnt: 0
        foreach slot slot-map [
            if find [OCCUPIED DOUBLE-SLOTTED CROSS-SLOTTED] slot [
                cnt: cnt + 1
            ]
        ]
        cnt
    ]
]

Red [
    Title: "Reticle SEMI E87 Carrier Management System (CMS)"
    Author: "Aneesh"
    File: %carrier.red
    Tabs: 4
]

;; ----------------------------------------------------------------------------
;; Reticle: Semiconductor Material Control System & SECS/GEM Engine
;; Module: SEMI E87 Carrier Management System (CMS)
;;
;; Enforces FOUP carrier lifecycle states:
;; - Carrier ID Verification: NOT READ -> WAITING FOR HOST -> ID VERIFIED OK
;; - Carrier Accessing: NOT ACCESSED -> IN ACCESS -> CARRIER COMPLETE
;; - Clamping and docking interlocks on equipment load ports
;; ----------------------------------------------------------------------------

#include %../core/types.red

reticle-e87-carrier: context [

    ;; Carrier Registry Table: maps carrier-id -> carrier object
    carriers: copy []

    ;; Register or update a FOUP carrier in the CMS
    register-carrier: function [
        carrier-id   [string!]
        slot-count   [integer!]
        lot-name     [string!]
        recipe-name  [string!]
        return:      [object!]
    ][
        c: reticle-core/make-carrier-info carrier-id slot-count
        append carriers context [
            info: c
            lot: lot-name
            recipe: recipe-name
            clamped?: false
            docked?: false
            port-id: none
        ]
        last carriers
    ]

    ;; Find carrier by ID string
    find-carrier: function [
        carrier-id [string!]
        return:    [object!]
    ][
        res: none
        foreach c carriers [
            if c/info/id = carrier-id [res: c break]
        ]
        res
    ]

    ;; Optical barcode / RFID scan event: transitions ID status to WAITING FOR HOST
    on-carrier-id-read: function [
        carrier-id [string!]
    ][
        c: find-carrier carrier-id
        if c [
            c/info/id-status: reticle-core/carrier-id-waiting
        ]
    ]

    ;; Host validates carrier ID (via S3F17 or S14F9): transitions to ID VERIFIED OK
    confirm-carrier-id: function [
        carrier-id [string!]
        is-valid?  [logic!]
    ][
        c: find-carrier carrier-id
        if c [
            c/info/id-status: either is-valid? [
                reticle-core/carrier-id-ok
            ][
                reticle-core/carrier-id-failed
            ]
        ]
    ]

    ;; Clamp FOUP onto load port kinematic alignment pins
    clamp-carrier: function [
        carrier-id [string!]
        port-name  [string!]
        return:    [logic!]
    ][
        c: find-carrier carrier-id
        if c [
            c/clamped?: true
            c/port-id: port-name
            return true
        ]
        false
    ]

    ;; Dock FOUP (open FIMS mini-environment door)
    dock-carrier: function [
        carrier-id [string!]
        return:    [logic!]
    ][
        c: find-carrier carrier-id
        if all [c c/clamped? c/info/id-status = reticle-core/carrier-id-ok] [
            c/docked?: true
            c/info/access-status: reticle-core/carrier-access-in
            return true
        ]
        false
    ]

    ;; Undock and unclamp FOUP
    undock-carrier: function [
        carrier-id [string!]
        return:    [logic!]
    ][
        c: find-carrier carrier-id
        if c [
            c/docked?: false
            c/info/access-status: reticle-core/carrier-access-done
            c/clamped?: false
            return true
        ]
        false
    ]
]

Red [
    Title: "Reticle SEMI E90 Substrate Tracking Engine"
    Author: "Aneesh"
    File: %substrate.red
    Tabs: 4
]

;; ----------------------------------------------------------------------------
;; Reticle: Semiconductor Material Control System & SECS/GEM Engine
;; Module: SEMI E90 Substrate Tracking & Chamber Routing
;;
;; Tracks individual 300mm silicon wafers as they transfer through cleanroom equipment:
;; - Substrate Locations:
;;   * FOUP Carrier Slot
;;   * Atmospheric Transfer Robot Arm (EFEM)
;;   * Optical Pre-Aligner Notch Station
;;   * Vacuum Loadlock Chamber
;;   * Vacuum Core Transfer Robot Arm
;;   * Processing Chuck / Exposure Station
;; ----------------------------------------------------------------------------

#include %../core/types.red

reticle-e90-substrate: context [

    ;; Substrate Location Constants
    loc-foup-slot:       'FOUP-SLOT
    loc-efem-robot:      'EFEM-ROBOT-ARM
    loc-prealigner:      'PREALIGNER
    loc-loadlock-in:     'LOADLOCK-IN
    loc-vacuum-robot:    'VACUUM-ROBOT-ARM
    loc-process-chuck:   'PROCESS-CHUCK
    loc-loadlock-out:    'LOADLOCK-OUT

    ;; Substrate Status Constants
    status-not-processed: 'NOT-PROCESSED
    status-in-process:    'IN-PROCESS
    status-processed:     'PROCESSED
    status-rejected:      'REJECTED

    ;; Active Substrates Registry: list of objects
    substrates: copy []

    ;; Register a wafer substrate
    register-wafer: function [
        wafer-id    [string!]
        lot-name    [string!]
        foup-name   [string!]
        slot-number [integer!]
        recipe-name [string!]
        return:     [object!]
    ][
        w: context [
            id: wafer-id
            lot: lot-name
            carrier: foup-name
            slot: slot-number
            recipe: recipe-name
            location: loc-foup-slot
            status: status-not-processed
            exposure-dose: 0.0
            transfer-history: copy [loc-foup-slot]
        ]
        append substrates w
        w
    ]

    ;; Find wafer substrate by ID
    find-wafer: function [
        wafer-id [string!]
        return:  [object!]
    ][
        res: none
        foreach w substrates [
            if w/id = wafer-id [res: w break]
        ]
        res
    ]

    ;; Move wafer to a new chamber location
    transfer-wafer: function [
        wafer-id     [string!]
        new-location [word!]
        return:      [logic!]
    ][
        w: find-wafer wafer-id
        if w [
            w/location: new-location
            append w/transfer-history new-location
            return true
        ]
        false
    ]

    ;; Mark wafer processing state
    update-status: function [
        wafer-id   [string!]
        new-status [word!]
    ][
        w: find-wafer wafer-id
        if w [
            w/status: new-status
        ]
    ]
]

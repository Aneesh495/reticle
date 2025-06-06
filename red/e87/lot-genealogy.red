Red [
    Title: "Reticle SEMI E87 Lot Genealogy & Process History Tracker"
    Author: "Aneesh"
    File: %lot-genealogy.red
    Tabs: 4
]

;; ----------------------------------------------------------------------------
;; Reticle: Semiconductor Material Control System & SECS/GEM Engine
;; Module: 300mm Wafer Lot Genealogy & Manufacturing Execution History
;;
;; Tracks multi-layer silicon fabrication genealogy:
;; - Active Area Lithography (ACT)
;; - Polysilicon Gate Formation (POLY)
;; - Contact Tungsten Plugs (CONT)
;; - Copper Dual-Damascene Metallization (M1..M12)
;; - Cumulative cleanroom Q-time and defect density history
;; ----------------------------------------------------------------------------

#include %../core/types.red

reticle-e87-genealogy: context [

    ;; Process Layer Flow Steps
    layer-flow: copy [
        "L01_SHALLOW_TRENCH_ISOLATION"
        "L02_WELL_IMPLANTATION"
        "L03_GATE_OXIDE_DIFFUSION"
        "L04_POLYSILICON_GATE_LITHO"
        "L05_POLYSILICON_GATE_ETCH"
        "L06_SPACER_DEPOSITION"
        "L07_SOURCE_DRAIN_IMPLANT"
        "L08_INTERLAYER_DIELECTRIC"
        "L09_CONTACT_TUNGSTEN_PLUG"
        "L10_COPPER_METAL_1_DAMASCENE"
    ]

    ;; Lot History Table: maps lot-id -> lot object
    lot-records: copy []

    ;; Register a new wafer lot
    create-lot: function [
        lot-id       [string!]
        product-code [string!]
        wafer-count  [integer!]
        carrier-id   [string!]
        return:      [object!]
    ][
        rec: context [
            id: lot-id
            product: product-code
            wafers: wafer-count
            carrier: carrier-id
            current-layer-idx: 1
            completed-layers: copy []
            cumulative-qtime-sec: 0.0
            defect-count: 0
            created-timestamp: "20210601000000"
        ]
        append lot-records rec
        rec
    ]

    ;; Advance lot to next manufacturing layer
    advance-layer: function [
        lot-id [string!]
        return: [logic!]
    ][
        lot: none
        foreach l lot-records [if l/id = lot-id [lot: l break]]
        if none? lot [return false]

        if lot/current-layer-idx <= length? layer-flow [
            finished-layer: pick layer-flow lot/current-layer-idx
            append lot/completed-layers finished-layer
            lot/current-layer-idx: lot/current-layer-idx + 1
            return true
        ]
        false
    ]

    ;; Query current layer for a lot
    current-layer: function [
        lot-id [string!]
        return: [string!]
    ][
        lot: none
        foreach l lot-records [if l/id = lot-id [lot: l break]]
        if none? lot [return "UNKNOWN"]

        either lot/current-layer-idx <= length? layer-flow [
            pick layer-flow lot/current-layer-idx
        ][
            "FABRICATION_COMPLETED"
        ]
    ]
]

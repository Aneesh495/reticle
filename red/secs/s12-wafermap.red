Red [
    Title: "Reticle SECS-II Stream 12 Wafer Map & Die Binning Handlers"
    Author: "Aneesh"
    File: %s12-wafermap.red
    Tabs: 4
]

;; ----------------------------------------------------------------------------
;; Reticle: Semiconductor Material Control System & SECS/GEM Engine
;; Module: Stream 12 (Wafer Mapping & Die Binning) Handlers
;;
;; Manages coordinate grid mapping, die defect binning, flat/notch orientation,
;; and probe inspection data exchange per SEMI E5 and E142.
;; ----------------------------------------------------------------------------

#include %../core/types.red
#include %../core/item-encoder.red

reticle-secs-s12: context [

    ;; Wafer Map Bin Quality Codes
    bin-good:        1 ; Passed all electrical tests
    bin-functional:  2 ; Functional with non-critical degradation
    bin-parametric:  3 ; Parametric voltage threshold failure
    bin-leakage:     4 ; Gate dielectric leakage failure
    bin-open-circuit: 5 ; Metal interconnect open circuit
    bin-short-circuit: 6 ; Short between adjacent metal tracks
    bin-edge-die:    7 ; Incomplete edge die
    bin-optical-defect: 8 ; Visual particulate defect

    ;; Build S12F1: Map Setup Data Send
    build-s12f1: function [
        wafer-id    [string!]
        die-size-x  [number!] ; mm
        die-size-y  [number!] ; mm
        flat-angle  [integer!] ; Notch orientation: 0, 90, 180, 270 degrees
        origin-loc  [integer!] ; 1 = Center, 2 = Upper-left, 3 = Lower-left
        rows        [integer!]
        columns     [integer!]
        return:     [block!]
    ][
        reduce ['L reduce [
            reduce ['A wafer-id]
            reduce ['F4 die-size-x]
            reduce ['F4 die-size-y]
            reduce ['U2 flat-angle]
            reduce ['U1 origin-loc]
            reduce ['U2 rows]
            reduce ['U2 columns]
        ]]
    ]

    ;; Build S12F2: Map Setup Acknowledge
    build-s12f2: function [
        ack-code [integer!] ; 0 = Accepted
        return:  [block!]
    ][
        reduce ['B to-binary to-char (ack-code and 255)]
    ]

    ;; Build S12F3: Map Data Request
    build-s12f3: function [
        wafer-id [string!]
        map-type [integer!] ; 1 = Grid, 2 = Array, 3 = Coordinate
        return:  [block!]
    ][
        reduce ['L reduce [
            reduce ['A wafer-id]
            reduce ['U1 map-type]
        ]]
    ]

    ;; Build S12F4: Map Data Transmit
    build-s12f4: function [
        wafer-id    [string!]
        die-records [block!] ; List of [x y bin-code]
        return:     [block!]
    ][
        die-items: copy []
        foreach [x y bin] die-records [
            append/only die-items reduce ['L reduce [
                reduce ['I2 x]
                reduce ['I2 y]
                reduce ['U1 bin]
            ]]
        ]

        reduce ['L reduce [
            reduce ['A wafer-id]
            reduce ['L die-items]
        ]]
    ]

    ;; Build S12F5: Map Data Send (Primary from Equipment to Host)
    build-s12f5: function [
        wafer-id [string!]
        lot-id   [string!]
        lot-bin  [block!]
        return:  [block!]
    ][
        reduce ['L reduce [
            reduce ['A wafer-id]
            reduce ['A lot-id]
            reduce ['L lot-bin]
        ]]
    ]

    ;; Build S12F6: Map Data Acknowledge
    build-s12f6: function [
        ack-code [integer!]
        return:  [block!]
    ][
        reduce ['B to-binary to-char (ack-code and 255)]
    ]
]

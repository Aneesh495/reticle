Red [
    Title: "Reticle SECS-II Stream 3 Material Status Handlers"
    Author: "Aneesh"
    File: %s3-material.red
    Tabs: 4
]

;; ----------------------------------------------------------------------------
;; Reticle: Semiconductor Material Control System & SECS/GEM Engine
;; Module: Stream 3 (Material & Carrier Status) Handlers
;;
;; Coordinates FOUP carrier action requests, dock/undock cycles, clamp/unclamp
;; mechanisms, and carrier RFID/barcode tag verification per SEMI E87.
;; ----------------------------------------------------------------------------

#include %../core/types.red
#include %../core/item-encoder.red

reticle-secs-s3: context [

    ;; Carrier Action Acknowledge codes (CAACK)
    caack-ok:              0 ; Acknowledged, command will be executed
    caack-invalid-command: 1 ; Invalid action command
    caack-cannot-perform:  2 ; Cannot perform action in current carrier state
    caack-invalid-data:    3 ; Invalid parameter or carrier ID
    caack-rejected:        4 ; Action rejected by equipment safety interlock

    ;; Build S3F17: Carrier Action Request
    build-s3f17: function [
        data-id      [integer!]
        carrier-id   [string!]
        action-spec  [string!] ; "Clamp", "Unclamp", "Dock", "Undock", "ReadID"
        port-id      [string!]
        return:      [block!]
    ][
        reduce ['L reduce [
            reduce ['U4 data-id]
            reduce ['A carrier-id]
            reduce ['A action-spec]
            reduce ['L reduce [
                reduce ['L reduce [
                    reduce ['A "PortID"]
                    reduce ['A port-id]
                ]]
            ]]
        ]]
    ]

    ;; Build S3F18: Carrier Action Acknowledge
    build-s3f18: function [
        caack-code [integer!]
        errors     [block!]
        return:    [block!]
    ][
        err-items: copy []
        foreach err errors [
            append/only err-items reduce ['L reduce [
                reduce ['A first err]
                reduce ['B to-binary to-char (second err)]
            ]]
        ]
        reduce ['L reduce [
            reduce ['B to-binary to-char (caack-code and 255)]
            reduce ['L err-items]
        ]]
    ]

    ;; Build S3F27: Carrier Tag Read Request
    build-s3f27: function [
        carrier-id [string!]
        tag-data   [string!]
        return:    [block!]
    ][
        reduce ['L reduce [
            reduce ['A carrier-id]
            reduce ['A tag-data]
        ]]
    ]

    ;; Build S3F28: Carrier Tag Read Acknowledge
    build-s3f28: function [
        status-code [integer!]
        carrier-id  [string!]
        tag-payload [string!]
        return:     [block!]
    ][
        reduce ['L reduce [
            reduce ['B to-binary to-char (status-code and 255)]
            reduce ['A carrier-id]
            reduce ['A tag-payload]
        ]]
    ]
]

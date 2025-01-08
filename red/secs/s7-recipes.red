Red [
    Title: "Reticle SECS-II Stream 7 Process Program Recipe Handlers"
    Author: "Aneesh"
    File: %s7-recipes.red
    Tabs: 4
]

;; ----------------------------------------------------------------------------
;; Reticle: Semiconductor Material Control System & SECS/GEM Engine
;; Module: Stream 7 (Process Program Management) Handlers
;;
;; Manages photolithography and etch recipe uploads, downloads, space inquiries,
;; deletions, and directory audits per SEMI E5 and E30.
;; ----------------------------------------------------------------------------

#include %../core/types.red
#include %../core/item-encoder.red

reticle-secs-s7: context [

    ;; Grant codes for S7F2
    ppgnt-ok:          0 ; Space available, permission granted
    ppgnt-already-have: 1 ; Already have recipe with identical name
    ppgnt-no-space:    2 ; Insufficient storage space on equipment
    ppgnt-invalid-ppid: 3 ; Recipe name syntax invalid

    ;; Acknowledge codes for S7F4
    ackc7-ok:          0 ; Recipe accepted and verified
    ackc7-denied:      1 ; Recipe rejected (syntax error or parameter out of bounds)
    ackc7-checksum-err: 2 ; Recipe body checksum mismatch

    ;; Build S7F1: Process Program Load Inquire
    build-s7f1: function [
        recipe-name [string!]
        byte-length [integer!]
        return:     [block!]
    ][
        reduce ['L reduce [
            reduce ['A recipe-name]
            reduce ['U4 byte-length]
        ]]
    ]

    ;; Build S7F2: Process Program Load Grant
    build-s7f2: function [
        grant-code [integer!]
        return:    [block!]
    ][
        reduce ['B to-binary to-char (grant-code and 255)]
    ]

    ;; Build S7F3: Process Program Send
    build-s7f3: function [
        recipe-name [string!]
        recipe-body [binary!]
        return:     [block!]
    ][
        reduce ['L reduce [
            reduce ['A recipe-name]
            reduce ['B recipe-body]
        ]]
    ]

    ;; Build S7F4: Process Program Acknowledge
    build-s7f4: function [
        ack-code [integer!]
        return:  [block!]
    ][
        reduce ['B to-binary to-char (ack-code and 255)]
    ]

    ;; Build S7F6: Process Program Data
    build-s7f6: function [
        recipe-name [string!]
        recipe-body [binary!]
        return:     [block!]
    ][
        reduce ['L reduce [
            reduce ['A recipe-name]
            reduce ['B recipe-body]
        ]]
    ]

    ;; Build S7F19: Current EPPD Request
    build-s7f19: function [
        return: [block!]
    ][
        reduce ['L copy []]
    ]

    ;; Build S7F20: Current EPPD Data reply
    build-s7f20: function [
        recipe-names [block!] ; List of strings
        return:       [block!]
    ][
        items: copy []
        foreach name recipe-names [
            append/only items reduce ['A name]
        ]
        reduce ['L items]
    ]
]

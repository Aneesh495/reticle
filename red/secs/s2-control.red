Red [
    Title: "Reticle SECS-II Stream 2 Equipment Control Handlers"
    Author: "Aneesh"
    File: %s2-control.red
    Tabs: 4
]

;; ----------------------------------------------------------------------------
;; Reticle: Semiconductor Material Control System & SECS/GEM Engine
;; Module: Stream 2 (Equipment Control & Configuration) Handlers
;;
;; Handles host commands, equipment constants, date/time synchronization,
;; report definitions, and event report linkages per SEMI E5 and E30.
;; ----------------------------------------------------------------------------

#include %../core/types.red
#include %../core/item-encoder.red

reticle-secs-s2: context [

    ;; Host command execution status codes (HCACK)
    hcack-ok:              0 ; Command executed successfully
    hcack-unknown-command: 1 ; Command does not exist
    hcack-cannot-perform:  2 ; Cannot perform in current state
    hcack-parameter-invalid: 3 ; At least one parameter is invalid
    hcack-deferred:        4 ; Acknowledged, completion will be signaled later
    hcack-rejected:        5 ; Rejected, already in requested state

    ;; Build S2F14: Equipment Constant Data reply
    build-s2f14: function [
        ec-values [block!]
        return: [block!]
    ][
        items: copy []
        foreach val ec-values [
            either string? val [
                append/only items reduce ['A val]
            ][
                append/only items reduce ['U4 to-integer val]
            ]
        ]
        reduce ['L items]
    ]

    ;; Build S2F16: New Equipment Constant Acknowledge
    build-s2f16: function [
        eack [integer!] ; 0 = Accepted
        return: [block!]
    ][
        reduce ['B to-binary to-char (eack and 255)]
    ]

    ;; Build S2F18: Date and Time Data reply
    build-s2f18: function [
        timestamp-str [string!] ; Format: YYYYMMDDHHMMSS
        return: [block!]
    ][
        reduce ['A timestamp-str]
    ]

    ;; Build S2F32: Date and Time Set Acknowledge
    build-s2f32: function [
        tiack [integer!] ; 0 = Accepted
        return: [block!]
    ][
        reduce ['B to-binary to-char (tiack and 255)]
    ]

    ;; Build S2F34: Define Report Acknowledge
    build-s2f34: function [
        drack [integer!] ; 0 = Accepted
        return: [block!]
    ][
        reduce ['B to-binary to-char (drack and 255)]
    ]

    ;; Build S2F36: Link Event Report Acknowledge
    build-s2f36: function [
        lrack [integer!] ; 0 = Accepted
        return: [block!]
    ][
        reduce ['B to-binary to-char (lrack and 255)]
    ]

    ;; Build S2F38: Enable/Disable Event Report Acknowledge
    build-s2f38: function [
        erack [integer!] ; 0 = Accepted
        return: [block!]
    ][
        reduce ['B to-binary to-char (erack and 255)]
    ]

    ;; Build S2F41: Host Command Send
    build-s2f41: function [
        command-name [string!]
        parameters   [block!] ; List of [name value] pairs
        return:      [block!]
    ][
        param-items: copy []
        foreach [p-name p-val] parameters [
            append/only param-items reduce ['L reduce [
                reduce ['A p-name]
                reduce ['A form p-val]
            ]]
        ]
        reduce ['L reduce [
            reduce ['A command-name]
            reduce ['L param-items]
        ]]
    ]

    ;; Build S2F42: Host Command Acknowledge
    build-s2f42: function [
        hcack-code [integer!]
        param-errors [block!] ; List of invalid parameters
        return: [block!]
    ][
        err-items: copy []
        foreach p param-errors [
            append/only err-items reduce ['L reduce [
                reduce ['A first p]
                reduce ['B to-binary to-char (second p)]
            ]]
        ]
        reduce ['L reduce [
            reduce ['B to-binary to-char (hcack-code and 255)]
            reduce ['L err-items]
        ]]
    ]
]

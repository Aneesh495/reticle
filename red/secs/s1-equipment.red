Red [
    Title: "Reticle SECS-II Stream 1 Equipment Status Handlers"
    Author: "Aneesh"
    File: %s1-equipment.red
    Tabs: 4
]

;; ----------------------------------------------------------------------------
;; Reticle: Semiconductor Material Control System & SECS/GEM Engine
;; Module: Stream 1 (Equipment Status) Message Handlers
;;
;; Handles connectivity verification, status variable queries, communications
;; establishment, and online/offline transitions per SEMI E5 and E30.
;; ----------------------------------------------------------------------------

#include %../core/types.red
#include %../core/item-encoder.red

reticle-secs-s1: context [

    ;; Equipment identification metadata
    model-name: "RETICLE-300MM-STEPPER"
    software-rev: "4.2.0-RELEASE"

    ;; Build S1F2: Are You Online Data reply
    build-s1f2: function [
        return: [block!]
    ][
        reduce ['L reduce [
            reduce ['A model-name]
            reduce ['A software-rev]
        ]]
    ]

    ;; Build S1F4: Selected Status Data reply
    build-s1f4: function [
        sv-values [block!] ; List of values
        return: [block!]
    ][
        items: copy []
        foreach val sv-values [
            either string? val [
                append/only items reduce ['A val]
            ][
                append/only items reduce ['U4 to-integer val]
            ]
        ]
        reduce ['L items]
    ]

    ;; Build S1F13: Establish Communications Request
    build-s1f13: function [
        return: [block!]
    ][
        reduce ['L reduce [
            reduce ['A model-name]
            reduce ['A software-rev]
        ]]
    ]

    ;; Build S1F14: Establish Communications Acknowledge
    build-s1f14: function [
        comm-ack [integer!] ; 0 = Accepted, 1 = Denied
        return: [block!]
    ][
        reduce ['L reduce [
            reduce ['B to-binary to-char (comm-ack and 255)]
            reduce ['L reduce [
                reduce ['A model-name]
                reduce ['A software-rev]
            ]]
        ]]
    ]

    ;; Build S1F16: Request Offline Acknowledge
    build-s1f16: function [
        ack-code [integer!] ; 0 = Offline acknowledged
        return: [block!]
    ][
        reduce ['B to-binary to-char (ack-code and 255)]
    ]

    ;; Build S1F18: Request Online Acknowledge
    build-s1f18: function [
        onl-ack [integer!] ; 0 = Online accepted, 1 = Not allowed, 2 = Performing transition
        return: [block!]
    ][
        reduce ['B to-binary to-char (onl-ack and 255)]
    ]
]

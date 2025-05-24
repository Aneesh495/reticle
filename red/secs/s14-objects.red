Red [
    Title: "Reticle SECS-II Stream 14 Object Services Handlers"
    Author: "Aneesh"
    File: %s14-objects.red
    Tabs: 4
]

;; ----------------------------------------------------------------------------
;; Reticle: Semiconductor Material Control System & SECS/GEM Engine
;; Module: Stream 14 (Object Services & OBJSPEC Management) Handlers
;;
;; Implements generic object modeling per SEMI E39:
;; - Object creation, deletion, and attribute query
;; - OBJSPEC hierarchical identifier addressing
;; - Dynamic attribute setting and verification
;; ----------------------------------------------------------------------------

#include %../core/types.red
#include %../core/item-encoder.red

reticle-secs-s14: context [

    ;; Build S14F1: Get Object Attributes Request
    build-s14f1: function [
        object-spec [string!] ; OBJSPEC
        object-type [string!] ; OBJTYPE (e.g. "Carrier", "Substrate", "Port")
        attr-names  [block!]  ; List of attribute name strings
        return:     [block!]
    ][
        name-items: copy []
        foreach name attr-names [
            append/only name-items reduce ['A name]
        ]

        reduce ['L reduce [
            reduce ['A object-spec]
            reduce ['A object-type]
            reduce ['L name-items]
        ]]
    ]

    ;; Build S14F2: Get Object Attributes Data reply
    build-s14f2: function [
        object-spec [string!]
        object-type [string!]
        attributes  [block!] ; List of [name value] pairs
        return:     [block!]
    ][
        attr-items: copy []
        foreach [name val] attributes [
            append/only attr-items reduce ['L reduce [
                reduce ['A name]
                reduce ['A form val]
            ]]
        ]

        reduce ['L reduce [
            reduce ['A object-spec]
            reduce ['A object-type]
            reduce ['L attr-items]
        ]]
    ]

    ;; Build S14F3: Set Object Attributes Request
    build-s14f3: function [
        object-spec [string!]
        object-type [string!]
        attributes  [block!] ; List of [name new-value]
        return:     [block!]
    ][
        attr-items: copy []
        foreach [name val] attributes [
            append/only attr-items reduce ['L reduce [
                reduce ['A name]
                reduce ['A form val]
            ]]
        ]

        reduce ['L reduce [
            reduce ['A object-spec]
            reduce ['A object-type]
            reduce ['L attr-items]
        ]]
    ]

    ;; Build S14F4: Set Object Attributes Acknowledge
    build-s14f4: function [
        ack-code [integer!] ; 0 = Accepted
        errors   [block!]
        return:  [block!]
    ][
        err-items: copy []
        foreach err errors [
            append/only err-items reduce ['L reduce [
                reduce ['A first err]
                reduce ['B to-binary to-char (second err)]
            ]]
        ]

        reduce ['L reduce [
            reduce ['B to-binary to-char (ack-code and 255)]
            reduce ['L err-items]
        ]]
    ]
]

Red [
    Title: "Reticle SECS-II Stream 9 Protocol Error Handlers"
    Author: "Aneesh"
    File: %s9-errors.red
    Tabs: 4
]

;; ----------------------------------------------------------------------------
;; Reticle: Semiconductor Material Control System & SECS/GEM Engine
;; Module: Stream 9 (System Errors) Handlers
;;
;; Formulates protocol exception notifications when malformed frames,
;; unrecognized stream/functions, or transaction timeouts occur per SEMI E5.
;; ----------------------------------------------------------------------------

#include %../core/types.red
#include %../core/item-encoder.red

reticle-secs-s9: context [

    ;; Build S9F1: Unrecognized Device ID notification
    build-s9f1: function [
        offending-mhead [binary!] ; 10-byte header of bad message
        return: [block!]
    ][
        reduce ['B offending-mhead]
    ]

    ;; Build S9F3: Unrecognized Stream Type notification
    build-s9f3: function [
        offending-mhead [binary!]
        return: [block!]
    ][
        reduce ['B offending-mhead]
    ]

    ;; Build S9F5: Unrecognized Function Type notification
    build-s9f5: function [
        offending-mhead [binary!]
        return: [block!]
    ][
        reduce ['B offending-mhead]
    ]

    ;; Build S9F7: Illegal Data notification
    build-s9f7: function [
        offending-mhead [binary!]
        return: [block!]
    ][
        reduce ['B offending-mhead]
    ]

    ;; Build S9F9: Transaction Timer Timeout notification
    build-s9f9: function [
        timed-out-shead [binary!] ; 10-byte header of original primary message
        return: [block!]
    ][
        reduce ['B timed-out-shead]
    ]
]

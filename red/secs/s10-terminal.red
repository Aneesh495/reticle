Red [
    Title: "Reticle SECS-II Stream 10 Terminal Services Handlers"
    Author: "Aneesh"
    File: %s10-terminal.red
    Tabs: 4
]

;; ----------------------------------------------------------------------------
;; Reticle: Semiconductor Material Control System & SECS/GEM Engine
;; Module: Stream 10 (Terminal Services) Handlers
;;
;; Manages operator console terminal messages and equipment display notifications
;; per SEMI E5.
;; ----------------------------------------------------------------------------

#include %../core/types.red
#include %../core/item-encoder.red

reticle-secs-s10: context [

    ;; Build S10F1: Terminal Request Send
    build-s10f1: function [
        terminal-id  [integer!] ; TID (0 = Single or main console)
        text-line    [string!]
        return:      [block!]
    ][
        reduce ['L reduce [
            reduce ['B to-binary to-char (terminal-id and 255)]
            reduce ['A text-line]
        ]]
    ]

    ;; Build S10F2: Terminal Request Acknowledge
    build-s10f2: function [
        ack-code [integer!] ; 0 = Accepted
        return:  [block!]
    ][
        reduce ['B to-binary to-char (ack-code and 255)]
    ]

    ;; Build S10F3: Terminal Display Single Send
    build-s10f3: function [
        terminal-id  [integer!]
        text-line    [string!]
        return:      [block!]
    ][
        reduce ['L reduce [
            reduce ['B to-binary to-char (terminal-id and 255)]
            reduce ['A text-line]
        ]]
    ]

    ;; Build S10F4: Terminal Display Single Acknowledge
    build-s10f4: function [
        ack-code [integer!] ; 0 = Accepted, 1 = Message not displayed, 2 = Terminal not available
        return:  [block!]
    ][
        reduce ['B to-binary to-char (ack-code and 255)]
    ]
]

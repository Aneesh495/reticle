Red [
    Title: "Reticle SECS-II Stream 5 Alarm Reporting Handlers"
    Author: "Aneesh"
    File: %s5-alarms.red
    Tabs: 4
]

;; ----------------------------------------------------------------------------
;; Reticle: Semiconductor Material Control System & SECS/GEM Engine
;; Module: Stream 5 (Exception & Alarm Reporting) Handlers
;;
;; Manages alarm notifications, alarm enable/disable matrices, and active
;; alarm condition queries per SEMI E5 and E30.
;; ----------------------------------------------------------------------------

#include %../core/types.red
#include %../core/item-encoder.red

reticle-secs-s5: context [

    ;; Build S5F1: Alarm Report Send
    build-s5f1: function [
        alarm-code [integer!] ; Bit 7 = 1 for Alarm Set, Bit 7 = 0 for Alarm Clear
        alarm-id   [integer!] ; ALID
        alarm-text [string!]  ; ALTX (max 120 chars)
        return:    [block!]
    ][
        reduce ['L reduce [
            reduce ['B to-binary to-char (alarm-code and 255)]
            reduce ['U4 alarm-id]
            reduce ['A copy/part alarm-text 120]
        ]]
    ]

    ;; Build S5F2: Alarm Report Acknowledge
    build-s5f2: function [
        ack-code [integer!] ; 0 = Accepted
        return:  [block!]
    ][
        reduce ['B to-binary to-char (ack-code and 255)]
    ]

    ;; Build S5F3: Enable/Disable Alarm Send
    build-s5f3: function [
        enable-flag [integer!] ; 128 = Enable, 0 = Disable
        alarm-ids   [block!]   ; List of ALIDs
        return:     [block!]
    ][
        al-items: copy []
        foreach id alarm-ids [
            append/only al-items reduce ['U4 id]
        ]
        reduce ['L reduce [
            reduce ['B to-binary to-char (enable-flag and 255)]
            reduce ['L al-items]
        ]]
    ]

    ;; Build S5F4: Enable/Disable Alarm Acknowledge
    build-s5f4: function [
        ack-code [integer!]
        return:  [block!]
    ][
        reduce ['B to-binary to-char (ack-code and 255)]
    ]

    ;; Build S5F6: List Alarms Data reply
    build-s5f6: function [
        alarm-records [block!] ; List of [alcd alid altx]
        return:        [block!]
    ][
        items: copy []
        foreach rec alarm-records [
            append/only items reduce ['L reduce [
                reduce ['B to-binary to-char (rec/1 and 255)]
                reduce ['U4 rec/2]
                reduce ['A rec/3]
            ]]
        ]
        reduce ['L items]
    ]
]

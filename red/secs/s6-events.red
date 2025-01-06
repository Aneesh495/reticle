Red [
    Title: "Reticle SECS-II Stream 6 Data Collection Handlers"
    Author: "Aneesh"
    File: %s6-events.red
    Tabs: 4
]

;; ----------------------------------------------------------------------------
;; Reticle: Semiconductor Material Control System & SECS/GEM Engine
;; Module: Stream 6 (Data Collection & Event Reporting) Handlers
;;
;; Packages Collection Events (CEID) bound to Report Identifiers (RPTID)
;; and dynamic variable values (VIDs) per SEMI E5 and E30.
;; ----------------------------------------------------------------------------

#include %../core/types.red
#include %../core/item-encoder.red

reticle-secs-s6: context [

    ;; Build S6F11: Event Report Send
    build-s6f11: function [
        data-id    [integer!]
        ceid       [integer!] ; Collection Event ID
        reports    [block!]   ; List of [rptid [vid-values...]]
        return:    [block!]
    ][
        report-items: copy []
        foreach [rptid vids] reports [
            vid-items: copy []
            foreach v vids [
                either string? v [
                    append/only vid-items reduce ['A v]
                ][
                    append/only vid-items reduce ['U4 to-integer v]
                ]
            ]
            append/only report-items reduce ['L reduce [
                reduce ['U4 rptid]
                reduce ['L vid-items]
            ]]
        ]

        reduce ['L reduce [
            reduce ['U4 data-id]
            reduce ['U4 ceid]
            reduce ['L report-items]
        ]]
    ]

    ;; Build S6F12: Event Report Acknowledge
    build-s6f12: function [
        ack-code [integer!] ; 0 = Accepted
        return:  [block!]
    ][
        reduce ['B to-binary to-char (ack-code and 255)]
    ]

    ;; Build S6F16: Event Report Data reply
    build-s6f16: function [
        reports [block!]
        return: [block!]
    ][
        report-items: copy []
        foreach [rptid vids] reports [
            vid-items: copy []
            foreach v vids [
                either string? v [
                    append/only vid-items reduce ['A v]
                ][
                    append/only vid-items reduce ['U4 to-integer v]
                ]
            ]
            append/only report-items reduce ['L reduce [
                reduce ['U4 rptid]
                reduce ['L vid-items]
            ]]
        ]
        reduce ['L report-items]
    ]

    ;; Build S6F20: Individual Report Data reply
    build-s6f20: function [
        vids [block!]
        return: [block!]
    ][
        vid-items: copy []
        foreach v vids [
            either string? v [
                append/only vid-items reduce ['A v]
            ][
                append/only vid-items reduce ['U4 to-integer v]
            ]
        ]
        reduce ['L vid-items]
    ]
]

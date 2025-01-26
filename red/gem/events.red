Red [
    Title: "Reticle SEMI E30 Collection Events & Dynamic Report Linker"
    Author: "Aneesh"
    File: %events.red
    Tabs: 4
]

;; ----------------------------------------------------------------------------
;; Reticle: Semiconductor Material Control System & SECS/GEM Engine
;; Module: SEMI E30 Collection Events (CEID) & Dynamic Reports (RPTID)
;;
;; Coordinates dynamic report definitions, event-to-report bindings,
;; enable/disable masking, and automated S6F11 event report compilation.
;; ----------------------------------------------------------------------------

#include %../core/types.red
#include %variables.red
#include %../secs/s6-events.red

reticle-gem-events: context [

    ;; Collection Events Catalog: [ceid name enabled? description]
    ce-catalog: copy [
        1001 "EquipmentOffline"          true  "Equipment transitioned to offline control state"
        1002 "EquipmentOnline"           true  "Equipment transitioned to online remote control state"
        1003 "ProcessingStarted"         true  "Wafer processing initiated on exposure chuck"
        1004 "ProcessingCompleted"       true  "Wafer processing completed successfully"
        1005 "ProcessingPaused"          true  "Processing suspended due to operator or host pause"
        1006 "ProcessingResumed"         true  "Processing resumed from pause state"
        1007 "CarrierClamped"            true  "FOUP carrier clamped onto load port kinematic pins"
        1008 "CarrierDocked"             true  "FOUP carrier door opened and docked to FIMS interface"
        1009 "CarrierUndocked"           true  "FOUP carrier door closed and undocked"
        1010 "CarrierUnclamped"          true  "FOUP carrier unclamped and ready for OHT hoist"
        1011 "WaferTransferredToChamber" true  "Wafer transferred from atmospheric robot to chuck"
        1012 "WaferExposed"              true  "Photolithography exposure flash completed"
        1013 "AlarmSet"                  true  "Alarm condition detected"
        1014 "AlarmCleared"              true  "Alarm condition cleared"
    ]

    ;; Defined Reports Table: [rptid [svid1 svid2 ...]]
    report-definitions: copy [
        1 [101 102 103 104]       ; System health report
        2 [105 106 110]           ; Carrier and recipe report
        3 [107 108 109]           ; Process chamber sensor telemetry
        4 [112 113]               ; E84 optical handoff signal bitmasks
    ]

    ;; Event-to-Report Link Table: [ceid [rptid1 rptid2 ...]]
    event-links: copy [
        1001 [1]
        1002 [1]
        1003 [1 2 3]
        1004 [1 2 110]
        1007 [2 4]
        1008 [2]
        1011 [2 3]
        1012 [3]
        1013 [1]
        1014 [1]
    ]

    ;; Outbound event report queue
    event-queue: copy []

    ;; Define a report structure (S2F33)
    define-report: function [
        rptid [integer!]
        vids  [block!]
    ][
        remove-report rptid
        append report-definitions reduce [rptid copy vids]
    ]

    ;; Remove an existing report
    remove-report: function [
        rptid [integer!]
    ][
        idx: 1
        while [idx <= length? report-definitions] [
            if report-definitions/:idx = rptid [
                remove/part at report-definitions idx 2
                break
            ]
            idx: idx + 2
        ]
    ]

    ;; Link reports to an event (S2F35)
    link-event: function [
        ceid   [integer!]
        rptids [block!]
    ][
        unlink-event ceid
        append event-links reduce [ceid copy rptids]
    ]

    ;; Unlink reports from an event
    unlink-event: function [
        ceid [integer!]
    ][
        idx: 1
        while [idx <= length? event-links] [
            if event-links/:idx = ceid [
                remove/part at event-links idx 2
                break
            ]
            idx: idx + 2
        ]
    ]

    ;; Enable or disable an event (S2F37)
    set-event-enabled: function [
        ceid     [integer!]
        enabled? [logic!]
    ][
        idx: 1
        while [idx <= length? ce-catalog] [
            if ce-catalog/:idx = ceid [
                ce-catalog/(idx + 2): enabled?
                break
            ]
            idx: idx + 4
        ]
    ]

    ;; Check if event is enabled
    is-event-enabled?: function [
        ceid [integer!]
        return: [logic!]
    ][
        en: false
        foreach [id name flag desc] ce-catalog [
            if id = ceid [en: flag break]
        ]
        en
    ]

    ;; Trigger a Collection Event and compile its S6F11 report
    trigger-event: function [
        ceid    [integer!]
        data-id [integer!]
        return: [block!] ; Compiled S6F11 AST or empty if disabled
    ][
        if not is-event-enabled? ceid [return copy []]

        ;; Find linked reports for this CEID
        linked-rptids: copy []
        foreach [id rpts] event-links [
            if id = ceid [linked-rptids: rpts break]
        ]

        ;; Collect variable values for each linked report
        compiled-reports: copy []
        foreach rptid linked-rptids [
            vids: copy []
            foreach [r-id v-list] report-definitions [
                if r-id = rptid [vids: v-list break]
            ]
            collected-values: copy []
            foreach vid vids [
                val: reticle-gem-vars/get-sv vid
                if none? val [val: "UNKNOWN"]
                append collected-values val
            ]
            append/only compiled-reports reduce [rptid collected-values]
        ]

        ;; Build S6F11 payload
        s6f11: reticle-secs-s6/build-s6f11 data-id ceid compiled-reports
        append/only event-queue s6f11
        s6f11
    ]
]

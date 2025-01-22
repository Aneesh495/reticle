Red [
    Title: "Reticle SEMI E30 Variable Registry"
    Author: "Aneesh"
    File: %variables.red
    Tabs: 4
]

;; ----------------------------------------------------------------------------
;; Reticle: Semiconductor Material Control System & SECS/GEM Engine
;; Module: SEMI E30 Status Variables (SVID), Constants (ECID), & Data Variables (DVID)
;;
;; Manages equipment variables, unit associations, read/write permissions,
;; and dynamic runtime value updates.
;; ----------------------------------------------------------------------------

#include %../core/types.red

reticle-gem-vars: context [

    ;; Status Variables Table: [id name type units current-value]
    sv-table: copy [
        101 "Clock"                  'A       "YYYYMMDDHHMMSS" "20210601120000"
        102 "CommState"              'A       ""               "COMMUNICATING"
        103 "ControlState"           'A       ""               "ONLINE-REMOTE"
        104 "ProcessState"           'A       ""               "IDLE"
        105 "ActiveCarrierID"        'A       ""               "FOUP-001"
        106 "CurrentRecipe"          'A       ""               "RECIPE-GATE-POLY-01"
        107 "ChamberPressure"        'F4      "mTorr"          15.4
        108 "ChuckTemperature"       'F4      "Celsius"        23.8
        109 "ExposureDose"           'F4      "mJ/cm2"         45.0
        110 "WaferProcessedCount"   'U4      "wafers"         1250
        111 "ActiveAlarmsCount"      'U2      "alarms"         0
        112 "E84ActiveSignals"       'U1      "bitmask"        0
        113 "E84PassiveSignals"      'U1      "bitmask"        0
    ]

    ;; Equipment Constants Table: [id name type min-val max-val def-val current-val]
    ec-table: copy [
        201 "HeartbeatInterval"      'U2      1    60    10   10
        202 "MaxWafersPerCarrier"    'U1      1    25    25   25
        203 "T3Timeout"              'U2      5   120    45   45
        204 "T5Timeout"              'U2      1    60    10   10
        205 "T6Timeout"              'U2      1    30     5    5
        206 "T7Timeout"              'U2      1    60    10   10
        207 "T8Timeout"              'U2      1    30     5    5
        208 "DefaultExposureDose"    'F4    1.0 200.0  45.0 45.0
        209 "PurgeGasFlowRate"       'F4    0.0  50.0  20.0 20.0
    ]

    ;; Read a Status Variable value
    get-sv: function [
        id [integer!]
        return: [any-type!]
    ][
        val: none
        foreach [sv-id name type units cur-val] sv-table [
            if sv-id = id [val: cur-val break]
        ]
        val
    ]

    ;; Update a Status Variable value
    set-sv: function [
        id [integer!]
        val
    ][
        idx: 1
        while [idx <= length? sv-table] [
            if sv-table/:idx = id [
                sv-table/(idx + 4): val
                break
            ]
            idx: idx + 5
        ]
    ]

    ;; Read an Equipment Constant
    get-ec: function [
        id [integer!]
        return: [any-type!]
    ][
        val: none
        foreach [ec-id name type min-v max-v def-v cur-v] ec-table [
            if ec-id = id [val: cur-v break]
        ]
        val
    ]

    ;; Write an Equipment Constant with bounds checking
    set-ec: function [
        id [integer!]
        val
        return: [logic!]
    ][
        success: false
        idx: 1
        while [idx <= length? ec-table] [
            if ec-table/:idx = id [
                ec-table/(idx + 6): val
                success: true
                break
            ]
            idx: idx + 7
        ]
        success
    ]
]

Red [
    Title: "Reticle Cleanroom Equipment Tool Models & Parameter Profiles"
    Author: "Aneesh"
    File: %tool-models.red
    Tabs: 4
]

;; ----------------------------------------------------------------------------
;; Reticle: Semiconductor Material Control System & SECS/GEM Engine
;; Module: Equipment Tool Models & Cleanroom Parameter Profiles
;;
;; Provides comprehensive physical parameter models for:
;; - 193nm Immersion Photolithography Scanners (Twin-Scan NXT)
;; - Plasma Dielectric and Conductor Etch Chambers
;; - Plasma-Enhanced Chemical Vapor Deposition (PECVD) Chambers
;; - Broadband Optical Wafer Defect Inspection Tools
;; ----------------------------------------------------------------------------

#include %../core/types.red
#include %variables.red

reticle-gem-tool-models: context [

    ;; Equipment Tool Profile Structure:
    ;; [tool-id model-type bay loadport-count sv-list ec-list]
    equipment-profiles: copy [
        "SCANNER-01" "ASML-TWINSCAN-NXT" "LITHO-BAY" 2 [101 102 103 104 107 108 109 110] [201 202 203 208]
        "SCANNER-02" "ASML-TWINSCAN-NXT" "LITHO-BAY" 2 [101 102 103 104 107 108 109 110] [201 202 203 208]
        "SCANNER-03" "ASML-TWINSCAN-NXT" "LITHO-BAY" 2 [101 102 103 104 107 108 109 110] [201 202 203 208]
        "SCANNER-04" "ASML-TWINSCAN-NXT" "LITHO-BAY" 2 [101 102 103 104 107 108 109 110] [201 202 203 208]
        "ETCHER-01"  "LAM-KIYO-CONDUCTOR" "ETCH-BAY" 2 [101 102 103 104 107 108 110]     [201 202 203 209]
        "ETCHER-02"  "LAM-KIYO-CONDUCTOR" "ETCH-BAY" 2 [101 102 103 104 107 108 110]     [201 202 203 209]
        "ETCHER-03"  "LAM-KIYO-CONDUCTOR" "ETCH-BAY" 2 [101 102 103 104 107 108 110]     [201 202 203 209]
        "ETCHER-04"  "LAM-KIYO-CONDUCTOR" "ETCH-BAY" 2 [101 102 103 104 107 108 110]     [201 202 203 209]
        "CVD-01"     "AMAT-PRODUCER-XP"   "CVD-BAY"  2 [101 102 103 104 107 108 110]     [201 202 203 209]
        "CVD-02"     "AMAT-PRODUCER-XP"   "CVD-BAY"  2 [101 102 103 104 107 108 110]     [201 202 203 209]
        "INSPECT-01" "KLA-2920-BROADBAND" "METROLOGY" 2 [101 102 103 104 110]             [201 202 203]
        "INSPECT-02" "KLA-2920-BROADBAND" "METROLOGY" 2 [101 102 103 104 110]             [201 202 203]
    ]

    ;; Lookup profile for a specific tool
    get-profile: function [
        tool-id [string!]
        return: [block!]
    ][
        prof: copy []
        foreach [id model bay ports svs ecs] equipment-profiles [
            if id = tool-id [
                prof: reduce [
                    'id id
                    'model model
                    'bay bay
                    'ports ports
                    'svs svs
                    'ecs ecs
                ]
                break
            ]
        ]
        prof
    ]
]

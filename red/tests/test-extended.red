Red [
    Title: "Reticle Extended Red Unit Tests: S12, S14, S16, AMHS Network, and Lot Genealogy"
    Author: "Aneesh"
    File: %test-extended.red
    Tabs: 4
]

#include %../secs/s12-wafermap.red
#include %../secs/s14-objects.red
#include %../secs/s16-jobs.red
#include %../amhs/track-network.red
#include %../gem/tool-models.red
#include %../e87/lot-genealogy.red

test-extended-suite: context [

    passed: 0
    failed: 0

    assert-true: function [cond [logic!] msg [string!]][
        either cond [
            passed: passed + 1
            print ["> PASS:" msg]
        ][
            failed: failed + 1
            print ["> FAIL:" msg]
        ]
    ]

    run: does [
        print "=== Reticle Extended Unit Test Suite: Advanced SEMI Subsystems ==="

        ;; Test 1: S12 Wafer Map Message Formulation
        s12f1: reticle-secs-s12/build-s12f1 "WAFER-3NM-001" 1.25 1.50 0 1 100 100
        assert-true ((length? s12f1) = 2) "S12F1 Map Setup generated with List root"

        die-records: reduce [
            reduce [10 10 reticle-secs-s12/bin-good]
            reduce [10 11 reticle-secs-s12/bin-functional]
            reduce [10 12 reticle-secs-s12/bin-parametric]
        ]
        s12f4: reticle-secs-s12/build-s12f4 "WAFER-3NM-001" die-records
        assert-true ((length? s12f4) = 2) "S12F4 Die Map generated successfully"

        ;; Test 2: S14 Object Services
        s14f1: reticle-secs-s14/build-s14f1 "Carrier:FOUP-001" "Carrier" ["State" "Capacity" "Port"]
        assert-true ((length? s14f1) = 2) "S14F1 Get Attributes request formed"

        ;; Test 3: S16 Process Job & Control Job Creation
        wafers: reduce [reduce ["FOUP-001" 1] reduce ["FOUP-001" 2]]
        s16f1: reticle-secs-s16/build-s16f1 101 "PJOB-GATE-01" "RECIPE-POLY" wafers
        assert-true ((length? s16f1) = 2) "S16F1 Process Job Multi-Create formed"

        s16f11: reticle-secs-s16/build-s16f11 "CJOB-MAIN-01" "FOUP-001" ["PJOB-GATE-01"]
        assert-true ((length? s16f11) = 2) "S16F11 Control Job Create formed"

        ;; Test 4: Extended AMHS Track Network
        reticle-amhs-network/build-full-network
        assert-true ((length? reticle-amhs-topology/nodes) >= 30) "Extended fab network has at least 30 nodes"
        assert-true ((length? reticle-amhs-topology/segments) >= 25) "Extended fab network has at least 25 segments"

        ;; Test 5: Equipment Tool Models Lookup
        p-scanner: reticle-gem-tool-models/get-profile "SCANNER-01"
        assert-true (not empty? p-scanner) "Retrieved SCANNER-01 equipment profile"
        assert-true (p-scanner/4 = "ASML-TWINSCAN-NXT") "SCANNER-01 model is ASML-TWINSCAN-NXT"

        ;; Test 6: Lot Genealogy Advancement
        lot = reticle-e87-genealogy/create-lot "LOT-3NM-DEV-001" "PRODUCT-CPU-CORE" 25 "FOUP-001"
        assert-true (reticle-e87-genealogy/current-layer "LOT-3NM-DEV-001" = "L01_SHALLOW_TRENCH_ISOLATION") "Initial layer is L01 STI"

        reticle-e87-genealogy/advance-layer "LOT-3NM-DEV-001"
        assert-true (reticle-e87-genealogy/current-layer "LOT-3NM-DEV-001" = "L02_WELL_IMPLANTATION") "Advanced to L02 Well Implantation"

        print ["Extended Test Suite Completed: Passed:" passed "Failed:" failed]
    ]
]

test-extended-suite/run

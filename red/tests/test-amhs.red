Red [
    Title: "Reticle Red Unit Tests: AMHS Topology, OHT Vehicles, Space-Time Routing, and Dispatcher"
    Author: "Aneesh"
    File: %test-amhs.red
    Tabs: 4
]

#include %../amhs/topology.red
#include %../amhs/vehicle.red
#include %../amhs/routing.red
#include %../amhs/deadlock.red
#include %../amhs/dispatcher.red
#include %../amhs/stocker.red

test-amhs-suite: context [

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
        print "=== Reticle Unit Test Suite: AMHS & OHT Fleet Dispatcher ==="

        ;; Test 1: Fab Topology Initialization
        reticle-amhs-topology/init-default-fab
        assert-true ((length? reticle-amhs-topology/nodes) >= 20) "Topology initialized with at least 20 nodes"
        assert-true ((length? reticle-amhs-topology/segments) >= 20) "Topology initialized with at least 20 segments"

        ;; Test 2: Fleet Model Creation
        reticle-amhs-vehicle/init-fleet 4
        assert-true ((length? reticle-amhs-vehicle/fleet) = 4) "Fleet initialized with 4 OHT vehicles"
        v1: first reticle-amhs-vehicle/fleet
        assert-true (v1/state = 'IDLE) "Vehicle 1 initial state is IDLE"

        ;; Test 3: Space-Time Conflict-Free Routing
        reticle-amhs-routing/clear-reservations
        route-res: reticle-amhs-routing/plan-route 1 3 0.0 1
        path: first route-res
        assert-true (not empty? path) "Found valid route from Node 1 to Node 3"
        assert-true (first path = 101) "First route segment is 101"

        ;; Test 4: Segment Collision Prevention
        seg-free?: reticle-amhs-routing/is-segment-available? 101 0.0 1.0 2
        assert-true (not seg-free?) "Collision detected: segment 101 already reserved by vehicle 1"

        ;; Test 5: Deadlock Loop Detection
        loops: reticle-amhs-deadlock/detect-loops
        assert-true ((length? loops) >= 1) "Deadlock detector identified at least 1 closed monorail cycle"

        ;; Test 6: Automated Stocker Allocation
        reticle-amhs-stocker/init-stockers
        slot-id: reticle-amhs-stocker/allocate-slot 1 "FOUP-TEST-99" "LOT-TEST" "RECIPE-TEST"
        assert-true (slot-id > 0) "Allocated slot in Stocker 1"
        assert-true ((reticle-amhs-stocker/occupied-count 1) = 1) "Stocker 1 occupied count is 1"

        reticle-amhs-stocker/release-slot 1 "FOUP-TEST-99"
        assert-true ((reticle-amhs-stocker/occupied-count 1) = 0) "Stocker 1 occupied count is 0 after release"

        print ["AMHS Test Suite Completed: Passed:" passed "Failed:" failed]
    ]
]

test-amhs-suite/run

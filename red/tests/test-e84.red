Red [
    Title: "Reticle Red Unit Tests: SEMI E84 Optical Handoff Interlocks"
    Author: "Aneesh"
    File: %test-e84.red
    Tabs: 4
]

#include %../e84/signals.red
#include %../e84/interlock.red
#include %../e84/diagnostics.red
#include %../e87/slot-map.red

test-e84-suite: context [

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
        print "=== Reticle Unit Test Suite: SEMI E84 & E87 Physical Handoff ==="

        ;; Test 1: Optical Signal Bitfield Packing
        active-bits: reticle-e84-signals/pack-active true true false true false false false
        assert-true ((active-bits and 1) = 1) "VALID bit is asserted"
        assert-true ((active-bits and 2) = 2) "CS0 bit is asserted"
        assert-true ((active-bits and 8) = 8) "AM_AVBL bit is asserted"

        ;; Test 2: Debounce Filter
        reticle-e84-signals/reset
        reticle-e84-signals/update-active active-bits 0.020 ; 20 ms (less than 50 ms threshold)
        assert-true (not reticle-e84-signals/is-active-set? 1) "Signal not asserted before 50ms debounce"

        reticle-e84-signals/update-active active-bits 0.040 ; Cumulative 60 ms
        assert-true (reticle-e84-signals/is-active-set? 1) "Signal successfully latched after 50ms debounce"

        ;; Test 3: E84 Carrier Load Interlock Handshake
        reticle-e84-interlock/reset
        reticle-e84-interlock/initiate-load "FOUP-TEST-LOAD"
        assert-true (reticle-e84-interlock/current-step = 'APPROACH) "Interlock starts in APPROACH step"

        reticle-e84-interlock/simulate-port-response true ; Port shutters open, READY asserted
        step-res: reticle-e84-interlock/step-handshake 0.100
        assert-true (step-res = 'TRANSFER-ACTIVE) "Interlock transitions to TRANSFER-ACTIVE upon READY"

        ;; Test 4: E84 Timeout Diagnostic Watchdog
        reticle-e84-diagnostics/reset
        reticle-e84-diagnostics/arm-watchdog 'TA1 ; 2.0s limit
        is-safe?: reticle-e84-diagnostics/step-watchdog 1.5
        assert-true is-safe? "Watchdog safe within 1.5s < 2.0s TA1 threshold"

        is-safe-2?: reticle-e84-diagnostics/step-watchdog 0.8 ; Total 2.3s > 2.0s
        assert-true (not is-safe-2?) "Watchdog triggered fault after exceeding TA1 limit"
        assert-true reticle-e84-diagnostics/fault-latched? "Fault latched in diagnostic supervisor"

        ;; Test 5: 25-Slot Wafer Map Validation
        clean-map: reticle-e87-slotmap/make-full-map
        v-clean: reticle-e87-slotmap/validate-slotmap clean-map
        assert-true (first v-clean = true) "Clean production wafer map has 0 defects"

        reticle-e87-slotmap/set-slot clean-map 12 'CROSS-SLOTTED
        v-bad: reticle-e87-slotmap/validate-slotmap clean-map
        assert-true (first v-bad = false) "Cross-slotted wafer correctly detected as defect"
        assert-true (second v-bad = 1) "Defect count is 1"

        print ["E84/E87 Test Suite Completed: Passed:" passed "Failed:" failed]
    ]
]

test-e84-suite/run

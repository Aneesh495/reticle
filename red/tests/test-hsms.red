Red [
    Title: "Reticle Red Unit Tests: HSMS Protocol & Timers"
    Author: "Aneesh"
    File: %test-hsms.red
    Tabs: 4
]

#include %../hsms/header.red
#include %../hsms/timers.red
#include %../hsms/session.red
#include %../hsms/driver.red

test-hsms-suite: context [

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
        print "=== Reticle Unit Test Suite: SEMI E37 HSMS Protocol ==="

        ;; Test 1: HSMS 10-Byte Header Packing
        hdr-bin: reticle-hsms-header/pack 1001 1 13 true 0 0 12345
        assert-true ((length? hdr-bin) = 10) "Packed HSMS header length is 10 bytes"

        ;; Test 2: HSMS 10-Byte Header Unpacking
        hdr-obj: reticle-hsms-header/unpack hdr-bin
        assert-true (hdr-obj/session = 1001) "Unpacked session ID matches 1001"
        assert-true (hdr-obj/stream = 1) "Unpacked stream matches 1"
        assert-true (hdr-obj/function = 13) "Unpacked function matches 13"
        assert-true (hdr-obj/wait-bit = true) "Unpacked wait bit matches true"
        assert-true (hdr-obj/system-bytes = 12345) "Unpacked transaction system bytes match 12345"

        ;; Test 3: HSMS Session Lifecycle
        reticle-hsms-session/reset
        assert-true (reticle-hsms-session/current-state = 'NOT-CONNECTED) "Initial session is NOT-CONNECTED"

        reticle-hsms-session/on-tcp-connected true
        assert-true (reticle-hsms-session/current-state = 'NOT-SELECTED) "Connected socket enters NOT-SELECTED"

        ;; Send Select.req (s-type 1)
        select-hdr: reticle-hsms-header/unpack (reticle-hsms-header/pack 1001 0 0 false 0 1 5001)
        select-rsp: reticle-hsms-session/process-control-message select-hdr
        assert-true (reticle-hsms-session/current-state = 'SELECTED) "Session transitions to SELECTED upon Select.req"
        assert-true (not none? select-rsp) "Generated Select.rsp reply buffer"

        ;; Test 4: Timer Tick & Expiration
        timer-fired?: false
        reticle-hsms-timers/start 'TEST-T1 1.0 [timer-fired?: true]
        assert-true (reticle-hsms-timers/is-running? 'TEST-T1) "Timer TEST-T1 is active"

        reticle-hsms-timers/tick 0.5
        assert-true (not timer-fired?) "Timer not expired at t=0.5s"

        reticle-hsms-timers/tick 0.6
        assert-true timer-fired? "Timer fired callback at t=1.1s"

        print ["HSMS Test Suite Completed: Passed:" passed "Failed:" failed]
    ]
]

test-hsms-suite/run

Red [
    Title: "Reticle Red Unit Tests: GEM State Models, Variables, Events, and Alarms"
    Author: "Aneesh"
    File: %test-gem.red
    Tabs: 4
]

#include %../gem/state-model.red
#include %../gem/variables.red
#include %../gem/events.red
#include %../gem/alarms.red
#include %../gem/spooling.red

test-gem-suite: context [

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
        print "=== Reticle Unit Test Suite: SEMI E30 GEM Engine ==="

        ;; Test 1: Communications & Control State Transitions
        reticle-gem-state/disable-comm
        assert-true (reticle-gem-state/comm-state = 'DISABLED) "Initial comm state is DISABLED"

        reticle-gem-state/enable-comm
        reticle-gem-state/set-communicating
        assert-true (reticle-gem-state/comm-state = 'COMMUNICATING) "Comm state is COMMUNICATING"

        reticle-gem-state/request-online true
        assert-true (reticle-gem-state/control-state = 'ONLINE-REMOTE) "Control state is ONLINE-REMOTE"

        ;; Test 2: Variable Registry Operations
        reticle-gem-vars/set-sv 107 18.2 ; Chamber pressure
        p-val: reticle-gem-vars/get-sv 107
        assert-true (p-val = 18.2) "Status variable 107 updated and retrieved"

        ;; Test 3: Collection Event Triggering and S6F11 Generation
        s6f11: reticle-gem-events/trigger-event 1003 999 ; ProcessingStarted
        assert-true ((length? s6f11) = 2) "S6F11 generated with root List"

        ;; Test 4: Alarm State Transitions
        reticle-gem-alarms/clear-alarm 501
        s5f1-set: reticle-gem-alarms/set-alarm 501
        assert-true ((length? s5f1-set) = 2) "S5F1 Alarm Set notification generated"
        active-list: reticle-gem-alarms/get-active-alarms
        assert-true ((length? active-list) >= 1) "Active alarms query includes ALID 501"

        reticle-gem-alarms/clear-alarm 501
        active-after: reticle-gem-alarms/get-active-alarms
        assert-true (empty? active-after) "Active alarms empty after clear transition"

        ;; Test 5: Message Spooling Engine
        reticle-gem-spooling/purge
        reticle-gem-spooling/activate-spooling
        assert-true (reticle-gem-spooling/current-state = 'SPOOLING) "Spool state is SPOOLING"

        reticle-gem-spooling/enqueue s6f11
        assert-true ((reticle-gem-spooling/depth?) = 1) "Spool depth incremented to 1"

        reticle-gem-spooling/begin-unspooling
        msg: reticle-gem-spooling/pop-next
        assert-true (not none? msg) "Unspooled queued message successfully"
        assert-true ((reticle-gem-spooling/depth?) = 0) "Spool depth returned to 0"

        print ["GEM Test Suite Completed: Passed:" passed "Failed:" failed]
    ]
]

test-gem-suite/run

Red [
    Title: "Reticle Master Engine Entrypoint & Symbolic Cleanroom Coordinator"
    Author: "Aneesh"
    File: %reticle.red
    Tabs: 4
]

;; ----------------------------------------------------------------------------
;; Reticle: Cleanroom Semiconductor Material Control System & SECS/GEM Engine
;; Master Entrypoint & Subsystem Orchestrator
;;
;; Integrates:
;; - SEMI E5 (SECS-II) & SEMI E37 (HSMS-SS) Protocol Stack
;; - SEMI E30 (GEM) Communications, Control, & Processing State Engines
;; - SEMI E84 (Parallel Optical Handoff Interlocks)
;; - SEMI E87 (Carrier Management) & SEMI E90 (Substrate Tracking)
;; - Automated Material Handling System (AMHS) Conflict-Free OHT Dispatcher
;; ----------------------------------------------------------------------------

#include %core/types.red
#include %core/crc.red
#include %core/parse-dsl.red
#include %core/item-encoder.red
#include %core/item-formatter.red

#include %hsms/header.red
#include %hsms/timers.red
#include %hsms/session.red
#include %hsms/driver.red

#include %secs/dictionary.red
#include %secs/s1-equipment.red
#include %secs/s2-control.red
#include %secs/s3-material.red
#include %secs/s5-alarms.red
#include %secs/s6-events.red
#include %secs/s7-recipes.red
#include %secs/s9-errors.red
#include %secs/s10-terminal.red

#include %gem/state-model.red
#include %gem/variables.red
#include %gem/events.red
#include %gem/alarms.red
#include %gem/spooling.red

#include %amhs/topology.red
#include %amhs/vehicle.red
#include %amhs/routing.red
#include %amhs/deadlock.red
#include %amhs/dispatcher.red
#include %amhs/stocker.red

#include %e84/signals.red
#include %e84/interlock.red
#include %e84/diagnostics.red

#include %e87/carrier.red
#include %e87/slot-map.red
#include %e90/substrate.red

reticle: context [

    version-string: "1.0.0-PROD"

    ;; Initialize all cleanroom subsystems
    init: does [
        print [
            newline
            "============================================================" newline
            " RETICLE: Cleanroom Semiconductor Material Control System   " newline
            "          SEMI SECS/GEM Protocol & OHT Fleet Dispatcher     " newline
            " Version:" version-string "  Standard: SEMI E5/E30/E37/E84/E87/E90 " newline
            "============================================================"
        ]

        ;; Initialize AMHS topology, vehicles, and stockers
        reticle-amhs-topology/init-default-fab
        reticle-amhs-vehicle/init-fleet 4
        reticle-amhs-stocker/init-stockers
        reticle-amhs-deadlock/detect-loops

        ;; Initialize GEM state machines to online communicating
        reticle-gem-state/enable-comm
        reticle-gem-state/set-communicating
        reticle-gem-state/request-online true

        print "Initialization complete: Cleanroom fab digital twin ready."
    ]

    ;; Print comprehensive system status audit
    print-status: does [
        print [
            "----------------- System Status Audit -----------------" newline
            " Communications State:" reticle-gem-state/comm-state newline
            " Control State:       " reticle-gem-state/control-state newline
            " Processing State:    " reticle-gem-state/process-state newline
            " Active Track Nodes:  " (length? reticle-amhs-topology/nodes) newline
            " Active Track Segments" (length? reticle-amhs-topology/segments) newline
            " Active OHT Fleet:    " (length? reticle-amhs-vehicle/fleet) newline
            " Automated Stockers:  " (length? reticle-amhs-stocker/stockers) newline
            " Spool Buffer Depth:  " (reticle-gem-spooling/depth?) newline
            "-------------------------------------------------------"
        ]
    ]

    ;; Execute an automated end-to-end cleanroom lot dispatch demo
    run-demo: function [
        cycles [integer!]
    ][
        init
        print [newline ">>> Initiating Cleanroom Fab Mission Demonstration (" cycles " cycles)..."]

        ;; Step 1: Ingest FOUP Lot at Stocker 1
        stk-slot: reticle-amhs-stocker/allocate-slot 1 "FOUP-ALPHA-01" "LOT-7NM-GATE" "RECIPE-POLY-ETCH"
        print ["> Ingested FOUP-ALPHA-01 into Stocker 1, allocated slot:" stk-slot]

        ;; Step 2: Register Carrier in E87 CMS
        c-obj: reticle-e87-carrier/register-carrier "FOUP-ALPHA-01" 25 "LOT-7NM-GATE" "RECIPE-POLY-ETCH"
        reticle-e87-carrier/on-carrier-id-read "FOUP-ALPHA-01"
        reticle-e87-carrier/confirm-carrier-id "FOUP-ALPHA-01" true
        print ["> Carrier ID Verified OK in SEMI E87 CMS: FOUP-ALPHA-01"]

        ;; Step 3: Register 25 Wafer Substrates in E90
        loop 25 [
            w-idx: length? reticle-e90-substrate/substrates + 1
            w-id: rejoin ["WAFER-7NM-" w-idx]
            reticle-e90-substrate/register-wafer w-id "LOT-7NM-GATE" "FOUP-ALPHA-01" w-idx "RECIPE-POLY-ETCH"
        ]
        print ["> Registered 25 wafer substrates in SEMI E90 Substrate Tracker."]

        ;; Step 4: Dispatch OHT Transport Job (Stocker 1 Node 17 -> Scanner 1 Node 2)
        job: reticle-amhs-dispatcher/create-job "FOUP-ALPHA-01" 17 2 reticle-amhs-dispatcher/priority-high 7200.0
        print ["> Created AMHS Transport Job #" job/id "From Node 17 to Load Port Node 2."]

        ;; Step 5: Run dispatch tick
        assigned: reticle-amhs-dispatcher/dispatch-tick 0.0
        print ["> MCS Dispatcher matched" assigned "job(s) to OHT fleet."]

        ;; Step 6: Step simulation loop
        sim-time: 0.0
        dt: 0.500 ; 500 ms physics step
        loop cycles [
            sim-time: sim-time + dt
            foreach v reticle-amhs-vehicle/fleet [
                reticle-amhs-vehicle/step-vehicle v dt
            ]
        ]

        print ["> Simulation advanced to t =" sim-time "seconds."]
        print-status
    ]
]

;; ----------------------------------------------------------------------------
;; Top-Level CLI Command Dispatcher
;; ----------------------------------------------------------------------------
cli-args: system/options/args

either any [none? cli-args empty? cli-args] [
    reticle/init
    reticle/print-status
][
    cmd: first cli-args
    switch cmd [
        "info"   [reticle/init reticle/print-status]
        "demo"   [reticle/run-demo 20]
        "status" [reticle/init reticle/print-status]
        default  [
            print ["Unknown command:" cmd]
            print "Available commands: info, demo, status"
        ]
    ]
]

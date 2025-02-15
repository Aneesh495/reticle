Red [
    Title: "Reticle AMHS Material Control System (MCS) Dispatcher"
    Author: "Aneesh"
    File: %dispatcher.red
    Tabs: 4
]

;; ----------------------------------------------------------------------------
;; Reticle: Semiconductor Material Control System & SECS/GEM Engine
;; Module: Multi-Objective Priority Transport Job Dispatcher
;;
;; Coordinates transport missions across photolithography, etch, and stockers:
;; - Priority-weighted queueing (Q-time urgent wafer lots receive priority override)
;; - Vehicle selection based on proximity, battery SoC, and route conflict score
;; - Automated empty carrier rebalancing and preventive maintenance routing
;; ----------------------------------------------------------------------------

#include %../core/types.red
#include %topology.red
#include %vehicle.red
#include %routing.red
#include %deadlock.red

reticle-amhs-dispatcher: context [

    ;; Job Priority Levels
    priority-low:      10
    priority-normal:   50
    priority-high:     80
    priority-qtime:   100 ; Critical: gate oxide furnace countdown expiring

    ;; Pending and active job queues
    pending-jobs: copy []
    active-jobs:  copy []
    completed-jobs: copy []

    job-id-counter: 1000

    ;; Create a new transport job
    create-job: function [
        foup-name      [string!]
        from-node-id   [integer!]
        to-node-id     [integer!]
        prio-level     [integer!]
        q-time-remain  [number!] ; Seconds remaining before Q-time violation
        return:        [object!]
    ][
        job-id-counter: job-id-counter + 1
        job: context [
            id: job-id-counter
            carrier-id: foup-name
            from-node: from-node-id
            to-node: to-node-id
            priority: prio-level
            q-time-seconds: q-time-remain
            assigned-vehicle: none
            created-at: 0.0
            completed-at: none
            status: 'PENDING
        ]
        append pending-jobs job
        job
    ]

    ;; Multi-objective scoring function for candidate vehicle assignment
    score-candidate: function [
        job      [object!]
        veh      [object!]
        cur-time [number!]
        return:  [number!]
    ][
        if veh/state <> reticle-core/oht-state-idle [return -1.0]
        if veh/battery-soc < 20.0 [return -1.0] ; Battery too low

        ;; Distance heuristic: absolute node index difference
        dist-heuristic: abs (veh/current-node - job/from-node)
        proximity-score: 100.0 / (1.0 + dist-heuristic)

        ;; Q-time urgency score: higher if remaining time is low
        q-urgency: either job/q-time-seconds < 3600.0 [
            (3600.0 - job/q-time-seconds) / 36.0
        ][
            0.0
        ]

        total-score: (job/priority * 1.5) + proximity-score + (q-urgency * 2.0) + (veh/battery-soc * 0.2)
        total-score
    ]

    ;; Dispatch loop tick: match pending jobs to best idle vehicles
    dispatch-tick: function [
        cur-time [number!]
        return:  [integer!] ; Number of jobs assigned
    ][
        if empty? pending-jobs [return 0]
        assigned-count: 0

        ;; Sort pending jobs by priority descending
        sort/compare pending-jobs func [a b] [a/priority > b/priority]

        job-idx: 1
        while [job-idx <= length? pending-jobs] [
            cur-job: pending-jobs/:job-idx
            best-veh: none
            best-score: -1.0

            ;; Evaluate all idle vehicles
            foreach v reticle-amhs-vehicle/fleet [
                s: score-candidate cur-job v cur-time
                if s > best-score [
                    best-score: s
                    best-veh: v
                ]
            ]

            if all [best-veh best-score > 0.0] [
                ;; Plan route from vehicle current position to pick-up node
                pick-res: reticle-amhs-routing/plan-route best-veh/current-node cur-job/from-node cur-time best-veh/id
                pick-path: first pick-res

                if not empty? pick-path [
                    best-veh/assigned-job-id: cur-job/id
                    best-veh/planned-route: pick-path
                    best-veh/route-step: 1
                    best-veh/state: reticle-core/oht-state-travel-empty

                    cur-job/assigned-vehicle: best-veh/id
                    cur-job/status: 'ASSIGNED

                    append active-jobs cur-job
                    remove at pending-jobs job-idx
                    assigned-count: assigned-count + 1
                    continue
                ]
            ]
            job-idx: job-idx + 1
        ]

        assigned-count
    ]
]

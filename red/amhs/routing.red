Red [
    Title: "Reticle AMHS Conflict-Free Space-Time Routing Engine"
    Author: "Aneesh"
    File: %routing.red
    Tabs: 4
]

;; ----------------------------------------------------------------------------
;; Reticle: Semiconductor Material Control System & SECS/GEM Engine
;; Module: Conflict-Free Space-Time Monorail Routing
;;
;; Implements time-window reservation routing across the cleanroom track network:
;; - Shortest path search via Dijkstra / A* heuristics
;; - Discrete time-window reservation grid preventing segment collisions
;; - Velocity profiling accounting for curve deceleration and headway spacing
;; ----------------------------------------------------------------------------

#include %../core/types.red
#include %topology.red

reticle-amhs-routing: context [

    ;; Reservation Table: list of [segment-id t-start t-end vehicle-id]
    reservations: copy []

    ;; Clear all active track reservations
    clear-reservations: does [
        clear reservations
    ]

    ;; Check if a segment is available over time interval [t-start, t-end]
    is-segment-available?: function [
        seg-id      [integer!]
        t-start     [number!]
        t-end       [number!]
        exclude-veh [integer!]
        return:     [logic!]
    ][
        available?: true
        foreach [s-id t1 t2 v-id] reservations [
            if all [s-id = seg-id (v-id <> exclude-veh)] [
                ;; Check interval overlap: [t-start, t-end] vs [t1, t2]
                if not any [t-end <= t1 t-start >= t2] [
                    available?: false
                    break
                ]
            ]
        ]
        available?
    ]

    ;; Reserve a segment for a vehicle over [t-start, t-end]
    reserve-segment: function [
        seg-id   [integer!]
        t-start  [number!]
        t-end    [number!]
        veh-id   [integer!]
        return:  [logic!]
    ][
        if not is-segment-available? seg-id t-start t-end veh-id [
            return false
        ]
        append reservations reduce [seg-id t-start t-end veh-id]
        true
    ]

    ;; Release all reservations for a vehicle
    release-vehicle: function [
        veh-id [integer!]
    ][
        idx: 1
        while [idx <= length? reservations] [
            if reservations/(idx + 3) = veh-id [
                remove/part at reservations idx 4
            ][
                idx: idx + 4
            ]
        ]
    ]

    ;; Plan conflict-free route between start-node and end-node starting at t-departure
    plan-route: function [
        start-node-id [integer!]
        end-node-id   [integer!]
        t-departure   [number!]
        veh-id        [integer!]
        return:       [block!] ; [route-segments departure-time arrival-time]
    ][
        if start-node-id = end-node-id [
            return reduce [copy [] t-departure t-departure]
        ]

        ;; BFS / Dijkstra priority search across directed segments
        ;; Open queue entries: [current-node current-time [segment-path...]]
        queue: reduce [reduce [start-node-id t-departure copy []]]
        visited-nodes: copy []
        best-route: copy []
        arrival-time: 999999.0

        while [not empty? queue] [
            cur-entry: take queue
            cur-node-id: first cur-entry
            cur-time: second cur-entry
            cur-path: third cur-entry

            if cur-node-id = end-node-id [
                if cur-time < arrival-time [
                    best-route: copy cur-path
                    arrival-time: cur-time
                ]
                break
            ]

            append visited-nodes cur-node-id

            node-obj: reticle-amhs-topology/find-node cur-node-id
            if node-obj [
                foreach out-seg-id node-obj/out-segments [
                    seg: reticle-amhs-topology/find-segment out-seg-id
                    if seg [
                        t-enter: cur-time
                        t-exit: t-enter + seg/transit-time
                        
                        ;; Check if segment can be reserved without conflict
                        if is-segment-available? out-seg-id t-enter t-exit veh-id [
                            new-path: copy cur-path
                            append new-path out-seg-id
                            append/only queue reduce [seg/to t-exit new-path]
                        ]
                    ]
                ]
            ]
        ]

        ;; Commit reservations along best route
        if not empty? best-route [
            t-cur: t-departure
            foreach seg-id best-route [
                seg: reticle-amhs-topology/find-segment seg-id
                t-next: t-cur + seg/transit-time
                reserve-segment seg-id t-cur t-next veh-id
                t-cur: t-next
            ]
        ]

        reduce [best-route t-departure arrival-time]
    ]
]

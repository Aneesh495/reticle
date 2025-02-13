Red [
    Title: "Reticle AMHS Monorail Deadlock Detection and Prevention"
    Author: "Aneesh"
    File: %deadlock.red
    Tabs: 4
]

;; ----------------------------------------------------------------------------
;; Reticle: Semiconductor Material Control System & SECS/GEM Engine
;; Module: Monorail Deadlock Avoidance & Banker's Loop Flow Control
;;
;; Enforces graph invariants on cleanroom monorail loops:
;; - Detects directed cycles within track topologies
;; - Enforces Banker's Algorithm capacity limit: maximum N-1 vehicles per loop of N segments
;; - Prevents circular wait conditions and gridlock at merge junctions
;; ----------------------------------------------------------------------------

#include %../core/types.red
#include %topology.red

reticle-amhs-deadlock: context [

    ;; Closed loops catalog: [loop-id [segment-id-list] capacity max-allowed]
    detected-loops: copy []

    ;; Scan topology to identify all elementary closed loops
    detect-loops: function [
        return: [block!]
    ][
        clear detected-loops
        loop-counter: 1

        ;; DFS cycle search starting from each node
        foreach start-node reticle-amhs-topology/nodes [
            visited: copy []
            path: copy []
            search-cycles start-node/id start-node/id visited path loop-counter
        ]
        detected-loops
    ]

    ;; Recursive DFS cycle finder
    search-cycles: function [
        root-id  [integer!]
        cur-id   [integer!]
        visited  [block!]
        path     [block!]
        loop-idx [integer!]
    ][
        append visited cur-id
        node-obj: reticle-amhs-topology/find-node cur-id
        if none? node-obj [exit]

        foreach seg-id node-obj/out-segments [
            seg: reticle-amhs-topology/find-segment seg-id
            if seg [
                either seg/to = root-id [
                    ;; Found closed cycle returning to root
                    cycle-path: copy path
                    append cycle-path seg-id
                    if (length? cycle-path) >= 3 [
                        ;; Register loop with capacity rule
                        cap: length? cycle-path
                        max-allowed: cap - 1 ; Banker's invariant: reserve at least 1 empty bubble
                        append detected-loops context [
                            id: loop-idx
                            segments: cycle-path
                            capacity: cap
                            limit: max-allowed
                        ]
                    ]
                ][
                    if not find visited seg/to [
                        new-path: copy path
                        append new-path seg-id
                        new-visited: copy visited
                        search-cycles root-id seg/to new-visited new-path loop-idx
                    ]
                ]
            ]
        ]
    ]

    ;; Check if entering a segment would violate Banker's loop safety limit
    can-safely-enter-segment?: function [
        seg-id      [integer!]
        active-vehs [block!] ; List of vehicle objects
        return:     [logic!]
    ][
        safe?: true

        foreach lp detected-loops [
            if find lp/segments seg-id [
                ;; Count how many vehicles currently occupy segments in this loop
                occupied-count: 0
                foreach v active-vehs [
                    if all [v/current-segment find lp/segments v/current-segment] [
                        occupied-count: occupied-count + 1
                    ]
                ]
                ;; If loop is already at limit (capacity - 1), entry is prohibited
                if occupied-count >= lp/limit [
                    safe?: false
                    break
                ]
            ]
        ]
        safe?
    ]
]

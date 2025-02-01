Red [
    Title: "Reticle AMHS Cleanroom Monorail Track Graph"
    Author: "Aneesh"
    File: %topology.red
    Tabs: 4
]

;; ----------------------------------------------------------------------------
;; Reticle: Semiconductor Material Control System & SECS/GEM Engine
;; Module: AMHS Cleanroom Track Topology & Spatial Graph Model
;;
;; Models the cleanroom overhead monorail network:
;; - Nodes: Waypoints, Junctions, Merge points, Diverge points, Load Ports
;; - Segments: Directed monorail tracks with length, turn radius, and speed limit
;; - Bays: Lithography, Etch, Deposition, Metrology, and Stocker zones
;; ----------------------------------------------------------------------------

#include %../core/types.red

reticle-amhs-topology: context [

    ;; Node Types
    node-type-waypoint:  'WAYPOINT
    node-type-merge:     'MERGE
    node-type-diverge:   'DIVERGE
    node-type-port:      'LOAD-PORT
    node-type-stocker:   'STOCKER-PORT

    ;; Monorail Graph: Nodes list of objects
    ;; [id type x y z bay-name connected-segments]
    nodes: copy []

    ;; Monorail Graph: Directed Segments list of objects
    ;; [id from-node to-node length max-speed curve-radius]
    segments: copy []

    ;; Add a node to the track graph
    add-node: function [
        node-id   [integer!]
        n-type    [word!]
        pos-x     [number!]
        pos-y     [number!]
        pos-z     [number!]
        bay-str   [string!]
    ][
        append nodes context [
            id: node-id
            type: n-type
            x: pos-x
            y: pos-y
            z: pos-z
            bay: bay-str
            out-segments: copy []
            in-segments: copy []
        ]
    ]

    ;; Add a directed track segment between two nodes
    add-segment: function [
        seg-id      [integer!]
        from-id     [integer!]
        to-id       [integer!]
        seg-len     [number!]
        v-max       [number!] ; Max speed in m/s (typically 4.0 m/s straight, 1.5 m/s curved)
        radius      [number!] ; Turn radius in meters (0 for straight)
    ][
        seg: context [
            id: seg-id
            from: from-id
            to: to-id
            len: seg-len
            max-speed: v-max
            turn-radius: radius
            transit-time: seg-len / v-max
        ]
        append segments seg

        ;; Link segment to from/to node lists
        foreach n nodes [
            if n/id = from-id [append n/out-segments seg-id]
            if n/id = to-id   [append n/in-segments seg-id]
        ]
        seg
    ]

    ;; Find node by ID
    find-node: function [
        node-id [integer!]
        return: [object!]
    ][
        res: none
        foreach n nodes [
            if n/id = node-id [res: n break]
        ]
        res
    ]

    ;; Find segment by ID
    find-segment: function [
        seg-id [integer!]
        return: [object!]
    ][
        res: none
        foreach s segments [
            if s/id = seg-id [res: s break]
        ]
        res
    ]

    ;; Initialize standard reference 300mm wafer fab layout
    init-default-fab: does [
        clear nodes
        clear segments

        ;; Bay 1: Photolithography Loop (Nodes 1..8)
        add-node 1 node-type-waypoint   0.0   0.0 3.5 "LITHO-BAY"
        add-node 2 node-type-port      10.0   0.0 3.5 "LITHO-BAY" ; Scanner 1 Load Port
        add-node 3 node-type-port      20.0   0.0 3.5 "LITHO-BAY" ; Scanner 2 Load Port
        add-node 4 node-type-diverge   30.0   0.0 3.5 "LITHO-BAY"
        add-node 5 node-type-waypoint  30.0  10.0 3.5 "LITHO-BAY"
        add-node 6 node-type-port      20.0  10.0 3.5 "LITHO-BAY" ; Track Coater/Developer
        add-node 7 node-type-port      10.0  10.0 3.5 "LITHO-BAY" ; Metrology Tool
        add-node 8 node-type-merge      0.0  10.0 3.5 "LITHO-BAY"

        ;; Bay 2: Plasma Etch Loop (Nodes 9..16)
        add-node  9 node-type-waypoint 40.0   0.0 3.5 "ETCH-BAY"
        add-node 10 node-type-port     50.0   0.0 3.5 "ETCH-BAY" ; Etcher 1 Load Port
        add-node 11 node-type-port     60.0   0.0 3.5 "ETCH-BAY" ; Etcher 2 Load Port
        add-node 12 node-type-diverge  70.0   0.0 3.5 "ETCH-BAY"
        add-node 13 node-type-waypoint 70.0  10.0 3.5 "ETCH-BAY"
        add-node 14 node-type-port     60.0  10.0 3.5 "ETCH-BAY" ; Asher Port
        add-node 15 node-type-port     50.0  10.0 3.5 "ETCH-BAY" ; Wet Clean Bench
        add-node 16 node-type-merge    40.0  10.0 3.5 "ETCH-BAY"

        ;; Central Stocker & Inter-Bay Transport (IBT) Express Track (Nodes 17..20)
        add-node 17 node-type-stocker  15.0 -10.0 3.5 "STOCKER-CENTRAL"
        add-node 18 node-type-stocker  55.0 -10.0 3.5 "STOCKER-CENTRAL"
        add-node 19 node-type-merge    35.0  -5.0 3.5 "INTERBAY-EXPRESS"
        add-node 20 node-type-diverge  35.0  15.0 3.5 "INTERBAY-EXPRESS"

        ;; Connect Litho Bay Track Segments (Straight 4.0 m/s, Curves 1.5 m/s)
        add-segment 101 1 2 10.0 4.0 0.0
        add-segment 102 2 3 10.0 4.0 0.0
        add-segment 103 3 4 10.0 4.0 0.0
        add-segment 104 4 5 10.0 1.5 2.0 ; 90-degree curve
        add-segment 105 5 6 10.0 4.0 0.0
        add-segment 106 6 7 10.0 4.0 0.0
        add-segment 107 7 8 10.0 4.0 0.0
        add-segment 108 8 1 10.0 1.5 2.0 ; 90-degree curve

        ;; Connect Etch Bay Track Segments
        add-segment 201  9 10 10.0 4.0 0.0
        add-segment 202 10 11 10.0 4.0 0.0
        add-segment 203 11 12 10.0 4.0 0.0
        add-segment 204 12 13 10.0 1.5 2.0
        add-segment 205 13 14 10.0 4.0 0.0
        add-segment 206 14 15 10.0 4.0 0.0
        add-segment 207 15 16 10.0 4.0 0.0
        add-segment 208 16  9 10.0 1.5 2.0

        ;; Connect Inter-Bay Express Crossovers
        add-segment 301 4  9 10.0 4.0 0.0 ; Litho -> Etch crossover
        add-segment 302 16 8 10.0 4.0 0.0 ; Etch -> Litho return crossover
        add-segment 303 17 1 15.0 3.0 1.0 ; Stocker 1 -> Litho
        add-segment 304 18 9 15.0 3.0 1.0 ; Stocker 2 -> Etch
    ]
]

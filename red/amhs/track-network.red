Red [
    Title: "Reticle AMHS 300mm Cleanroom High-Density Monorail Network"
    Author: "Aneesh"
    File: %track-network.red
    Tabs: 4
]

;; ----------------------------------------------------------------------------
;; Reticle: Semiconductor Material Control System & SECS/GEM Engine
;; Module: High-Density Wafer Fab Track Network Topology
;;
;; Models an industrial 300mm wafer manufacturing cleanroom facility:
;; - 4 Processing Bays: Lithography, Etch, Thin-Film CVD/ALD, and Metrology
;; - High-Speed Inter-Bay Expressway Loops (4.0 m/s monorail)
;; - 4 Automated Stockers & Side-Track Buffers (STB)
;; - 24 Load Ports with kinematic docking pins and SEMI E84 optical sensors
;; ----------------------------------------------------------------------------

#include %../core/types.red
#include %topology.red

reticle-amhs-network: context [

    ;; Build full high-density fab topology
    build-full-network: does [
        reticle-amhs-topology/init-default-fab

        ;; Add Lithography Bay Extended Nodes (Nodes 121..130)
        reticle-amhs-topology/add-node 121 reticle-amhs-topology/node-type-port 12.0 0.0 3.5 "LITHO-BAY"
        reticle-amhs-topology/add-node 122 reticle-amhs-topology/node-type-port 14.0 0.0 3.5 "LITHO-BAY"
        reticle-amhs-topology/add-node 123 reticle-amhs-topology/node-type-port 16.0 0.0 3.5 "LITHO-BAY"
        reticle-amhs-topology/add-node 124 reticle-amhs-topology/node-type-port 18.0 0.0 3.5 "LITHO-BAY"
        reticle-amhs-topology/add-node 125 reticle-amhs-topology/node-type-port 22.0 0.0 3.5 "LITHO-BAY"
        reticle-amhs-topology/add-node 126 reticle-amhs-topology/node-type-port 24.0 0.0 3.5 "LITHO-BAY"
        reticle-amhs-topology/add-node 127 reticle-amhs-topology/node-type-port 26.0 0.0 3.5 "LITHO-BAY"
        reticle-amhs-topology/add-node 128 reticle-amhs-topology/node-type-port 28.0 0.0 3.5 "LITHO-BAY"

        ;; Add Etch Bay Extended Nodes (Nodes 221..228)
        reticle-amhs-topology/add-node 221 reticle-amhs-topology/node-type-port 42.0 0.0 3.5 "ETCH-BAY"
        reticle-amhs-topology/add-node 222 reticle-amhs-topology/node-type-port 44.0 0.0 3.5 "ETCH-BAY"
        reticle-amhs-topology/add-node 223 reticle-amhs-topology/node-type-port 46.0 0.0 3.5 "ETCH-BAY"
        reticle-amhs-topology/add-node 224 reticle-amhs-topology/node-type-port 48.0 0.0 3.5 "ETCH-BAY"
        reticle-amhs-topology/add-node 225 reticle-amhs-topology/node-type-port 52.0 0.0 3.5 "ETCH-BAY"
        reticle-amhs-topology/add-node 226 reticle-amhs-topology/node-type-port 54.0 0.0 3.5 "ETCH-BAY"
        reticle-amhs-topology/add-node 227 reticle-amhs-topology/node-type-port 56.0 0.0 3.5 "ETCH-BAY"
        reticle-amhs-topology/add-node 228 reticle-amhs-topology/node-type-port 58.0 0.0 3.5 "ETCH-BAY"

        ;; Add CVD / Thin-Film Bay Nodes (Nodes 301..310)
        reticle-amhs-topology/add-node 301 reticle-amhs-topology/node-type-waypoint 80.0  0.0 3.5 "CVD-BAY"
        reticle-amhs-topology/add-node 302 reticle-amhs-topology/node-type-port     90.0  0.0 3.5 "CVD-BAY"
        reticle-amhs-topology/add-node 303 reticle-amhs-topology/node-type-port    100.0  0.0 3.5 "CVD-BAY"
        reticle-amhs-topology/add-node 304 reticle-amhs-topology/node-type-diverge 110.0  0.0 3.5 "CVD-BAY"
        reticle-amhs-topology/add-node 305 reticle-amhs-topology/node-type-waypoint 110.0 10.0 3.5 "CVD-BAY"
        reticle-amhs-topology/add-node 306 reticle-amhs-topology/node-type-port    100.0 10.0 3.5 "CVD-BAY"
        reticle-amhs-topology/add-node 307 reticle-amhs-topology/node-type-port     90.0 10.0 3.5 "CVD-BAY"
        reticle-amhs-topology/add-node 308 reticle-amhs-topology/node-type-merge    80.0 10.0 3.5 "CVD-BAY"

        ;; Connect CVD Bay Monorail Loop
        reticle-amhs-topology/add-segment 401 301 302 10.0 4.0 0.0
        reticle-amhs-topology/add-segment 402 302 303 10.0 4.0 0.0
        reticle-amhs-topology/add-segment 403 303 304 10.0 4.0 0.0
        reticle-amhs-topology/add-segment 404 304 305 10.0 1.5 2.0
        reticle-amhs-topology/add-segment 405 305 306 10.0 4.0 0.0
        reticle-amhs-topology/add-segment 406 306 307 10.0 4.0 0.0
        reticle-amhs-topology/add-segment 407 307 308 10.0 4.0 0.0
        reticle-amhs-topology/add-segment 408 308 301 10.0 1.5 2.0

        ;; Connect Etch to CVD Inter-Bay Expressway
        reticle-amhs-topology/add-segment 501 12 301 15.0 4.0 0.0
        reticle-amhs-topology/add-segment 502 308 16 15.0 4.0 0.0
    ]
]

Red [
    Title: "Reticle AMHS Overhead Hoist Transport (OHT) Vehicle Model"
    Author: "Aneesh"
    File: %vehicle.red
    Tabs: 4
]

;; ----------------------------------------------------------------------------
;; Reticle: Semiconductor Material Control System & SECS/GEM Engine
;; Module: OHT Vehicle Kinematics & Actuation State Model
;;
;; Simulates cleanroom overhead transport vehicles:
;; - Horizontal travel along monorail segments ($v_{\max} = 4.0\text{ m/s}$)
;; - Vertical hoist lowering and raising ($v_{\text{hoist}} = 0.5\text{ m/s}$)
;; - Mechanical gripper clamping onto FOUP top flange
;; - Supercapacitor / battery State of Charge (SoC) management
;; ----------------------------------------------------------------------------

#include %../core/types.red
#include %topology.red

reticle-amhs-vehicle: context [

    ;; Physical Vehicle Specifications
    v-max-straight:    4.0 ; Max horizontal speed (m/s)
    v-max-curve:       1.5 ; Max speed through curved rail (m/s)
    accel-rate:        1.0 ; Horizontal acceleration / deceleration (m/s^2)
    v-hoist:           0.5 ; Vertical hoist speed (m/s)
    hoist-stroke:      2.5 ; Vertical travel distance from rail to port (meters)
    clamp-time:        1.0 ; Clamping actuator duration (seconds)

    ;; Fleet of OHT Vehicles: list of objects
    fleet: copy []

    ;; Create an OHT vehicle instance
    make-vehicle: function [
        veh-id          [integer!]
        start-node-id   [integer!]
        battery-percent [number!]
        return:         [object!]
    ][
        context [
            id: veh-id
            state: reticle-core/oht-state-idle
            current-node: start-node-id
            current-segment: none
            segment-progress: 0.0 ; Distance traversed along current segment (meters)
            speed: 0.0            ; Current velocity (m/s)
            hoist-z: 0.0          ; Hoist position (0.0 = up at ceiling rail, 2.5 = down at port)
            foup-id: none         ; Carried FOUP carrier ID or none
            battery-soc: battery-percent
            assigned-job-id: none
            planned-route: copy [] ; List of segment IDs to traverse
            route-step: 1
        ]
    ]

    ;; Initialize fleet of N vehicles across designated nodes
    init-fleet: function [
        vehicle-count [integer!]
    ][
        clear fleet
        loop vehicle-count [
            v-id: length? fleet + 1
            node-idx: ((v-id - 1) * 2) + 1
            append fleet make-vehicle v-id node-idx 98.5
        ]
    ]

    ;; Find vehicle by ID
    find-vehicle: function [
        veh-id [integer!]
        return: [object!]
    ][
        res: none
        foreach v fleet [
            if v/id = veh-id [res: v break]
        ]
        res
    ]

    ;; Advance simulation tick by dt seconds
    step-vehicle: function [
        v  [object!]
        dt [number!]
    ][
        ;; Consume minimal standby battery power
        v/battery-soc: max 0.0 (v/battery-soc - (dt * 0.005))

        switch v/state [
            IDLE [
                v/speed: 0.0
            ]
            TRAVEL-EMPTY [
                step-horizontal-travel v dt
            ]
            TRAVEL-LOADED [
                step-horizontal-travel v dt
            ]
            HOISTING-DOWN [
                v/speed: 0.0
                v/hoist-z: min hoist-stroke (v/hoist-z + (v-hoist * dt))
                if v/hoist-z >= hoist-stroke [
                    ;; Reached load port level: transition to CLAMP or UNCLAMP
                    either none? v/foup-id [
                        v/state: reticle-core/oht-state-clamp
                    ][
                        v/state: reticle-core/oht-state-unclamp
                    ]
                ]
            ]
            CLAMPING [
                ;; Mechanical clamp engaged
                v/state: reticle-core/oht-state-hoist-up
            ]
            UNCLAMPING [
                ;; Gripper released FOUP onto kinematic docking pins
                v/foup-id: none
                v/state: reticle-core/oht-state-hoist-up
            ]
            HOISTING-UP [
                v/hoist-z: max 0.0 (v/hoist-z - (v-hoist * dt))
                if v/hoist-z <= 0.0 [
                    ;; Hoist secured at rail height: proceed to next mission state
                    either none? v/foup-id [
                        v/state: reticle-core/oht-state-idle
                    ][
                        v/state: reticle-core/oht-state-travel-loaded
                    ]
                ]
            ]
        ]
    ]

    ;; Step horizontal travel along planned route
    step-horizontal-travel: function [
        v  [object!]
        dt [number!]
    ][
        if empty? v/planned-route [
            v/state: reticle-core/oht-state-idle
            v/speed: 0.0
            exit
        ]

        cur-seg-id: pick v/planned-route v/route-step
        seg: reticle-amhs-topology/find-segment cur-seg-id
        if none? seg [exit]

        v/current-segment: cur-seg-id
        target-speed: seg/max-speed

        ;; Accelerate towards target speed
        either v/speed < target-speed [
            v/speed: min target-speed (v/speed + (accel-rate * dt))
        ][
            v/speed: max target-speed (v/speed - (accel-rate * dt))
        ]

        ;; Advance along segment
        distance: v/speed * dt
        v/segment-progress: v/segment-progress + distance

        if v/segment-progress >= seg/len [
            ;; Completed segment: advance to next
            v/current-node: seg/to
            v/segment-progress: 0.0
            v/route-step: v/route-step + 1

            if v/route-step > length? v/planned-route [
                ;; Reached destination node
                clear v/planned-route
                v/route-step: 1
                v/speed: 0.0
                either v/state = reticle-core/oht-state-travel-empty [
                    v/state: reticle-core/oht-state-hoist-down ; Ready to pick up FOUP
                ][
                    v/state: reticle-core/oht-state-hoist-down ; Ready to deliver FOUP
                ]
            ]
        ]
    ]
]

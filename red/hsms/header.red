Red [
    Title: "Reticle HSMS Header Specification and Packing"
    Author: "Aneesh"
    File: %header.red
    Tabs: 4
]

;; ----------------------------------------------------------------------------
;; Reticle: Semiconductor Material Control System & SECS/GEM Engine
;; Module: HSMS 10-Byte Header Packing & Transaction Identifier Manager
;;
;; Conforms to SEMI E37 / E37.1 High-Speed SECS Message Services.
;; Encodes and decodes the 10-byte header:
;; - Bytes 0..1: Session ID / Device ID (16-bit big endian)
;; - Byte 2:     Stream ID (bits 0..6) & Wait Bit (bit 7)
;; - Byte 3:     Function ID
;; - Byte 4:     Presentation Type (P-Type = 0 for SECS-II)
;; - Byte 5:     Session Type (S-Type = 0..9)
;; - Bytes 6..9: System Bytes / Transaction ID (32-bit big endian)
;; ----------------------------------------------------------------------------

#include %../core/types.red

reticle-hsms-header: context [

    ;; Monotonic transaction ID generator
    next-system-id: 1000

    generate-system-id: function [
        return: [integer!]
    ][
        next-system-id: next-system-id + 1
        next-system-id
    ]

    ;; Pack HSMS header into 10-byte binary buffer
    pack: function [
        session-id   [integer!]
        stream       [integer!]
        function     [integer!]
        wait-bit     [logic!]
        p-type       [integer!]
        s-type       [integer!]
        system-bytes [integer!]
        return:      [binary!]
    ][
        hdr: make binary! 10
        ;; Session ID (2 bytes, big-endian)
        append hdr to-char (shift/right session-id 8)
        append hdr to-char (session-id and 255)

        ;; Stream byte with W-bit in bit 7
        st-byte: (stream and 127) or (either wait-bit [128] [0])
        append hdr to-char st-byte

        ;; Function byte
        append hdr to-char (function and 255)

        ;; P-Type & S-Type
        append hdr to-char (p-type and 255)
        append hdr to-char (s-type and 255)

        ;; System bytes (4 bytes, big-endian)
        append hdr to-char ((shift/right system-bytes 24) and 255)
        append hdr to-char ((shift/right system-bytes 16) and 255)
        append hdr to-char ((shift/right system-bytes 8) and 255)
        append hdr to-char (system-bytes and 255)

        hdr
    ]

    ;; Unpack 10-byte binary buffer into structured descriptor
    unpack: function [
        buf [binary!]
        return: [object!]
    ][
        if (length? buf) < 10 [return none]

        s-id: (shift/left (to-integer buf/1) 8) or (to-integer buf/2)
        raw-st: to-integer buf/3
        w-bit: (raw-st and 128) <> 0
        st: raw-st and 127
        fn: to-integer buf/4
        p-typ: to-integer buf/5
        s-typ: to-integer buf/6

        sys-id: 0
        loop 4 [
            idx: 6 + index? [1 2 3 4]
            ;; Extract 4-byte transaction id
        ]
        b6: to-integer buf/7
        b7: to-integer buf/8
        b8: to-integer buf/9
        b9: to-integer buf/10
        sys-id: (shift/left b6 24) or (shift/left b7 16) or (shift/left b8 8) or b9

        context [
            session: s-id
            stream: st
            function: fn
            wait-bit: w-bit
            p-type: p-typ
            s-type: s-typ
            system-bytes: sys-id
            is-data?: (s-typ = reticle-core/stype-data)
            is-control?: (s-typ <> reticle-core/stype-data)
        ]
    ]

    ;; Format control message subtype into human-readable string
    stype-to-string: function [
        s-type [integer!]
        return: [string!]
    ][
        switch s-type [
            0 ["DATA"]
            1 ["SELECT-REQ"]
            2 ["SELECT-RSP"]
            3 ["DESELECT-REQ"]
            4 ["DESELECT-RSP"]
            5 ["LINKTEST-REQ"]
            6 ["LINKTEST-RSP"]
            7 ["REJECT-REQ"]
            9 ["SEPARATE-REQ"]
            default ["UNKNOWN-STYPE"]
        ]
    ]
]

Red [
    Title: "Reticle CRC Verification Engine"
    Author: "Aneesh"
    File: %crc.red
    Tabs: 4
]

;; ----------------------------------------------------------------------------
;; Reticle: Semiconductor Material Control System & SECS/GEM Engine
;; Module: Cyclic Redundancy Check (CRC-16 & CRC-32)
;;
;; Provides bitwise frame verification for SECS-I packet wrapping and
;; HSMS-SS message integrity verification.
;; ----------------------------------------------------------------------------

reticle-crc: context [

    ;; CRC-16-CCITT standard polynomial (0x1021)
    crc16-poly: 4129  ; 1021h

    ;; Castagnoli CRC-32C polynomial (0x82F63B78 reflected)
    crc32c-poly: -2097792136 ; 82F63B78h as signed 32-bit int

    ;; Compute 16-bit CRC over binary payload using bitwise arithmetic
    compute-crc16: function [
        "Calculate CCITT CRC-16 over binary data buffer"
        data [binary! string!]
        return: [integer!]
    ][
        if string? data [data: to-binary data]
        crc: 65535 ; Initial 0xFFFF
        
        foreach byte data [
            crc: crc xor (shift/left to-integer byte 8)
            loop 8 [
                either (crc and 32768) <> 0 [
                    crc: ((shift/left crc 1) xor crc16-poly) and 65535
                ][
                    crc: (shift/left crc 1) and 65535
                ]
            ]
        ]
        crc
    ]

    ;; Compute 32-bit Castagnoli CRC-32C over binary payload
    compute-crc32c: function [
        "Calculate Castagnoli CRC-32C over binary data buffer"
        data [binary! string!]
        return: [integer!]
    ][
        if string? data [data: to-binary data]
        crc: -1 ; 0xFFFFFFFF
        
        foreach byte data [
            crc: crc xor to-integer byte
            loop 8 [
                b: crc and 1
                crc: shift/logical crc 1
                if b = 1 [
                    crc: crc xor crc32c-poly
                ]
            ]
        ]
        crc xor -1 ; Final XOR with 0xFFFFFFFF
    ]

    ;; Verify whether trailing 2 bytes of data match computed CRC-16
    verify-crc16: function [
        "Verify CRC-16 checksum embedded in packet tail"
        packet [binary!]
        return: [logic!]
    ][
        len: length? packet
        if len < 3 [return false]
        body-len: len - 2
        body: copy/part packet body-len
        
        expected-high: to-integer packet/(len - 1)
        expected-low: to-integer packet/(len)
        expected-crc: (shift/left expected-high 8) or expected-low
        
        actual-crc: compute-crc16 body
        actual-crc = expected-crc
    ]
]

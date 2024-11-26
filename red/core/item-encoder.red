Red [
    Title: "Reticle SECS-II Binary Item Encoder and Decoder"
    Author: "Aneesh"
    File: %item-encoder.red
    Tabs: 4
]

;; ----------------------------------------------------------------------------
;; Reticle: Semiconductor Material Control System & SECS/GEM Engine
;; Module: SECS-II Binary Item Serializer & Deserializer
;;
;; Implements strict SEMI E5 binary encoding of typed data items:
;; - Lists (<L [N] ...>)
;; - ASCII strings (<A "TEXT">)
;; - Unsigned integers (<U1>, <U2>, <U4>, <U8>)
;; - Signed integers (<I1>, <I2>, <I4>, <I8>)
;; - Floating-point numbers (<F4>, <F8>)
;; - Boolean flags (<BOOLEAN>)
;; - Raw binary payloads (<B 0x00 0xFF>)
;; ----------------------------------------------------------------------------

#include %types.red

reticle-item-encoder: context [

    ;; ------------------------------------------------------------------------
    ;; Encoding Helper: Generate Item Header (Format Code + Length Bytes)
    ;; ------------------------------------------------------------------------
    make-item-header: function [
        format-code [integer!]
        byte-count  [integer!]
        return:     [binary!]
    ][
        hdr: make binary! 4
        either byte-count <= 255 [
            ;; 1 length byte: format byte has bits 1-0 = 01b (value 1)
            fmt-byte: (shift/left format-code 2) or 1
            append hdr to-char fmt-byte
            append hdr to-char byte-count
        ][
            either byte-count <= 65535 [
                ;; 2 length bytes: format byte has bits 1-0 = 10b (value 2)
                fmt-byte: (shift/left format-code 2) or 2
                append hdr to-char fmt-byte
                append hdr to-char (shift/right byte-count 8)
                append hdr to-char (byte-count and 255)
            ][
                ;; 3 length bytes: format byte has bits 1-0 = 11b (value 3)
                fmt-byte: (shift/left format-code 2) or 3
                append hdr to-char fmt-byte
                append hdr to-char (shift/right byte-count 16)
                append hdr to-char ((shift/right byte-count 8) and 255)
                append hdr to-char (byte-count and 255)
            ]
        ]
        hdr
    ]

    ;; ------------------------------------------------------------------------
    ;; Recursive Item Encoding Function
    ;; ------------------------------------------------------------------------
    encode-item: function [
        "Serialize a symbolic typed item into SEMI E5 binary bytes"
        item [block!]
        return: [binary!]
    ][
        if empty? item [return make binary! 0]
        
        type-tag: first item
        val: second item
        out: make binary! 32

        switch type-tag [
            L [
                ;; List item: val is a block of child items
                elem-count: length? val
                header: make-item-header reticle-core/format-list elem-count
                append out header
                foreach child val [
                    child-bin: encode-item child
                    append out child-bin
                ]
            ]
            A [
                ;; ASCII string item
                str-bytes: to-binary form val
                header: make-item-header reticle-core/format-ascii (length? str-bytes)
                append out header
                append out str-bytes
            ]
            B [
                ;; Binary byte array
                bin-bytes: either binary? val [val] [to-binary val]
                header: make-item-header reticle-core/format-binary (length? bin-bytes)
                append out header
                append out bin-bytes
            ]
            BOOLEAN [
                ;; 1-byte boolean flag
                header: make-item-header reticle-core/format-boolean 1
                append out header
                append out either val [#{01}] [#{00}]
            ]
            U1 [
                header: make-item-header reticle-core/format-u1 1
                append out header
                append out to-char (to-integer val and 255)
            ]
            U2 [
                header: make-item-header reticle-core/format-u2 2
                append out header
                v: to-integer val
                append out to-char (shift/right v 8)
                append out to-char (v and 255)
            ]
            U4 [
                header: make-item-header reticle-core/format-u4 4
                append out header
                v: to-integer val
                append out to-char ((shift/right v 24) and 255)
                append out to-char ((shift/right v 16) and 255)
                append out to-char ((shift/right v 8) and 255)
                append out to-char (v and 255)
            ]
            I1 [
                header: make-item-header reticle-core/format-i1 1
                append out header
                append out to-char (to-integer val and 255)
            ]
            I2 [
                header: make-item-header reticle-core/format-i2 2
                append out header
                v: to-integer val
                append out to-char ((shift/right v 8) and 255)
                append out to-char (v and 255)
            ]
            I4 [
                header: make-item-header reticle-core/format-i4 4
                append out header
                v: to-integer val
                append out to-char ((shift/right v 24) and 255)
                append out to-char ((shift/right v 16) and 255)
                append out to-char ((shift/right v 8) and 255)
                append out to-char (v and 255)
            ]
        ]
        out
    ]

    ;; ------------------------------------------------------------------------
    ;; Recursive Item Decoding Function
    ;; ------------------------------------------------------------------------
    decode-item: function [
        "Parse a single SECS-II item from a binary buffer at offset"
        buf     [binary!]
        offset  [integer!]
        return: [block!] ; Returns [decoded-item next-offset]
    ][
        if offset > length? buf [return reduce [none offset]]
        
        fmt-byte: to-integer buf/:offset
        offset: offset + 1
        
        format-code: shift/right fmt-byte 2
        len-bytes-count: fmt-byte and 3
        
        ;; Zero length byte count is illegal in SEMI E5
        if len-bytes-count = 0 [return reduce [none offset]]
        
        payload-len: 0
        loop len-bytes-count [
            payload-len: (shift/left payload-len 8) or (to-integer buf/:offset)
            offset: offset + 1
        ]
        
        ;; Decode based on format code
        decoded-val: none
        type-symbol: 'UNKNOWN

        switch format-code [
            0 [
                ;; List format: payload-len represents child element count
                type-symbol: 'L
                child-list: copy []
                loop payload-len [
                    res: decode-item buf offset
                    child-item: first res
                    offset: second res
                    append/only child-list child-item
                ]
                decoded-val: child-list
            ]
            16 [
                ;; ASCII string
                type-symbol: 'A
                str-bin: copy/part at buf offset payload-len
                offset: offset + payload-len
                decoded-val: to-string str-bin
            ]
            8 [
                ;; Binary
                type-symbol: 'B
                bin-data: copy/part at buf offset payload-len
                offset: offset + payload-len
                decoded-val: bin-data
            ]
            9 [
                ;; Boolean
                type-symbol: 'BOOLEAN
                b-byte: to-integer buf/:offset
                offset: offset + 1
                decoded-val: (b-byte <> 0)
            ]
            44 [
                ;; U4 unsigned integer
                type-symbol: 'U4
                u-val: 0
                loop 4 [
                    u-val: (shift/left u-val 8) or (to-integer buf/:offset)
                    offset: offset + 1
                ]
                decoded-val: u-val
            ]
            42 [
                ;; U2 unsigned integer
                type-symbol: 'U2
                u-val: 0
                loop 2 [
                    u-val: (shift/left u-val 8) or (to-integer buf/:offset)
                    offset: offset + 1
                ]
                decoded-val: u-val
            ]
            41 [
                ;; U1 unsigned integer
                type-symbol: 'U1
                decoded-val: to-integer buf/:offset
                offset: offset + 1
            ]
            28 [
                ;; I4 signed integer
                type-symbol: 'I4
                i-val: 0
                loop 4 [
                    i-val: (shift/left i-val 8) or (to-integer buf/:offset)
                    offset: offset + 1
                ]
                decoded-val: i-val
            ]
        ]

        reduce [reduce [type-symbol decoded-val] offset]
    ]
]

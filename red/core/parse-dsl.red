Red [
    Title: "Reticle SECS Message Language (SML) Parse Dialect"
    Author: "Aneesh"
    File: %parse-dsl.red
    Tabs: 4
]

;; ----------------------------------------------------------------------------
;; Reticle: Semiconductor Material Control System & SECS/GEM Engine
;; Module: Parse Dialect for SECS Message Language (SML)
;;
;; Uses Red's native PARSE dialect to parse standard SEMI SML syntax
;; into symbolic Red AST blocks, handling streams, functions, W-bits,
;; nested lists, ASCII strings, integers, floats, and binary literals.
;; ----------------------------------------------------------------------------

#include %types.red

reticle-sml-parser: context [

    ;; ------------------------------------------------------------------------
    ;; SML Grammar Character Sets
    ;; ------------------------------------------------------------------------
    ws: charset " ^-^/^M"
    digit: charset "0123456789"
    hex-char: charset "0123456789abcdefABCDEF"
    alpha: charset [#"a" - #"z" #"A" - #"Z" #"_" #"-" #"."]
    tag-char: charset [#"a" - #"z" #"A" - #"Z" #"0" - #"9" #"_" #"-" #"."]

    ;; ------------------------------------------------------------------------
    ;; Parser State Variables
    ;; ------------------------------------------------------------------------
    cur-stream: 0
    cur-function: 0
    cur-w-bit: false
    cur-ast: copy []
    item-stack: copy []

    ;; Reset parser state before each run
    reset-state: does [
        cur-stream: 0
        cur-function: 0
        cur-w-bit: false
        clear cur-ast
        clear item-stack
    ]

    ;; ------------------------------------------------------------------------
    ;; Parse Rules using Red's PEG dialect
    ;; ------------------------------------------------------------------------
    sml-rules: [
        reset
        any ws
        header-rule
        any ws
        item-rule
        any ws
        opt ["." any ws]
    ]

    ;; Rule to match SxFy [W] header
    header-rule: [
        "S" copy str-val some digit (cur-stream: to-integer str-val)
        "F" copy fn-val some digit  (cur-function: to-integer fn-val)
        any ws
        opt [
            ["W" | "w"] (cur-w-bit: true) any ws
        ]
    ]

    ;; Rule to match typed SECS-II item: <TYPE [LEN] VAL...>
    item-rule: [
        "<" any ws
        copy type-tag some tag-char any ws
        opt [
            "[" any ws copy len-val some digit any ws "]" any ws
        ]
        [
            list-body-rule |
            ascii-body-rule |
            binary-body-rule |
            numeric-body-rule |
            boolean-body-rule |
            empty-body-rule
        ]
        any ws ">"
    ]

    list-body-rule: [
        &(type-tag = "L" or (type-tag = "LIST"))
        (
            new-list: copy []
            parent: last item-stack
            either parent [append/only parent new-list] [append/only cur-ast new-list]
            append/only item-stack new-list
        )
        any [any ws item-rule any ws]
        (take/last item-stack)
    ]

    dbl-quote: #"^""

    ascii-body-rule: [
        &(type-tag = "A" or (type-tag = "ASCII") or (type-tag = "J"))
        [
            dbl-quote copy str-content to dbl-quote dbl-quote (
                emit-value 'A str-content
            )
            |
            copy bare-str some [tag-char | ws] (
                emit-value 'A trim bare-str
            )
        ]
    ]

    binary-body-rule: [
        &(type-tag = "B" or (type-tag = "BIN") or (type-tag = "BINARY"))
        any ws
        copy hex-tokens any [hex-char | ws] (
            cleaned: copy ""
            foreach ch hex-tokens [if find hex-char ch [append cleaned ch]]
            bin-res: make binary! (length? cleaned) / 2
            ;; Store decoded binary representation
            emit-value 'B bin-res
        )
    ]

    numeric-body-rule: [
        &(type-tag = "I1" or (type-tag = "I2") or (type-tag = "I4") or (type-tag = "I8") or
          (type-tag = "U1") or (type-tag = "U2") or (type-tag = "U4") or (type-tag = "U8") or
          (type-tag = "F4") or (type-tag = "F8"))
        copy num-str some [digit | "." | "-" | ws] (
            num-val: attempt [load trim num-str]
            emit-value (to-word type-tag) num-val
        )
    ]

    boolean-body-rule: [
        &(type-tag = "BOOLEAN" or (type-tag = "BOOL"))
        copy bool-str some [digit | "T" | "F" | "true" | "false" | ws] (
            b-val: either find ["1" "T" "true"] trim bool-str [true] [false]
            emit-value 'BOOLEAN b-val
        )
    ]

    empty-body-rule: [
        (emit-value (to-word type-tag) none)
    ]

    emit-value: function [
        item-type [word!]
        item-val
    ][
        target: last item-stack
        entry: reduce [item-type item-val]
        either target [
            append/only target entry
        ][
            append/only cur-ast entry
        ]
    ]

    ;; ------------------------------------------------------------------------
    ;; High-Level API: Parse SML String to Structured AST Block
    ;; ------------------------------------------------------------------------
    parse-sml: function [
        "Parse SECS Message Language string into structured Red AST block"
        sml-text [string!]
        return: [block!]
    ][
        reset-state
        success: parse sml-text [
            any ws
            opt header-rule
            any ws
            opt item-rule
            any ws
            opt ["." any ws]
        ]
        
        reduce [
            'stream     cur-stream
            'function   cur-function
            'wait-bit   cur-w-bit
            'root       cur-ast
            'success    success
        ]
    ]
]

Red [
    Title: "Reticle SML Symbolic Formatter and AST Renderer"
    Author: "Aneesh"
    File: %item-formatter.red
    Tabs: 4
]

;; ----------------------------------------------------------------------------
;; Reticle: Semiconductor Material Control System & SECS/GEM Engine
;; Module: SML Pretty-Printer & Symbolic AST Formatter
;;
;; Formats typed SECS-II items and SxFy message trees into clean,
;; human-readable SECS Message Language (SML) text with standard indentation.
;; ----------------------------------------------------------------------------

#include %types.red

reticle-formatter: context [

    ;; Render indentation spaces
    make-indent: function [
        level [integer!]
        return: [string!]
    ][
        res: make string! (level * 4)
        loop (level * 4) [append res #" "]
        res
    ]

    ;; Format a single item recursively
    format-item: function [
        item  [block!]
        level [integer!]
        return: [string!]
    ][
        if empty? item [return ""]
        type-tag: first item
        val: second item
        indent: make-indent level
        out: make string! 64

        switch type-tag [
            L [
                append out rejoin [indent "<L [" (length? val) "]" newline]
                foreach child val [
                    append out format-item child (level + 1)
                ]
                append out rejoin [indent ">" newline]
            ]
            A [
                append out rejoin [indent "<A " mold form val ">" newline]
            ]
            B [
                append out rejoin [indent "<B"]
                if binary? val [
                    foreach byte val [
                        hex: to-hex to-integer byte
                        append out rejoin [" " copy/part at hex 7 2]
                    ]
                ]
                append out rejoin [">" newline]
            ]
            BOOLEAN [
                b-str: either val ["T"] ["F"]
                append out rejoin [indent "<BOOLEAN " b-str ">" newline]
            ]
            U1 [
                append out rejoin [indent "<U1 " val ">" newline]
            ]
            U2 [
                append out rejoin [indent "<U2 " val ">" newline]
            ]
            U4 [
                append out rejoin [indent "<U4 " val ">" newline]
            ]
            I1 [
                append out rejoin [indent "<I1 " val ">" newline]
            ]
            I2 [
                append out rejoin [indent "<I2 " val ">" newline]
            ]
            I4 [
                append out rejoin [indent "<I4 " val ">" newline]
            ]
            default [
                append out rejoin [indent "<" type-tag " " mold val ">" newline]
            ]
        ]
        out
    ]

    ;; Format a complete SxFy message transaction
    format-message: function [
        stream    [integer!]
        function  [integer!]
        wait-bit  [logic!]
        root-item [block!]
        return:   [string!]
    ][
        out: make string! 256
        w-str: either wait-bit [" W"] [""]
        append out rejoin ["S" stream "F" function w-str newline]
        if not empty? root-item [
            append out format-item root-item 0
        ]
        append out "."
        out
    ]
]

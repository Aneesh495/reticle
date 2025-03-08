Red [
    Title: "Reticle Red Unit Tests: Core, CRC, SML Parser, and Item Encoder"
    Author: "Aneesh"
    File: %test-core.red
    Tabs: 4
]

#include %../core/types.red
#include %../core/crc.red
#include %../core/parse-dsl.red
#include %../core/item-encoder.red
#include %../core/item-formatter.red

test-core-suite: context [

    passed: 0
    failed: 0

    assert-true: function [cond [logic!] msg [string!]][
        either cond [
            passed: passed + 1
            print ["> PASS:" msg]
        ][
            failed: failed + 1
            print ["> FAIL:" msg]
        ]
    ]

    run: does [
        print "=== Reticle Unit Test Suite: Core & SECS-II Encoding ==="

        ;; Test 1: CRC-16 Calculation
        crc16-res: reticle-crc/compute-crc16 "123456789"
        assert-true (crc16-res = 10673) "CRC-16 CCITT computation on 123456789"

        ;; Test 2: SECS-II Item Encoding: ASCII String
        item-ascii: reduce ['A "TEST_STEPPER"]
        encoded-ascii: reticle-item-encoder/encode-item item-ascii
        assert-true ((length? encoded-ascii) = 14) "ASCII item binary length (2 header + 12 string bytes)"

        ;; Test 3: SECS-II Item Decoding: ASCII String
        decoded-res: reticle-item-encoder/decode-item encoded-ascii 1
        decoded-item: first decoded-res
        assert-true (decoded-item/1 = 'A) "Decoded item format code is ASCII"
        assert-true (decoded-item/2 = "TEST_STEPPER") "Decoded string value matches original"

        ;; Test 4: Nested List Item Encoding and Decoding
        nested-list: reduce ['L reduce [
            reduce ['A "RECIPE_01"]
            reduce ['U4 1050]
            reduce ['BOOLEAN true]
        ]]
        encoded-list: reticle-item-encoder/encode-item nested-list
        decoded-list-res: reticle-item-encoder/decode-item encoded-list 1
        decoded-list: first decoded-list-res
        assert-true (decoded-list/1 = 'L) "Decoded outer format is List"
        assert-true ((length? decoded-list/2) = 3) "Decoded list has 3 children"

        ;; Test 5: SML Parser Rule Execution
        sml-sample: {S1F13 W <L [2] <A "MDLN-01"> <A "REV-1.0"> > .}
        ast-res: reticle-sml-parser/parse-sml sml-sample
        assert-true (ast-res/2 = 1) "SML parsed stream number is 1"
        assert-true (ast-res/4 = 13) "SML parsed function number is 13"
        assert-true (ast-res/6 = true) "SML parsed wait bit is true"

        print ["Core Test Suite Completed: Passed:" passed "Failed:" failed]
    ]
]

test-core-suite/run

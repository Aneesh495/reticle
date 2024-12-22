Red [
    Title: "Reticle HSMS Protocol Driver and Framing Engine"
    Author: "Aneesh"
    File: %driver.red
    Tabs: 4
]

;; ----------------------------------------------------------------------------
;; Reticle: Semiconductor Material Control System & SECS/GEM Engine
;; Module: HSMS Frame Assembly & Socket Driver
;;
;; Handles 4-byte network message length prefix framing, buffer reassembly,
;; packet validation, and primary/secondary transaction dispatch.
;; ----------------------------------------------------------------------------

#include %header.red
#include %session.red
#include %timers.red
#include %../core/item-encoder.red

reticle-hsms-driver: context [

    ;; Raw byte accumulation buffer for TCP stream reassembly
    rx-buffer: make binary! 4096

    ;; Primary transaction reply map: [system-bytes -> callback]
    pending-transactions: copy []

    ;; Frame an outbound HSMS message: [4-byte length prefix] [10-byte header] [payload]
    frame-message: function [
        hdr-bin [binary!]
        body-bin [binary!]
        return: [binary!]
    ][
        total-len: (length? hdr-bin) + (length? body-bin)
        frame: make binary! (4 + total-len)
        
        ;; 4-byte length prefix (big endian)
        append frame to-char ((shift/right total-len 24) and 255)
        append frame to-char ((shift/right total-len 16) and 255)
        append frame to-char ((shift/right total-len 8) and 255)
        append frame to-char (total-len and 255)
        
        append frame hdr-bin
        append frame body-bin
        frame
    ]

    ;; Ingest incoming stream bytes and extract completed messages
    ingest-bytes: function [
        chunk [binary!]
        return: [block!] ; List of completed [header-object body-binary]
    ][
        append rx-buffer chunk
        completed-messages: copy []

        while [(length? rx-buffer) >= 4] [
            ;; Read 4-byte message length
            b1: to-integer rx-buffer/1
            b2: to-integer rx-buffer/2
            b3: to-integer rx-buffer/3
            b4: to-integer rx-buffer/4
            msg-len: (shift/left b1 24) or (shift/left b2 16) or (shift/left b3 8) or b4

            if msg-len < 10 [
                ;; Illegal frame size: protocol error
                clear rx-buffer
                break
            ]

            total-frame-size: 4 + msg-len
            if (length? rx-buffer) < total-frame-size [
                ;; Incomplete frame: wait for more network bytes
                break
            ]

            ;; Extract complete frame
            hdr-bytes: copy/part at rx-buffer 5 10
            body-bytes: copy/part at rx-buffer 15 (msg-len - 10)

            hdr-obj: reticle-hsms-header/unpack hdr-bytes
            if hdr-obj [
                append/only completed-messages reduce [hdr-obj body-bytes]
            ]

            ;; Consume frame from buffer
            remove/part rx-buffer total-frame-size
        ]

        completed-messages
    ]

    ;; Register an outbound primary transaction with T3 reply timeout
    register-transaction: function [
        system-bytes [integer!]
        timeout-sec  [number!]
        timeout-action [block!]
    ][
        reticle-hsms-timers/start system-bytes timeout-sec timeout-action
        append pending-transactions system-bytes
    ]

    ;; Complete a transaction on secondary reply receipt
    complete-transaction: function [
        system-bytes [integer!]
    ][
        reticle-hsms-timers/stop system-bytes
        remove-each sys-id pending-transactions [sys-id = system-bytes]
    ]
]

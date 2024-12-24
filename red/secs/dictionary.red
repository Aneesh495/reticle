Red [
    Title: "Reticle SEMI E5 SECS-II Message Dictionary"
    Author: "Aneesh"
    File: %dictionary.red
    Tabs: 4
]

;; ----------------------------------------------------------------------------
;; Reticle: Semiconductor Material Control System & SECS/GEM Engine
;; Module: SEMI E5 SECS-II Stream & Function Message Dictionary
;;
;; Provides formal message signatures, expected parameter layouts,
;; primary/secondary correlation pairs, and directional classifications:
;; - H -> E (Host to Equipment)
;; - E -> H (Equipment to Host)
;; - H <-> E (Bidirectional)
;; ----------------------------------------------------------------------------

reticle-secs-dictionary: context [

    ;; Stream/Function catalog entries: [S F name direction wait-bit description]
    catalog: [
        1  1 "Are You Online Request"                   'H->E true  "Verify connectivity between host and equipment"
        1  2 "Are You Online Data"                      'E->H false "Equipment model and software revision reply"
        1  3 "Selected Status Request"                  'H->E true  "Query specific Status Variables (SVIDs)"
        1  4 "Selected Status Data"                     'E->H false "Values of requested Status Variables"
        1 11 "Status Variable Namelist Request"         'H->E true  "Query names and definitions of all SVIDs"
        1 12 "Status Variable Namelist Data"            'E->H false "List of SVID definitions"
        1 13 "Establish Communications Request"         'H->E true  "Initiate GEM communications handshake"
        1 14 "Establish Communications Acknowledge"     'E->H false "Comm ACK code (0 = Accepted, 1 = Denied)"
        1 15 "Request Offline"                          'H->E true  "Host requests equipment to go offline"
        1 16 "Offline Acknowledge"                      'E->H false "Offline transition acknowledge code"
        1 17 "Request Online"                           'H->E true  "Host requests equipment to go online"
        1 18 "Online Acknowledge"                       'E->H false "Online transition acknowledge code"

        2 13 "Equipment Constant Request"               'H->E true  "Query Equipment Constants (ECIDs)"
        2 14 "Equipment Constant Data"                  'E->H false "Values of requested Equipment Constants"
        2 15 "New Equipment Constant Send"              'H->E true  "Update Equipment Constant values"
        2 16 "New Equipment Constant Acknowledge"       'E->H false "Update status code"
        2 17 "Date and Time Request"                    'H->E true  "Request equipment internal clock time"
        2 18 "Date and Time Data"                       'E->H false "Current equipment timestamp YYYYMMDDHHMMSS"
        2 31 "Date and Time Set"                        'H->E true  "Synchronize equipment clock with host"
        2 32 "Date and Time Set Acknowledge"            'E->H false "Time synchronization status"
        2 33 "Define Report"                            'H->E true  "Configure event report structures (RPTIDs)"
        2 34 "Define Report Acknowledge"                'E->H false "Report definition acknowledge code"
        2 35 "Link Event Report"                        'H->E true  "Bind RPTIDs to Collection Events (CEIDs)"
        2 36 "Link Event Report Acknowledge"            'E->H false "Event link acknowledge code"
        2 37 "Enable/Disable Event Report"              'H->E true  "Enable or disable specific event reporting"
        2 38 "Enable/Disable Event Report Acknowledge"  'E->H false "Event enable acknowledge code"
        2 41 "Host Command Send"                        'H->E true  "Send remote command (START, STOP, PAUSE, ABORT)"
        2 42 "Host Command Acknowledge"                 'E->H false "Host command execution status (HCACK)"

        3 17 "Carrier Action Request"                   'H->E true  "Command carrier clamp, dock, unclamp, undock"
        3 18 "Carrier Action Acknowledge"               'E->H false "Carrier action status code (CAACK)"
        3 27 "Carrier Tag Read/Write"                   'H->E true  "Read or write RFID/barcode carrier tag data"
        3 28 "Carrier Tag Read/Write Acknowledge"       'E->H false "Carrier tag status code"

        5  1 "Alarm Report Send"                        'E->H true  "Notify host of equipment alarm state change"
        5  2 "Alarm Report Acknowledge"                 'H->E false "Host alarm receipt acknowledge"
        5  3 "Enable/Disable Alarm"                     'H->E true  "Enable or disable specific alarms (ALIDs)"
        5  4 "Enable/Disable Alarm Acknowledge"         'E->H false "Alarm enable status code"
        5  5 "List Alarms Request"                      'H->E true  "Query currently active alarm conditions"
        5  6 "List Alarms Data"                         'E->H false "List of active alarm identifiers and text"

        6 11 "Event Report Send"                        'E->H true  "Notify host of process collection event (CEID)"
        6 12 "Event Report Acknowledge"                 'H->E false "Host event receipt acknowledge"
        6 15 "Event Report Request"                     'H->E true  "Request current report values for a CEID"
        6 16 "Event Report Data"                        'E->H false "Report data payload"
        6 19 "Individual Report Request"                'H->E true  "Request specific report by RPTID"
        6 20 "Individual Report Data"                   'E->H false "Report data payload"

        7  1 "Process Program Load Inquire"             'H->E true  "Inquire if equipment has space for recipe"
        7  2 "Process Program Load Grant"               'E->H false "Recipe grant code (0 = Permission granted)"
        7  3 "Process Program Send"                     'H->E true  "Transmit recipe body (PPBODY) to equipment"
        7  4 "Process Program Acknowledge"              'E->H false "Recipe transmission acknowledge code"
        7  5 "Process Program Request"                  'H->E true  "Request recipe body from equipment"
        7  6 "Process Program Data"                     'E->H false "Transmitted recipe body"
        7 17 "Delete Process Program"                   'H->E true  "Delete recipe from equipment storage"
        7 18 "Delete Process Program Acknowledge"       'E->H false "Recipe deletion status code"
        7 19 "Current EPPD Request"                     'H->E true  "Query list of all recipes on equipment"
        7 20 "Current EPPD Data"                        'E->H false "List of recipe names (PPIDs)"

        9  1 "Unrecognized Device ID"                   'E->H false "Protocol error: unknown session device ID"
        9  3 "Unrecognized Stream Type"                 'E->H false "Protocol error: unknown stream number"
        9  5 "Unrecognized Function Type"               'E->H false "Protocol error: unknown function number"
        9  7 "Illegal Data"                             'E->H false "Protocol error: malformed SECS-II item body"
        9  9 "Transaction Timer Timeout"                'E->H false "Protocol error: T3 reply timeout expired"

       10  1 "Terminal Request"                         'E->H true  "Equipment operator entered message for host"
       10  2 "Terminal Request Acknowledge"             'H->E false "Host terminal message acknowledge"
       10  3 "Terminal Display Single"                  'H->E true  "Display single text line on equipment screen"
       10  4 "Terminal Display Single Acknowledge"      'E->H false "Display status code"
    ]

    ;; Find dictionary entry for a stream/function
    find-entry: function [
        stream   [integer!]
        function [integer!]
        return:  [block!]
    ][
        result: copy []
        foreach [s f name dir w desc] catalog [
            if all [s = stream f = function] [
                result: reduce [
                    'stream stream
                    'function function
                    'name name
                    'direction dir
                    'wait-bit w
                    'description desc
                ]
                break
            ]
        ]
        result
    ]
]

/**
 * Reticle Semiconductor Material Control System & SECS/GEM Engine
 * Module: C17 Hardware Fastpath Acceleration Library
 * Header: fastpath.h
 *
 * Implements high-throughput HSMS packet framing, zero-copy header packing,
 * Castagnoli CRC-32C verification, and 64-bit spatial bitboards for
 * monorail vehicle conflict-free reservation.
 */

#ifndef RETICLE_FASTPATH_H
#define RETICLE_FASTPATH_H

#include <stdint.h>
#include <stdbool.h>
#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

#define RETICLE_HSMS_HEADER_SIZE 10
#define RETICLE_MAX_TRACK_SEGMENTS 1024
#define RETICLE_MAX_TIME_HORIZON 128

/**
 * Standard SEMI E37 HSMS Header (10 bytes on wire, big-endian)
 */
#pragma pack(push, 1)
typedef struct {
    uint16_t session_id;     /* Device ID or Session ID */
    uint8_t  stream;         /* Stream number: bit 7 is Wait-bit */
    uint8_t  function;       /* Function number */
    uint8_t  p_type;         /* Presentation Type (0 = SECS-II) */
    uint8_t  s_type;         /* Session Type (0 = Data, 1 = Select.req, etc) */
    uint32_t system_bytes;   /* Unique transaction identifier */
} reticle_hsms_header_t;
#pragma pack(pop)

/**
 * Space-Time Reservation Bitboard Grid for AMHS Monorail Tracks.
 * Each track segment has a bitfield of reserved discrete time slots.
 */
typedef struct {
    uint64_t words[RETICLE_MAX_TRACK_SEGMENTS][RETICLE_MAX_TIME_HORIZON / 64];
    uint32_t active_segments;
    uint32_t horizon_slots;
} reticle_bitboard_grid_t;

/**
 * Packs native host header parameters into a 10-byte wire buffer.
 */
void reticle_hsms_pack_header(
    uint8_t* out_buf,
    uint16_t session_id,
    uint8_t stream,
    bool wait_bit,
    uint8_t function,
    uint8_t p_type,
    uint8_t s_type,
    uint32_t system_bytes
);

/**
 * Unpacks a 10-byte wire buffer into a typed header structure.
 * Returns true on success, false if buffer is null.
 */
bool reticle_hsms_unpack_header(
    const uint8_t* in_buf,
    reticle_hsms_header_t* out_header,
    bool* out_wait_bit
);

/**
 * Calculates Castagnoli CRC-32C over a memory buffer.
 */
uint32_t reticle_crc32c(const uint8_t* data, size_t len);

/**
 * Calculates CCITT CRC-16 over a memory buffer.
 */
uint16_t reticle_crc16(const uint8_t* data, size_t len);

/**
 * Initializes a space-time reservation bitboard grid.
 */
void reticle_grid_init(reticle_bitboard_grid_t* grid, uint32_t segments, uint32_t horizon);

/**
 * Checks whether a track segment is completely free over time interval [t_start, t_end).
 * Returns true if available, false if collision/conflict detected.
 */
bool reticle_grid_is_free(
    const reticle_bitboard_grid_t* grid,
    uint32_t segment_id,
    uint32_t t_start,
    uint32_t t_end
);

/**
 * Attempts to reserve a track segment over time interval [t_start, t_end).
 * Returns true if reservation succeeded, false if already occupied.
 */
bool reticle_grid_reserve(
    reticle_bitboard_grid_t* grid,
    uint32_t segment_id,
    uint32_t t_start,
    uint32_t t_end
);

/**
 * Releases a previously reserved track segment over [t_start, t_end).
 */
void reticle_grid_release(
    reticle_bitboard_grid_t* grid,
    uint32_t segment_id,
    uint32_t t_start,
    uint32_t t_end
);

/**
 * Scans a SECS-II item header to calculate format code and payload length.
 * Returns bytes consumed by the item header (2, 3, or 4).
 */
int reticle_secs2_scan_header(
    const uint8_t* buf,
    size_t buf_len,
    uint8_t* out_format_code,
    uint32_t* out_payload_len
);

#ifdef __cplusplus
}
#endif

#endif /* RETICLE_FASTPATH_H */

/**
 * Reticle Semiconductor Material Control System & SECS/GEM Engine
 * Module: C17 Hardware Fastpath Acceleration Library
 * Implementation: fastpath.c
 *
 * Implements high-throughput HSMS packet framing, zero-copy header packing,
 * Castagnoli CRC-32C verification, and 64-bit spatial bitboards for
 * monorail vehicle conflict-free reservation.
 */

#include "reticle/fastpath.h"
#include <string.h>

#define CRC16_POLY 0x1021
#define CRC32C_POLY 0x82F63B78

void reticle_hsms_pack_header(
    uint8_t* out_buf,
    uint16_t session_id,
    uint8_t stream,
    bool wait_bit,
    uint8_t function,
    uint8_t p_type,
    uint8_t s_type,
    uint32_t system_bytes
) {
    if (!out_buf) return;

    /* Session ID (2 bytes, big-endian) */
    out_buf[0] = (uint8_t)((session_id >> 8) & 0xFF);
    out_buf[1] = (uint8_t)(session_id & 0xFF);

    /* Stream byte: bit 7 is W-bit */
    out_buf[2] = (uint8_t)((stream & 0x7F) | (wait_bit ? 0x80 : 0x00));

    /* Function byte */
    out_buf[3] = function;

    /* P-Type (Presentation type, 0 = SECS-II) */
    out_buf[4] = p_type;

    /* S-Type (Session message subtype) */
    out_buf[5] = s_type;

    /* System Bytes / Transaction ID (4 bytes, big-endian) */
    out_buf[6] = (uint8_t)((system_bytes >> 24) & 0xFF);
    out_buf[7] = (uint8_t)((system_bytes >> 16) & 0xFF);
    out_buf[8] = (uint8_t)((system_bytes >> 8) & 0xFF);
    out_buf[9] = (uint8_t)(system_bytes & 0xFF);
}

bool reticle_hsms_unpack_header(
    const uint8_t* in_buf,
    reticle_hsms_header_t* out_header,
    bool* out_wait_bit
) {
    if (!in_buf || !out_header) return false;

    uint16_t sid = ((uint16_t)in_buf[0] << 8) | (uint16_t)in_buf[1];
    uint8_t raw_stream = in_buf[2];
    bool w_bit = (raw_stream & 0x80) != 0;
    uint8_t stream = raw_stream & 0x7F;
    uint8_t function = in_buf[3];
    uint8_t p_type = in_buf[4];
    uint8_t s_type = in_buf[5];
    uint32_t sys_id = ((uint32_t)in_buf[6] << 24) |
                      ((uint32_t)in_buf[7] << 16) |
                      ((uint32_t)in_buf[8] << 8)  |
                      (uint32_t)in_buf[9];

    out_header->session_id = sid;
    out_header->stream = stream;
    out_header->function = function;
    out_header->p_type = p_type;
    out_header->s_type = s_type;
    out_header->system_bytes = sys_id;

    if (out_wait_bit) {
        *out_wait_bit = w_bit;
    }
    return true;
}

uint32_t reticle_crc32c(const uint8_t* data, size_t len) {
    if (!data || len == 0) return 0;

    uint32_t crc = 0xFFFFFFFF;
    for (size_t i = 0; i < len; ++i) {
        crc ^= (uint32_t)data[i];
        for (int b = 0; b < 8; ++b) {
            uint32_t mask = -(crc & 1);
            crc = (crc >> 1) ^ (CRC32C_POLY & mask);
        }
    }
    return crc ^ 0xFFFFFFFF;
}

uint16_t reticle_crc16(const uint8_t* data, size_t len) {
    if (!data || len == 0) return 0;

    uint16_t crc = 0xFFFF;
    for (size_t i = 0; i < len; ++i) {
        crc ^= ((uint16_t)data[i] << 8);
        for (int b = 0; b < 8; ++b) {
            if (crc & 0x8000) {
                crc = ((crc << 1) ^ CRC16_POLY) & 0xFFFF;
            } else {
                crc = (crc << 1) & 0xFFFF;
            }
        }
    }
    return crc;
}

void reticle_grid_init(reticle_bitboard_grid_t* grid, uint32_t segments, uint32_t horizon) {
    if (!grid) return;
    if (segments > RETICLE_MAX_TRACK_SEGMENTS) segments = RETICLE_MAX_TRACK_SEGMENTS;
    if (horizon > RETICLE_MAX_TIME_HORIZON) horizon = RETICLE_MAX_TIME_HORIZON;

    grid->active_segments = segments;
    grid->horizon_slots = horizon;
    memset(grid->words, 0, sizeof(grid->words));
}

bool reticle_grid_is_free(
    const reticle_bitboard_grid_t* grid,
    uint32_t segment_id,
    uint32_t t_start,
    uint32_t t_end
) {
    if (!grid || segment_id >= grid->active_segments) return false;
    if (t_start >= t_end || t_end > grid->horizon_slots) return false;

    for (uint32_t t = t_start; t < t_end; ++t) {
        uint32_t word_idx = t / 64;
        uint32_t bit_idx = t % 64;
        uint64_t mask = (uint64_t)1 << bit_idx;

        if (grid->words[segment_id][word_idx] & mask) {
            return false; /* Collision detected */
        }
    }
    return true;
}

bool reticle_grid_reserve(
    reticle_bitboard_grid_t* grid,
    uint32_t segment_id,
    uint32_t t_start,
    uint32_t t_end
) {
    if (!reticle_grid_is_free(grid, segment_id, t_start, t_end)) {
        return false;
    }

    for (uint32_t t = t_start; t < t_end; ++t) {
        uint32_t word_idx = t / 64;
        uint32_t bit_idx = t % 64;
        uint64_t mask = (uint64_t)1 << bit_idx;
        grid->words[segment_id][word_idx] |= mask;
    }
    return true;
}

void reticle_grid_release(
    reticle_bitboard_grid_t* grid,
    uint32_t segment_id,
    uint32_t t_start,
    uint32_t t_end
) {
    if (!grid || segment_id >= grid->active_segments) return;
    if (t_start >= t_end || t_end > grid->horizon_slots) return;

    for (uint32_t t = t_start; t < t_end; ++t) {
        uint32_t word_idx = t / 64;
        uint32_t bit_idx = t % 64;
        uint64_t mask = ~((uint64_t)1 << bit_idx);
        grid->words[segment_id][word_idx] &= mask;
    }
}

int reticle_secs2_scan_header(
    const uint8_t* buf,
    size_t buf_len,
    uint8_t* out_format_code,
    uint32_t* out_payload_len
) {
    if (!buf || buf_len < 2) return -1;

    uint8_t fmt_byte = buf[0];
    uint8_t fmt_code = (fmt_byte >> 2) & 0x3F;
    uint8_t len_bytes = fmt_byte & 0x03;

    if (len_bytes == 0 || (size_t)(1 + len_bytes) > buf_len) {
        return -1;
    }

    uint32_t length = 0;
    for (uint8_t i = 0; i < len_bytes; ++i) {
        length = (length << 8) | (uint32_t)buf[1 + i];
    }

    if (out_format_code) *out_format_code = fmt_code;
    if (out_payload_len) *out_payload_len = length;

    return 1 + len_bytes;
}

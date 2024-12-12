/**
 * Reticle Semiconductor Material Control System & SECS/GEM Engine
 * Module: C17 Fastpath Test Suite
 * File: test_fastpath.c
 */

#include "reticle/fastpath.h"
#include <stdio.h>
#include <stdlib.h>
#include <assert.h>
#include <string.h>

static void test_hsms_pack_unpack(void) {
    uint8_t buffer[RETICLE_HSMS_HEADER_SIZE];
    uint16_t session = 1001;
    uint8_t stream = 1;
    bool w_bit = true;
    uint8_t function = 13;
    uint8_t p_type = 0;
    uint8_t s_type = 0;
    uint32_t system_bytes = 0xDEADBEEF;

    reticle_hsms_pack_header(buffer, session, stream, w_bit, function, p_type, s_type, system_bytes);

    reticle_hsms_header_t unpacked;
    bool parsed_w_bit = false;
    bool ok = reticle_hsms_unpack_header(buffer, &unpacked, &parsed_w_bit);

    assert(ok == true);
    assert(unpacked.session_id == 1001);
    assert(unpacked.stream == 1);
    assert(parsed_w_bit == true);
    assert(unpacked.function == 13);
    assert(unpacked.p_type == 0);
    assert(unpacked.s_type == 0);
    assert(unpacked.system_bytes == 0xDEADBEEF);
    printf("PASS: test_hsms_pack_unpack\n");
}

static void test_crc_calculations(void) {
    const char* sample = "123456789";
    uint32_t crc32c = reticle_crc32c((const uint8_t*)sample, strlen(sample));
    assert(crc32c == 0xE3069283);

    uint16_t crc16 = reticle_crc16((const uint8_t*)sample, strlen(sample));
    assert(crc16 == 0x29B1);

    printf("PASS: test_crc_calculations\n");
}

static void test_bitboard_reservations(void) {
    reticle_bitboard_grid_t grid;
    reticle_grid_init(&grid, 10, 64);

    assert(reticle_grid_is_free(&grid, 0, 0, 10) == true);
    assert(reticle_grid_reserve(&grid, 0, 0, 10) == true);
    assert(reticle_grid_is_free(&grid, 0, 5, 15) == false);
    assert(reticle_grid_reserve(&grid, 0, 5, 15) == false);

    assert(reticle_grid_is_free(&grid, 0, 10, 20) == true);
    assert(reticle_grid_reserve(&grid, 0, 10, 20) == true);

    reticle_grid_release(&grid, 0, 0, 10);
    assert(reticle_grid_is_free(&grid, 0, 0, 5) == true);

    printf("PASS: test_bitboard_reservations\n");
}

static void test_secs2_scan_header(void) {
    /* 1 length byte: format ASCII (16 = 010000b -> shifted << 2 | 1 = 65) */
    uint8_t buf1[] = {65, 5, 'H', 'E', 'L', 'L', 'O'};
    uint8_t fmt = 0;
    uint32_t len = 0;
    int bytes = reticle_secs2_scan_header(buf1, sizeof(buf1), &fmt, &len);

    assert(bytes == 2);
    assert(fmt == 16);
    assert(len == 5);
    printf("PASS: test_secs2_scan_header\n");
}

int main(void) {
    printf("=== Reticle C17 Fastpath Unit Verification ===\n");
    test_hsms_pack_unpack();
    test_crc_calculations();
    test_bitboard_reservations();
    test_secs2_scan_header();
    printf("All C17 fastpath tests successfully passed.\n");
    return 0;
}

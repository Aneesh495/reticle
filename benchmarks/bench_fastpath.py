"""
Benchmark: Measures C17 fastpath latency, CRC-32C throughput, and bitboard queries.
"""

from __future__ import annotations

import ctypes
import os
import sys
import time

repo_root = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
dylib_path = os.path.join(repo_root, "lib", "libreticle_fastpath.dylib")

if not os.path.exists(dylib_path):
    dylib_path = os.path.join(repo_root, "lib", "libreticle_fastpath.so")


def run_benchmark() -> None:
    print("=== Reticle C17 Fastpath Throughput & Latency Benchmark ===")
    if not os.path.exists(dylib_path):
        print(f"Fastpath shared library not found at {dylib_path}. Run 'make' first.")
        return

    c_lib = ctypes.CDLL(dylib_path)

    # Benchmark 1: CRC-32C throughput
    c_crc32c = c_lib.reticle_crc32c
    c_crc32c.argtypes = [ctypes.c_char_p, ctypes.c_size_t]
    c_crc32c.restype = ctypes.c_uint32

    payload = b"X" * 1024 * 1024  # 1 MB buffer
    iterations = 200

    start = time.perf_counter()
    for _ in range(iterations):
        c_crc32c(payload, len(payload))
    elapsed = time.perf_counter() - start

    mb_total = (len(payload) * iterations) / (1024 * 1024)
    throughput_mb_s = mb_total / elapsed
    print(f"CRC-32C Throughput: {throughput_mb_s:,.1f} MB/s ({iterations} iterations in {elapsed:.3f}s)")

    # Benchmark 2: HSMS Header Pack Latency
    c_pack = c_lib.reticle_hsms_pack_header
    c_pack.argtypes = [
        ctypes.POINTER(ctypes.c_uint8),
        ctypes.c_uint16,
        ctypes.c_uint8,
        ctypes.c_bool,
        ctypes.c_uint8,
        ctypes.c_uint8,
        ctypes.c_uint8,
        ctypes.c_uint32,
    ]

    out_buf = (ctypes.c_uint8 * 10)()
    pack_iters = 500000

    start_pack = time.perf_counter()
    for i in range(pack_iters):
        c_pack(out_buf, 1001, 1, True, 13, 0, 0, i)
    elapsed_pack = time.perf_counter() - start_pack

    packs_per_sec = pack_iters / elapsed_pack
    latency_ns = (elapsed_pack / pack_iters) * 1e9
    print(f"HSMS Header Packing: {packs_per_sec:,.0f} ops/sec (average latency: {latency_ns:.1f} ns/op)")


if __name__ == "__main__":
    run_benchmark()

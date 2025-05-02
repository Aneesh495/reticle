"""
Benchmark: Measures SEMI E5 SECS-II item encoding and decoding throughput.
"""

from __future__ import annotations

import os
import sys
import time

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "python")))

from reticle.secs import encode_item, decode_item


def run_benchmark() -> None:
    print("=== Reticle SEMI E5 SECS-II Message Throughput Benchmark ===")

    sample_msg = (
        "L",
        [
            ("A", "MDLN_IMMERSION_SCANNER_01"),
            ("A", "REV_4.2.0"),
            ("U4", 98500),
            ("F4", 23.45),
            ("BOOLEAN", True),
            (
                "L",
                [
                    ("A", "CHAMBER_A"),
                    ("U2", 15),
                ],
            ),
        ],
    )

    encoded = encode_item(sample_msg)
    iterations = 100000

    # Benchmark Encoding Throughput
    start_enc = time.perf_counter()
    for _ in range(iterations):
        encode_item(sample_msg)
    elapsed_enc = time.perf_counter() - start_enc
    enc_per_sec = iterations / elapsed_enc
    print(f"SECS-II Item Encoding: {enc_per_sec:,.0f} messages/sec ({iterations} iterations in {elapsed_enc:.3f}s)")

    # Benchmark Decoding Throughput
    start_dec = time.perf_counter()
    for _ in range(iterations):
        decode_item(encoded, 0)
    elapsed_dec = time.perf_counter() - start_dec
    dec_per_sec = iterations / elapsed_dec
    print(f"SECS-II Item Decoding: {dec_per_sec:,.0f} messages/sec ({iterations} iterations in {elapsed_dec:.3f}s)")


if __name__ == "__main__":
    run_benchmark()

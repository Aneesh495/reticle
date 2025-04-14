"""
Unit tests for SEMI E5 SECS-II item encoding, decoding, and SML syntax.
"""

import unittest
import sys
import os

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "python")))

from reticle.secs import encode_item, decode_item, format_sml


class TestSECSMessages(unittest.TestCase):
    def test_ascii_roundtrip(self) -> None:
        item = ("A", "STEPPER_MODEL_X1")
        encoded = encode_item(item)
        decoded, offset = decode_item(encoded, 0)
        self.assertEqual(decoded[0], "A")
        self.assertEqual(decoded[1], "STEPPER_MODEL_X1")
        self.assertEqual(offset, len(encoded))

    def test_numeric_roundtrip(self) -> None:
        # U4 unsigned integer
        item_u4 = ("U4", 12345678)
        enc_u4 = encode_item(item_u4)
        dec_u4, _ = decode_item(enc_u4, 0)
        self.assertEqual(dec_u4[0], "U4")
        self.assertEqual(dec_u4[1], 12345678)

        # I2 signed integer
        item_i2 = ("I2", -1024)
        enc_i2 = encode_item(item_i2)
        dec_i2, _ = decode_item(enc_i2, 0)
        self.assertEqual(dec_i2[0], "I2")
        self.assertEqual(dec_i2[1], -1024)

        # F4 float
        item_f4 = ("F4", 23.5)
        enc_f4 = encode_item(item_f4)
        dec_f4, _ = decode_item(enc_f4, 0)
        self.assertEqual(dec_f4[0], "F4")
        self.assertAlmostEqual(dec_f4[1], 23.5, places=3)

    def test_boolean_and_binary(self) -> None:
        item_bool = ("BOOLEAN", True)
        enc_bool = encode_item(item_bool)
        dec_bool, _ = decode_item(enc_bool, 0)
        self.assertEqual(dec_bool[1], True)

        item_bin = ("B", b"\x00\xFF\x5A\xA5")
        enc_bin = encode_item(item_bin)
        dec_bin, _ = decode_item(enc_bin, 0)
        self.assertEqual(dec_bin[1], b"\x00\xFF\x5A\xA5")

    def test_nested_list_roundtrip(self) -> None:
        nested = (
            "L",
            [
                ("A", "MDLN_01"),
                ("U2", 400),
                (
                    "L",
                    [
                        ("A", "SUB_ITEM"),
                        ("BOOLEAN", False),
                    ],
                ),
            ],
        )
        encoded = encode_item(nested)
        decoded, _ = decode_item(encoded, 0)
        self.assertEqual(decoded[0], "L")
        self.assertEqual(len(decoded[1]), 3)
        self.assertEqual(decoded[1][0], ("A", "MDLN_01"))
        self.assertEqual(decoded[1][1], ("U2", 400))
        self.assertEqual(len(decoded[1][2][1]), 2)

    def test_sml_formatting(self) -> None:
        sample_item = (
            "L",
            [
                ("A", "RETICLE_SCANNER"),
                ("U4", 100),
            ],
        )
        sml = format_sml(stream=1, function=13, wait_bit=True, root_item=sample_item)
        self.assertIn("S1F13 W", sml)
        self.assertIn("<L [2]", sml)
        self.assertIn('<A "RETICLE_SCANNER">', sml)
        self.assertIn("<U4 100>", sml)
        self.assertTrue(sml.strip().endswith("."))


if __name__ == "__main__":
    unittest.main()

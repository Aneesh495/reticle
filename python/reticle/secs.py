"""
Reticle SEMI E5 SECS-II Binary Encoder, Decoder, and SML Parser.

Implements recursive encoding and decoding of typed SECS-II items and
formatting to and from SECS Message Language (SML) text syntax.
"""

from __future__ import annotations

import re
import struct
from typing import Any, List, Tuple, Union

# Format codes (upper 6 bits)
FMT_LIST = 0
FMT_BINARY = 8
FMT_BOOLEAN = 9
FMT_ASCII = 16
FMT_JIS8 = 17
FMT_I8 = 24
FMT_I1 = 25
FMT_I2 = 26
FMT_I4 = 28
FMT_F8 = 32
FMT_F4 = 33
FMT_U8 = 40
FMT_U1 = 41
FMT_U2 = 42
FMT_U4 = 44


def encode_item_header(fmt_code: int, byte_count: int) -> bytes:
    """Generates the 2, 3, or 4 byte SECS-II item header."""
    if byte_count <= 255:
        hdr_byte = (fmt_code << 2) | 1
        return bytes([hdr_byte, byte_count])
    elif byte_count <= 65535:
        hdr_byte = (fmt_code << 2) | 2
        return bytes([hdr_byte, (byte_count >> 8) & 0xFF, byte_count & 0xFF])
    else:
        hdr_byte = (fmt_code << 2) | 3
        return bytes([
            hdr_byte,
            (byte_count >> 16) & 0xFF,
            (byte_count >> 8) & 0xFF,
            byte_count & 0xFF,
        ])


def encode_item(item: Tuple[str, Any]) -> bytes:
    """Recursively serializes a typed item tuple ('TYPE', value) into SECS-II binary bytes."""
    tag, val = item
    tag_upper = tag.upper()

    if tag_upper in ("L", "LIST"):
        children = val if isinstance(val, (list, tuple)) else []
        elem_count = len(children)
        hdr = encode_item_header(FMT_LIST, elem_count)
        return hdr + b"".join(encode_item(c) for c in children)

    elif tag_upper in ("A", "ASCII"):
        str_bytes = val.encode("ascii", errors="replace") if isinstance(val, str) else bytes(val)
        hdr = encode_item_header(FMT_ASCII, len(str_bytes))
        return hdr + str_bytes

    elif tag_upper in ("B", "BIN", "BINARY"):
        bin_data = val if isinstance(val, (bytes, bytearray)) else bytes(val)
        hdr = encode_item_header(FMT_BINARY, len(bin_data))
        return hdr + bin_data

    elif tag_upper in ("BOOL", "BOOLEAN"):
        b_val = 1 if val else 0
        hdr = encode_item_header(FMT_BOOLEAN, 1)
        return hdr + bytes([b_val])

    elif tag_upper == "U1":
        val_int = int(val) & 0xFF
        hdr = encode_item_header(FMT_U1, 1)
        return hdr + bytes([val_int])

    elif tag_upper == "U2":
        val_int = int(val) & 0xFFFF
        hdr = encode_item_header(FMT_U2, 2)
        return hdr + struct.pack(">H", val_int)

    elif tag_upper == "U4":
        val_int = int(val) & 0xFFFFFFFF
        hdr = encode_item_header(FMT_U4, 4)
        return hdr + struct.pack(">I", val_int)

    elif tag_upper == "I1":
        hdr = encode_item_header(FMT_I1, 1)
        return hdr + struct.pack(">b", int(val))

    elif tag_upper == "I2":
        hdr = encode_item_header(FMT_I2, 2)
        return hdr + struct.pack(">h", int(val))

    elif tag_upper == "I4":
        hdr = encode_item_header(FMT_I4, 4)
        return hdr + struct.pack(">i", int(val))

    elif tag_upper == "F4":
        hdr = encode_item_header(FMT_F4, 4)
        return hdr + struct.pack(">f", float(val))

    elif tag_upper == "F8":
        hdr = encode_item_header(FMT_F8, 8)
        return hdr + struct.pack(">d", float(val))

    else:
        raise ValueError(f"Unsupported SECS-II item format tag: {tag}")


def decode_item(buf: bytes, offset: int = 0) -> Tuple[Tuple[str, Any], int]:
    """Recursively deserializes a single SECS-II item from a byte buffer at offset."""
    if offset >= len(buf):
        raise ValueError(f"Buffer underflow at offset {offset}")

    fmt_byte = buf[offset]
    offset += 1

    fmt_code = (fmt_byte >> 2) & 0x3F
    len_bytes_count = fmt_byte & 0x03

    if len_bytes_count == 0:
        raise ValueError(f"Invalid SECS-II length byte count: 0 at offset {offset}")

    if offset + len_bytes_count > len(buf):
        raise ValueError("Buffer underflow reading item length")

    payload_len = 0
    for _ in range(len_bytes_count):
        payload_len = (payload_len << 8) | buf[offset]
        offset += 1

    if fmt_code == FMT_LIST:
        items = []
        for _ in range(payload_len):
            child_item, offset = decode_item(buf, offset)
            items.append(child_item)
        return ("L", items), offset

    elif fmt_code == FMT_ASCII:
        if offset + payload_len > len(buf):
            raise ValueError("Buffer underflow reading ASCII item payload")
        s = buf[offset : offset + payload_len].decode("ascii", errors="replace")
        return ("A", s), offset + payload_len

    elif fmt_code == FMT_BINARY:
        if offset + payload_len > len(buf):
            raise ValueError("Buffer underflow reading Binary item payload")
        data = buf[offset : offset + payload_len]
        return ("B", data), offset + payload_len

    elif fmt_code == FMT_BOOLEAN:
        b_val = buf[offset] != 0
        return ("BOOLEAN", b_val), offset + 1

    elif fmt_code == FMT_U1:
        u_val = buf[offset]
        return ("U1", u_val), offset + 1

    elif fmt_code == FMT_U2:
        (u_val,) = struct.unpack(">H", buf[offset : offset + 2])
        return ("U2", u_val), offset + 2

    elif fmt_code == FMT_U4:
        (u_val,) = struct.unpack(">I", buf[offset : offset + 4])
        return ("U4", u_val), offset + 4

    elif fmt_code == FMT_I1:
        (i_val,) = struct.unpack(">b", buf[offset : offset + 1])
        return ("I1", i_val), offset + 1

    elif fmt_code == FMT_I2:
        (i_val,) = struct.unpack(">h", buf[offset : offset + 2])
        return ("I2", i_val), offset + 2

    elif fmt_code == FMT_I4:
        (i_val,) = struct.unpack(">i", buf[offset : offset + 4])
        return ("I4", i_val), offset + 4

    elif fmt_code == FMT_F4:
        (f_val,) = struct.unpack(">f", buf[offset : offset + 4])
        return ("F4", f_val), offset + 4

    elif fmt_code == FMT_F8:
        (f_val,) = struct.unpack(">d", buf[offset : offset + 8])
        return ("F8", f_val), offset + 8

    else:
        raw_slice = buf[offset : offset + payload_len]
        return ("RAW", raw_slice), offset + payload_len


def format_sml(stream: int, function: int, wait_bit: bool, root_item: Optional[Tuple[str, Any]] = None) -> str:
    """Formats a message transaction into clean SML text with standard indentation."""
    w_str = " W" if wait_bit else ""
    lines = [f"S{stream}F{function}{w_str}"]

    def _format(item: Tuple[str, Any], indent: int) -> None:
        tag, val = item
        prefix = "    " * indent
        if tag.upper() in ("L", "LIST"):
            lines.append(f"{prefix}<L [{len(val)}]")
            for child in val:
                _format(child, indent + 1)
            lines.append(f"{prefix}>")
        elif tag.upper() in ("A", "ASCII"):
            lines.append(f'{prefix}<A "{val}">')
        elif tag.upper() in ("B", "BIN"):
            hex_str = " ".join(f"{b:02X}" for b in val)
            lines.append(f"{prefix}<B {hex_str}>")
        elif tag.upper() in ("BOOL", "BOOLEAN"):
            b_str = "T" if val else "F"
            lines.append(f"{prefix}<BOOLEAN {b_str}>")
        else:
            lines.append(f"{prefix}<{tag} {val}>")

    if root_item:
        _format(root_item, 0)
    lines.append(".")
    return "\n".join(lines)

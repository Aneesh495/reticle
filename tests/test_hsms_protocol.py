"""
Unit tests for SEMI E37 HSMS protocol framing, headers, and sessions.
"""

import unittest
import sys
import os

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "python")))

from reticle.hsms import HSMSHeader, HSMSMessage, HSMSSession, SType, SessionState


class TestHSMSProtocol(unittest.TestCase):
    def test_header_pack_unpack(self) -> None:
        hdr = HSMSHeader(
            session_id=1001,
            stream=1,
            wait_bit=True,
            function=13,
            p_type=0,
            s_type=SType.DATA,
            system_bytes=0x12345678,
        )
        packed = hdr.pack()
        self.assertEqual(len(packed), 10)

        unpacked = HSMSHeader.unpack(packed)
        self.assertEqual(unpacked.session_id, 1001)
        self.assertEqual(unpacked.stream, 1)
        self.assertTrue(unpacked.wait_bit)
        self.assertEqual(unpacked.function, 13)
        self.assertEqual(unpacked.p_type, 0)
        self.assertEqual(unpacked.s_type, SType.DATA)
        self.assertEqual(unpacked.system_bytes, 0x12345678)

    def test_message_wire_framing(self) -> None:
        hdr = HSMSHeader(
            session_id=2000,
            stream=2,
            wait_bit=False,
            function=42,
            p_type=0,
            s_type=SType.DATA,
            system_bytes=999,
        )
        msg = HSMSMessage(header=hdr, body=b"TESTPAYLOAD")
        wire = msg.to_wire()
        # 4 bytes length prefix + 10 bytes header + 11 bytes body = 25 bytes
        self.assertEqual(len(wire), 25)

    def test_session_lifecycle(self) -> None:
        session = HSMSSession(device_id=1000, is_passive=True)
        self.assertEqual(session.state, SessionState.NOT_CONNECTED)

        # Inbound Select.req
        select_hdr = HSMSHeader(
            session_id=1000,
            stream=0,
            wait_bit=False,
            function=0,
            p_type=0,
            s_type=SType.SELECT_REQ,
            system_bytes=101,
        )
        req_msg = HSMSMessage(header=select_hdr)
        rsp_msg = session.process_control(req_msg)

        self.assertIsNotNone(rsp_msg)
        self.assertEqual(rsp_msg.header.s_type, SType.SELECT_RSP)
        self.assertEqual(rsp_msg.header.system_bytes, 101)
        self.assertEqual(session.state, SessionState.SELECTED)

        # Inbound Linktest.req
        link_hdr = HSMSHeader(
            session_id=1000,
            stream=0,
            wait_bit=False,
            function=0,
            p_type=0,
            s_type=SType.LINKTEST_REQ,
            system_bytes=202,
        )
        link_rsp = session.process_control(HSMSMessage(header=link_hdr))
        self.assertIsNotNone(link_rsp)
        self.assertEqual(link_rsp.header.s_type, SType.LINKTEST_RSP)
        self.assertEqual(link_rsp.header.system_bytes, 202)


if __name__ == "__main__":
    unittest.main()

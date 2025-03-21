"""
Reticle SEMI E37 / E37.1 HSMS-SS Protocol Implementation.

Provides asynchronous TCP framing, session state machines, 10-byte header packing,
and protocol watchdog timers for semiconductor equipment and host communications.
"""

from __future__ import annotations

import asyncio
import struct
import time
from dataclasses import dataclass
from enum import IntEnum
from typing import Callable, Dict, Optional, Tuple


class SType(IntEnum):
    DATA = 0
    SELECT_REQ = 1
    SELECT_RSP = 2
    DESELECT_REQ = 3
    DESELECT_RSP = 4
    LINKTEST_REQ = 5
    LINKTEST_RSP = 6
    REJECT_REQ = 7
    SEPARATE_REQ = 9


class SessionState(IntEnum):
    NOT_CONNECTED = 0
    NOT_SELECTED = 1
    SELECTED = 2


@dataclass
class HSMSHeader:
    session_id: int
    stream: int
    wait_bit: bool
    function: int
    p_type: int
    s_type: int
    system_bytes: int

    @classmethod
    def unpack(cls, buf: bytes) -> HSMSHeader:
        if len(buf) < 10:
            raise ValueError(f"HSMS header requires 10 bytes, received {len(buf)}")
        session_id, raw_stream, fn, p_type, s_type, sys_bytes = struct.unpack(">HBBBB I", buf[:10])
        w_bit = (raw_stream & 0x80) != 0
        stream = raw_stream & 0x7F
        return cls(
            session_id=session_id,
            stream=stream,
            wait_bit=w_bit,
            function=fn,
            p_type=p_type,
            s_type=s_type,
            system_bytes=sys_bytes,
        )

    def pack(self) -> bytes:
        st_byte = (self.stream & 0x7F) | (0x80 if self.wait_bit else 0x00)
        return struct.pack(
            ">HBBBB I",
            self.session_id,
            st_byte,
            self.function,
            self.p_type,
            self.s_type,
            self.system_bytes,
        )


@dataclass
class HSMSMessage:
    header: HSMSHeader
    body: bytes = b""

    def to_wire(self) -> bytes:
        hdr_bytes = self.header.pack()
        payload_len = len(hdr_bytes) + len(self.body)
        return struct.pack(">I", payload_len) + hdr_bytes + self.body


class HSMSSession:
    """Manages SEMI E37 session state machine and watchdog timers."""

    def __init__(
        self,
        device_id: int = 1000,
        is_passive: bool = True,
        t3: float = 45.0,
        t5: float = 10.0,
        t6: float = 5.0,
        t7: float = 10.0,
        t8: float = 5.0,
    ) -> None:
        self.device_id = device_id
        self.is_passive = is_passive
        self.t3 = t3
        self.t5 = t5
        self.t6 = t6
        self.t7 = t7
        self.t8 = t8

        self.state = SessionState.NOT_CONNECTED
        self.system_id_counter = 1000
        self.pending_replies: Dict[int, asyncio.Future[HSMSMessage]] = {}
        self._t7_task: Optional[asyncio.TimerHandle] = None

    def next_system_id(self) -> int:
        self.system_id_counter = (self.system_id_counter + 1) & 0xFFFFFFFF
        return self.system_id_counter

    def on_connected(self, loop: asyncio.AbstractEventLoop, on_t7_expired: Callable[[], None]) -> None:
        self.state = SessionState.NOT_SELECTED
        if self.is_passive:
            # Arm T7 timer: if Select.req is not received within T7, close socket
            self._t7_task = loop.call_later(self.t7, on_t7_expired)

    def on_disconnected(self) -> None:
        self.state = SessionState.NOT_CONNECTED
        if self._t7_task:
            self._t7_task.cancel()
            self._t7_task = None
        for fut in self.pending_replies.values():
            if not fut.done():
                fut.cancel()
        self.pending_replies.clear()

    def process_control(self, msg: HSMSMessage) -> Optional[HSMSMessage]:
        st = msg.header.s_type
        sys_id = msg.header.system_bytes

        if st == SType.SELECT_REQ:
            if self._t7_task:
                self._t7_task.cancel()
                self._t7_task = None
            self.state = SessionState.SELECTED
            rsp_hdr = HSMSHeader(
                session_id=self.device_id,
                stream=0,
                wait_bit=False,
                function=0,
                p_type=0,
                s_type=SType.SELECT_RSP,
                system_bytes=sys_id,
            )
            return HSMSMessage(header=rsp_hdr, body=b"")

        elif st == SType.SELECT_RSP:
            self.state = SessionState.SELECTED
            return None

        elif st == SType.DESELECT_REQ:
            self.state = SessionState.NOT_SELECTED
            rsp_hdr = HSMSHeader(
                session_id=self.device_id,
                stream=0,
                wait_bit=False,
                function=0,
                p_type=0,
                s_type=SType.DESELECT_RSP,
                system_bytes=sys_id,
            )
            return HSMSMessage(header=rsp_hdr, body=b"")

        elif st == SType.LINKTEST_REQ:
            rsp_hdr = HSMSHeader(
                session_id=self.device_id,
                stream=0,
                wait_bit=False,
                function=0,
                p_type=0,
                s_type=SType.LINKTEST_RSP,
                system_bytes=sys_id,
            )
            return HSMSMessage(header=rsp_hdr, body=b"")

        elif st == SType.SEPARATE_REQ:
            self.state = SessionState.NOT_CONNECTED
            return None

        return None

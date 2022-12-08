from __future__ import annotations

from enum import Enum
from typing import Callable

from .encoder import Codec, Message


class BusType(Enum):
    """An enum that indicates a type of bus. On most systems, there are
    normally two different kinds of buses running.
    """

    SESSION = 1  #: A bus for the current graphical user session.
    SYSTEM = 2  #: A persistent bus for the whole machine.


class Bus:
    """A bus is used to send and receive messages between D-Bus clients or services."""

    def __init_subclass__(cls, codec: type[Codec]) -> None:
        super().__init_subclass__()
        cls.codec = codec()

    def __init__(
        self,
        bus_address: str | None = None,
        bus_type: BusType = BusType.SYSTEM,
        negociate_unix_fd: bool = True,
    ) -> None:
        raise NotImplementedError

    async def connect(self) -> None:
        raise NotImplementedError

    def disconnect(self):
        """Disconnect the message bus by closing the underlying connection asynchronously.

        All pending  and future calls will error with a connection error.
        """
        raise NotImplementedError

    async def call(self, msg: Message) -> Message:
        raise NotImplementedError

    def add_message_handler(self, handler: Callable[[Message], Message | bool]) -> None:
        raise NotImplementedError

    def remove_message_handler(
        self, handler: Callable[[Message], Message | bool]
    ) -> None:
        raise NotImplementedError

from binascii import hexlify
from copy import deepcopy
from functools import reduce
from math import log
from operator import xor
from typing import Callable, List, Optional, Protocol
from functools import partial

from typing_extensions import Self

# The Keccak-f round constants.
ROUND_CONSTANTS = [
    0x0000000000000001,
    0x0000000000008082,
    0x800000000000808A,
    0x8000000080008000,
    0x000000000000808B,
    0x0000000080000001,
    0x8000000080008081,
    0x8000000000008009,
    0x000000000000008A,
    0x0000000000000088,
    0x0000000080008009,
    0x000000008000000A,
    0x000000008000808B,
    0x800000000000008B,
    0x8000000000008089,
    0x8000000000008003,
    0x8000000000008002,
    0x8000000000000080,
    0x000000000000800A,
    0x800000008000000A,
    0x8000000080008081,
    0x8000000000008080,
    0x0000000080000001,
    0x8000000080008008,
]

ROTATION_CONSTANTS = [
    [
        0,
        1,
        62,
        28,
        27,
    ],
    [
        36,
        44,
        6,
        55,
        20,
    ],
    [
        3,
        10,
        43,
        25,
        39,
    ],
    [
        41,
        45,
        15,
        21,
        8,
    ],
    [
        18,
        2,
        61,
        56,
        14,
    ],
]

MASKS = [(1 << i) - 1 for i in range(65)]


PaddingFn = Callable[[int, int], List[int]]
PermutationFn = Callable[["KeccakState"], None]


def bits2bytes(x: int) -> int:
    return (x + 7) // 8


def rol(value: int, left: int, bits: int) -> int:
    """
    Circularly rotate 'value' to the left,
    treating it as a quantity of the given size in bits.
    """
    top = value >> (bits - left)
    bot = (value & MASKS[bits - left]) << left
    return bot | top


def ror(value: int, right: int, bits: int) -> int:
    """
    Circularly rotate 'value' to the right,
    treating it as a quantity of the given size in bits.
    """
    top = value >> right
    bot = (value & MASKS[right]) << (bits - right)
    return bot | top


def multirate_padding(
    used_bytes: int, align_bytes: int, suffix: int = 0x01
) -> List[int]:
    """
    The Keccak padding function.
    """
    padlen = align_bytes - used_bytes
    if padlen == 0:
        padlen = align_bytes
    # note: padding done in 'internal bit ordering', wherein LSB is leftmost
    if padlen == 1:
        return [0x80 + suffix]
    else:
        return [suffix] + ([0x00] * (padlen - 2)) + [0x80]


def keccak_f(state: "KeccakState") -> None:
    """
    This is Keccak-f permutation.  It operates on and
    mutates the passed-in KeccakState.  It returns nothing.
    """
    __ROUND_CONSTANTS = [x % 2**state.lanew for x in ROUND_CONSTANTS]
    __ROTATION_CONSTANTS = [
        [x % state.lanew for x in row] for row in ROTATION_CONSTANTS
    ]
    __W, __H = state.W, state.H
    __RANGE_W, __RANGE_H = state.RANGE_W, state.RANGE_H
    __LANEW = state.lanew
    zero = state.zero

    def round(a: List[List[int]], rc: int) -> None:

        # theta
        c = [reduce(xor, a[x]) for x in __RANGE_W]
        d = [0] * __W
        for x in __RANGE_W:
            d[x] = c[(x - 1) % __W] ^ rol(c[(x + 1) % __W], 1, __LANEW)
            for y in __RANGE_H:
                a[x][y] ^= d[x]

        # rho and pi
        b = zero()
        for x in __RANGE_W:
            for y in __RANGE_H:
                b[y % __W][(2 * x + 3 * y) % __H] = rol(
                    a[x][y], __ROTATION_CONSTANTS[y][x], __LANEW
                )

        # chi
        for x in __RANGE_W:
            for y in __RANGE_H:
                a[x][y] = b[x][y] ^ (
                    (~b[(x + 1) % __W][y]) & b[(x + 2) % __W][y]
                )

        # iota
        a[0][0] ^= rc

    l_ = int(log(__LANEW, 2))
    nr = 12 + 2 * l_

    for ir in range(nr):
        round(state.s, __ROUND_CONSTANTS[ir])


class KeccakState:
    """
    A keccak state container.

    The state is stored as a 5x5 table of integers. Each integer represents
    a lane of the state (constant x, y coordinates).
    """

    W = 5
    H = 5

    RANGE_W = tuple(range(W))
    RANGE_H = tuple(range(H))

    @classmethod
    def zero(cls) -> List[List[int]]:
        """
        Returns an zero state table.
        """
        return [[0] * cls.W for _ in cls.RANGE_H]

    @staticmethod
    def lane2bytes(s: int, w: int) -> List[int]:
        """
        Converts the lane s to a sequence of byte values,
        assuming a lane is w bits.
        """
        return [(s >> b) & 0xFF for b in range(0, w, 8)]

    @staticmethod
    def bytes2lane(bb: List[int]) -> int:
        """
        Converts a sequence of byte values to a lane.
        """
        r = 0
        for b in reversed(bb):
            r = r << 8 | b
        return r

    @staticmethod
    def ilist2bytes(bb: List[int]) -> bytes:
        """
        Converts a sequence of byte values to a bytestring.
        #"""
        return bytes(bb)

    @staticmethod
    def bytes2ilist(ss: bytes) -> List[int]:
        """
        Converts a bytestring to a sequence of byte values.
        """
        return list(ss)

    def __init__(self, bitrate: int, b: int) -> None:
        self.bitrate = bitrate
        self.b = b

        # only byte-aligned
        assert self.bitrate % 8 == 0
        self.bitrate_bytes = bits2bytes(self.bitrate)

        assert self.b % (self.H * self.W) == 0
        self.lanew = self.b // (self.H * self.W)

        # size of a bit of state
        self.bitsize = self.lanew // 8

        self.s = self.zero()

    def __str__(self) -> str:
        """
        Formats the given state as hex, in natural byte order.
        """

        def fmt(x: int) -> str:
            return f"{x:0{2 * self.bitsize}x}"

        return "\n".join((" ".join(fmt(x) for x in row) for row in self.s))

    def absorb(self, bb: List[int]) -> None:
        """
        Mixes in the given bitrate-length string to the state.
        """
        assert len(bb) == self.bitrate_bytes

        bb += [0] * bits2bytes(self.b - self.bitrate)
        i = 0

        for y in self.RANGE_H:
            for x in self.RANGE_W:
                self.s[x][y] ^= self.bytes2lane(bb[i : i + self.bitsize])
                i += self.bitsize

    def squeeze(self) -> List[int]:
        """
        Returns the bitrate-length prefix of the state to be output.
        """
        return self.get_bytes()[: self.bitrate_bytes]

    def get_bytes(self) -> List[int]:
        """
        Convert whole state to a byte string.
        """
        out = [0] * bits2bytes(self.b)
        i = 0
        for y in self.RANGE_H:
            for x in self.RANGE_W:
                v = self.lane2bytes(self.s[x][y], self.lanew)
                out[i : i + self.bitsize] = v
                i += self.bitsize
        return out

    def set_bytes(self, bb: List[int]) -> None:
        """
        Set whole state from byte string, which is assumed
        to be the correct length.
        """
        i = 0
        for y in self.RANGE_H:
            for x in self.RANGE_W:
                self.s[x][y] = self.bytes2lane(bb[i : i + self.bitsize])
                i += self.bitsize


class KeccakSponge:
    def __init__(
        self, bitrate: int, width: int, padfn: PaddingFn, permfn: PermutationFn
    ) -> None:
        self.state = KeccakState(bitrate, width)
        self.padfn = padfn
        self.permfn = permfn
        self.buffer: List[int] = []

    def copy(self) -> Self:
        return deepcopy(self)

    def absorb_block(self, bb: List[int]) -> None:
        assert len(bb) == self.state.bitrate_bytes
        self.state.absorb(bb)
        self.permfn(self.state)

    def absorb(self, s: bytes) -> None:
        self.buffer += KeccakState.bytes2ilist(s)

        while len(self.buffer) >= self.state.bitrate_bytes:
            self.absorb_block(self.buffer[: self.state.bitrate_bytes])
            self.buffer = self.buffer[self.state.bitrate_bytes :]

    def absorb_final(self) -> None:
        padded = self.buffer + self.padfn(
            len(self.buffer), self.state.bitrate_bytes
        )
        self.absorb_block(padded)
        self.buffer = []

    def squeeze_once(self) -> List[int]:
        rc = self.state.squeeze()
        self.permfn(self.state)
        return rc

    def squeeze(self, length: int) -> List[int]:
        z = self.squeeze_once()
        while len(z) < length:
            z += self.squeeze_once()
        return z[:length]


class PresetKeccakHash(Protocol):
    def __call__(self, initial_input: Optional[bytes] = None) -> "KeccakHash":
        ...


class KeccakHash:
    """
    The Keccak hash function, with a hashlib-compatible interface.
    """

    def __init__(
        self,
        bitrate_bits: int,
        capacity_bits: int,
        output_bits: int,
        *,
        padfn: Optional[PaddingFn] = None,
    ) -> None:
        # our in-absorption sponge. this is never given padding
        if (w := bitrate_bits + capacity_bits) not in (
            v := (25, 50, 100, 200, 400, 800, 1600)
        ):
            raise ValueError(f"State width should be within {v}: got {w}.")
        self.sponge = KeccakSponge(
            bitrate_bits,
            bitrate_bits + capacity_bits,
            multirate_padding if padfn is None else padfn,
            keccak_f,
        )

        # hashlib interface members
        assert output_bits % 8 == 0
        self.digest_size = bits2bytes(output_bits)
        self.block_size = bits2bytes(bitrate_bits)

    def __repr__(self) -> str:
        inf = (
            self.sponge.state.bitrate,
            self.sponge.state.b - self.sponge.state.bitrate,
            self.digest_size * 8,
        )
        return "<KeccakHash with r=%d, c=%d, image=%d>" % inf

    def update(self, s: bytes) -> None:
        self.sponge.absorb(s)

    def digest(self) -> bytes:
        finalised = self.sponge.copy()
        finalised.absorb_final()
        digest = finalised.squeeze(self.digest_size)
        return KeccakState.ilist2bytes(digest)

    def hexdigest(self) -> bytes:
        return hexlify(self.digest())

    @classmethod
    def preset(
        cls,
        bitrate_bits: int,
        capacity_bits: int,
        output_bits: int,
        *,
        padfn: Optional[PaddingFn] = None,
    ) -> PresetKeccakHash:
        """
        Returns a factory function for the given bitrate,
        sponge capacity and output length.
        The function accepts an optional initial input, ala hashlib.
        """

        def create(initial_input: Optional[bytes] = None) -> Self:
            h = KeccakHash(
                bitrate_bits, capacity_bits, output_bits, padfn=padfn
            )
            if initial_input is not None:
                h.update(initial_input)
            return h

        return create

tmac_padding = partial(multirate_padding, suffix=0x04)
"""TropicSquare's custom padding function"""

ts_keccak = KeccakHash.preset(144, 256, 256, padfn=tmac_padding)

def tmac(key: bytes, data: bytes, nonce: bytes) -> bytes:
    """TMAC computation function"""
    return ts_keccak(
        nonce + bytes([len(key)]) + key + b"\x00\x00" + data
    ).digest()

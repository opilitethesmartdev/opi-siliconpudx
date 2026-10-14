# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, Timer


@cocotb.test()
async def test_interface(dut):
    """Smoke-test reset and the bidirectional-pin direction control."""

    clock = Clock(dut.clk, 20, unit="ns")
    cocotb.start_soon(clock.start())

    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 2)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 2)

    # ui_in[7:6] selects rw. The wrapper enables the bidirectional pins
    # for modes 01 and 11, and disables them for modes 00 and 10.
    for mode, expected_oe in (
        (0b00, 0x00),
        (0b01, 0xFF),
        (0b10, 0x00),
        (0b11, 0xFF),
    ):
        dut.ui_in.value = mode << 6
        await Timer(1, unit="ns")
        assert int(dut.uio_oe.value) == expected_oe, (
            f"rw mode {mode:02b}: expected uio_oe=0x{expected_oe:02x}, "
            f"got 0x{int(dut.uio_oe.value):02x}"
        )

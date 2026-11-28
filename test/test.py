# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, Timer


@cocotb.test()
async def test_interface(dut):

    clock = Clock(dut.clk, 40, unit="ns")
    cocotb.start_soon(clock.start())

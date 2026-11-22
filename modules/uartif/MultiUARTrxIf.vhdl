----------------------------------------------------------------------------
-- Project		:	OPI-siliconPUdx
-- Authors		:	opilitethesmartdev
-- Description	:	Multi-byte UART Receiver Interface
----------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.uart_pkg.all;
use work.core_pkg.all;
use work.register_pkg.all;
use work.instruction_pkg.all;

entity MultiUARTrxIf is
    port (
        clk : in std_ulogic;
        rst : in std_ulogic;
    );
end entity MultiUARTrxIf;

architecture rtl of MultiUARTrxIf is
begin
end architecture rtl;
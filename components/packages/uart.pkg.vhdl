----------------------------------------------------------------------------
-- Project		:	OPI-siliconPUdx
-- Authors		:	opilitethesmartdev
-- Description	:	UART utils package
----------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package uart_pkg is
    constant UWW : natural := 8;

    type uart_t is array(natural range<>) of std_ulogic_vector(UWW - 1 downto 0);
end package uart_pkg;
----------------------------------------------------------------------------
-- Project		:	OPI-siliconPUdx
-- Authors		:	opilitethesmartdev
-- Description	:	Registers utils package
----------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.core_pkg.all;

package register_pkg is
    constant REGD : natural := 5;
    constant MMIOD : natural := 3;

    type reg_array_t is array(natural range<>) of std_ulogic_vector(WORDWIDTH - 1 downto 0);
end package register_pkg;
----------------------------------------------------------------------------
-- Project		:	OPI-siliconPUdx
-- Authors		:	opilitethesmartdev
-- Description	:	Core utils package
----------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package core_pkg is
    constant WORDWIDTH : natural := 8;

    type clk_rec_t is record
        o    : std_ulogic;
        en   : std_ulogic;
        advp : std_ulogic;
        advn : std_ulogic;
    end record;
end package core_pkg;
----------------------------------------------------------------------------
-- Project		:	OPI-siliconPUdx
-- Authors		:	opilitethesmartdev
-- Description	:	Core utils package
----------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package core_pkg is
    -- Constants
    constant WORDWIDTH  : natural := 8;  

    type clk_record_t is record
        clk   : std_ulogic;
        clk_s : std_ulogic; 
        sadvp : std_ulogic;
        sadvn : std_ulogic;
        clkon : std_ulogic;
    end record;
end package core_pkg;
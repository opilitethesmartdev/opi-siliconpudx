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
    -- Constants
    constant CFGWIDTH  : natural := 2;  
    constant REGWIDTH  : natural := CFGWIDTH + WORDWIDTH;  

    constant REGDEPTH : natural := 5;
    
    constant REGNULL  : std_ulogic_vector(REGWIDTH - 1 downto 0) := (others => '0');  

    -- Register array
    type reg_array_t is array(0 to REGDEPTH**2-1) of std_ulogic_vector(REGWIDTH - 1 downto 0);
end package register_pkg;
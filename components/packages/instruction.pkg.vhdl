----------------------------------------------------------------------------
-- Project		:	OPI-siliconPUdx
-- Authors		:	opilitethesmartdev
-- Description	:	Instruction utils package
----------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.MATH_REAL.all;

use work.core_pkg.all;

package instruction_pkg is    
    constant IPTRW  : natural := 2;  
    constant ICMDW  : natural := 6;    
    constant PARAMW : natural := WORDWIDTH; 
    constant INSTW  : natural := IPTRW + ICMDW + PARAMW;

    constant INSTD : natural := WORDWIDTH;
end package instruction_pkg;

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
    constant ICMDW  : natural := 4;    
    constant PARAMW : natural := WORDWIDTH; 
    constant PARAMS : natural := 2;
    constant INSTW  : natural := IPTRW*PARAMS + ICMDW + PARAMW*PARAMS; --24

    constant INSTD : natural := WORDWIDTH;
end package instruction_pkg;

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

    constant CNOP : std_ulogic_vector(ICMDW - 1 downto 0) := x"0";
    constant CISZ : std_ulogic_vector(ICMDW - 1 downto 0) := x"1";
    constant CJMP : std_ulogic_vector(ICMDW - 1 downto 0) := x"2";
    constant CSTP : std_ulogic_vector(ICMDW - 1 downto 0) := x"3";
    constant CINC : std_ulogic_vector(ICMDW - 1 downto 0) := x"4";
    constant CDEC : std_ulogic_vector(ICMDW - 1 downto 0) := x"5";
end package instruction_pkg;

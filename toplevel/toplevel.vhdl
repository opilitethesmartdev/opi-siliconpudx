----------------------------------------------------------------------------
-- Project		:	OPI-siliconPUdx
-- Authors		:	opilitethesmartdev
-- Description	:	Processor toplevel
----------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.core_pkg.all;
use work.register_pkg.all;
use work.instruction_pkg.all;

entity toplevel is
    port(
        -- Fundamental signals
        clk : in std_ulogic; -- fast clock
        rst : in std_ulogic;
        en : in  std_ulogic_vector(1 downto 0); -- [imode][en] 
        o  : out std_ulogic_vector(1 downto 0); -- [done][err]
        
        -- Instruction bank
        inst_cmd  : in std_ulogic_vector(1 downto 0);
        inst_addr : in unsigned(INSTD-1 downto 0);
        inst_i : in  std_ulogic_vector(INSTW-1 downto 0);
        inst_o : out std_ulogic_vector(INSTW-1 downto 0); 
        
        -- Register bank
        re_cmd  : in std_ulogic_vector(2 downto 0);
        re_addr : in unsigned(REGD-1 downto 0);
        re_i : in  std_ulogic_vector(WORDWIDTH-1 downto 0);
        re_o : out std_ulogic_vector(WORDWIDTH-1 downto 0);

        -- Mock output (prevents instruction architecture from being optimized away at synthesis)
        instruction : out std_ulogic
    );

end entity toplevel;

architecture rtl of toplevel is
  
begin

end architecture rtl;
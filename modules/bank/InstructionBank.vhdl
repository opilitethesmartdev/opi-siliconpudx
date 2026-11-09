----------------------------------------------------------------------------
-- Project		:	OPI-siliconPUdx
-- Authors		:	opilitethesmartdev
-- Description	:	Instruction bank
----------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.core_pkg.all;
use work.register_pkg.all;

entity InstructionBank is
    port (
        clk : in std_ulogic;
        o : out std_ulogic_vector(1 downto 0); -- [stp][nop]
        
        cmd  : in  std_ulogic_vector(1 downto 0); --[read][write]; xor = en; 
        addr : in  unsigned(REGD - 1 downto 0); 
        din  : in  std_ulogic_vector(WORDWIDTH - 1 downto 0);
        dout : out std_ulogic_vector(WORDWIDTH - 1 downto 0)--;       
    );
end entity InstructionBank;

architecture rtl of InstructionBank is
    
begin
    
    
    
end architecture rtl;
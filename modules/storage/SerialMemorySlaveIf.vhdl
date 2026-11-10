----------------------------------------------------------------------------
-- Project		:	OPI-siliconPUdx
-- Authors		:	opilitethesmartdev
-- Description	:	8-wire serial interface to external memory
----------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.core_pkg.all;
use work.register_pkg.all;

entity SerialMemorySlaveIf is
    generic(
        DATAWIDTH : natural := 4;
        ADDRWIDTH : natural := 2;
    );
    port (
        clk : in std_ulogic;
        
        int : out std_ulogic;
        cmd : in std_ulogic;

        addr : in   std_ulogic_vector(ADDRWIDTH - 1 downto 0);
        dio  : inout std_ulogic_vector(DATAWIDTH - 1 downto 0)--;       
    );
end entity SerialMemorySlaveIf;

architecture rtl of SerialMemorySlaveIf is
begin
end architecture rtl;
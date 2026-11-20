----------------------------------------------------------------------------
-- Project		:	OPI-SiliconPUdx
-- Authors		:	opilitethesmartdev
-- Description	:	Memory Mapped IO Interface
----------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.core_pkg.all;
use work.register_pkg.all;
use work.instruction_pkg.all;

entity MMioIf is
    generic(
        W : natural := 8
    );
    port (
        clk : in std_ulogic;
        rst : in std_ulogic;

        cmd : in std_ulogic_vector(1 downto 0)
    );
end MMioIf ;

architecture rtl of MMioIf is
begin
end architecture ; -- rtl
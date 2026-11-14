----------------------------------------------------------------------------
-- Project		:	OPI-siliconPUdx
-- Authors		:	opilitethesmartdev
-- Description	:	Execution Unit
----------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.core_pkg.all;
use work.register_pkg.all;
use work.instruction_pkg.all;

entity ExecutionUnit is
    port (
        clk : in std_ulogic;
        rst : in std_ulogic;
        en  : in std_ulogic;
        
        -- PCIf
        cmd : in std_ulogic_vector(1 downto 0);
        ovr : in unsigned(INSTD - 1 downto 0)
    );
end entity ExecutionUnit;

architecture rtl of ExecutionUnit is
begin
end rtl; -- rtl
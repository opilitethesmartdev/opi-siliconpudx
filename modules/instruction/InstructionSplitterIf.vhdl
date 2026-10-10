----------------------------------------------------------------------------
-- Project		:	OPI-siliconPUdx
-- Authors		:	opilitethesmartdev
-- Description	:	Instruction Splitter interface
----------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.core_pkg.all;
use work.register_pkg.all;
use work.instruction_pkg.all;

entity InstructionSplitterIf is
    port(
        i : in std_ulogic_vector(INSTW - 1 downto 0);

        cmd : out std_ulogic_vector(ICMDW - 1 downto 0);

        depth0 : out std_ulogic_vector(IPTRW - 1 downto 0);
        param0 : out std_ulogic_vector(PARAMW - 1 downto 0);

        depth1 : out std_ulogic_vector(IPTRW - 1 downto 0);
        param1 : out std_ulogic_vector(PARAMW - 1 downto 0)
    );

end entity InstructionSplitterIf;

architecture rtl of InstructionSplitterIf is
begin    
    cmd <= i(ICMDW + PARAMW*PARAMS - 1 downto PARAMW*PARAMS);

    depth0 <= i(INSTW - 1 downto IPTRW + ICMDW + PARAMW*PARAMS);
    param0 <= i(PARAMW*PARAMS - 1 downto PARAMW);

    depth1 <= i(IPTRW + ICMDW + PARAMW*PARAMS - 1 downto ICMDW + PARAMW*PARAMS);
    param1 <= i(PARAMW - 1 downto 0);
end architecture rtl;
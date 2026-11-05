----------------------------------------------------------------------------
-- Project		:	OPI-siliconPUdx
-- Authors		:	opilitethesmartdev
-- Description	:	ASIC harness
----------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.core_pkg.all;
use work.register_pkg.all;
use work.instruction_pkg.all;

entity asic_harness is
    port(
        -- Fundamental signals
        clk : in std_ulogic;
        rst : in std_ulogic;
        en : in  std_ulogic_vector(1 downto 0);
        o  : out std_ulogic_vector(1 downto 0);

        rw : in std_ulogic_vector(1 downto 0);
        addr : in std_ulogic_vector(REGD - 1 downto 0);

        din  : in std_ulogic_vector(WORDWIDTH - 1 downto 0);
        dout : out std_ulogic_vector(WORDWIDTH - 1 downto 0);

        -- Mock output (prevents instruction architecture from being optimized away at synthesis)
        instruction : out std_ulogic
    );

end entity asic_harness;

architecture rtl of asic_harness is

begin

end architecture rtl;
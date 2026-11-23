----------------------------------------------------------------------------
-- Project		:	OPI-siliconPUdx
-- Authors		:	opilitethesmartdev
-- Description	:	Transient State machine Interface
----------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.uart_pkg.all;
use work.core_pkg.all;
use work.register_pkg.all;
use work.instruction_pkg.all;

entity TransientStateIf is
    generic(
        STATES: natural := 4;
        FFPR: string := "reset";
        FFPO: string := "rising"
    );
    port (
        clk : in std_ulogic;
        rst : in std_ulogic;

        ss : in std_ulogic_vector(STATES - 1 downto 0);
        sr : in std_ulogic_vector(STATES - 1 downto 0);

        so : out std_ulogic_vector(STATES - 1 downto 0)
    );
end entity TransientStateIf;

architecture rtl of TransientStateIf is
    signal srint : std_ulogic_vector(STATES - 1 downto 0);
begin
    sm: for i in 0 to STATES-1 generate
        srff : entity work.sr_ff
            generic map(
                PRIORITY => FFPR,
                POLARITY => FFPO
            )
            port map(
                clk => clk,
                s   => ss(i),
                r   => srint(i),
                o   => so(i)
        );
    end generate;

    smrst: for i in 0 to STATES-1 generate
        srint(i) <= sr(i) or rst;
    end generate;
            
end architecture rtl;
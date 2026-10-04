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
        clk : in std_ulogic; -- fast clock
        rst : in std_ulogic;
        en : in std_ulogic;
        o  : out std_ulogic_vector(1 downto 0); -- ([done][error])

        -- Data IO Interface
        rw : in std_ulogic_vector(1 downto 0); -- read / write cmd ([read][write], xor = enable, and = inst_wr)
        addr : in unsigned(REGDEPTH - 1 downto 0);
        dio : inout unsigned(WORDWIDTH - 1 downto 0)
    );

end entity asic_harness;

architecture rtl of asic_harness is
    signal inst_wr   :  std_ulogic;
    signal inst_addr :  unsigned(INST_DEPTH-1 downto 0);
    signal inst_i    :  std_ulogic_vector(INST_WIDTH-1 downto 0);
    signal re_cmd    :  std_ulogic_vector(1 downto 0);
    signal re_addr   :  unsigned(REGDEPTH-1 downto 0);
    signal re_regi   :  std_ulogic_vector(REGWIDTH-1 downto 0);
    signal re_rego   :  std_ulogic_vector(REGWIDTH-1 downto 0);
component toplevel is
    port(
        clk       : in std_ulogic;
        rst       : in std_ulogic;
        en        : in std_ulogic;
        o         : out std_ulogic_vector(1 downto 0);
        inst_wr   : in std_ulogic;
        inst_addr : in unsigned(INST_DEPTH-1 downto 0);
        inst_i    : in std_ulogic_vector(INST_WIDTH-1 downto 0);
        re_cmd    : in std_ulogic_vector(1 downto 0);
        re_addr   : in unsigned(REGDEPTH-1 downto 0);
        re_regi   : in std_ulogic_vector(REGWIDTH-1 downto 0);
        re_rego   : out std_ulogic_vector(REGWIDTH-1 downto 0)
    );
end component toplevel;

begin
    i_toplevel : toplevel
        port map(
            clk       => clk,
            rst       => rst,
            en        => en,
            o         => o,
            inst_wr   => inst_wr,
            inst_addr => inst_addr,
            inst_i    => inst_i,
            re_cmd    => re_cmd,
            re_addr   => re_addr,
            re_regi   => re_regi,
            re_rego   => re_rego
    );

    re_cmd <= rw when ((xor rw) = '0') else "00";
end architecture rtl;
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
        dout : out std_ulogic_vector(WORDWIDTH - 1 downto 0)
    );

end entity asic_harness;

architecture rtl of asic_harness is
    signal inst_cmd  :  std_ulogic_vector(1 downto 0);
    signal inst_addr :  unsigned(INSTD-1 downto 0);
    signal inst_i    :  std_ulogic_vector(INSTW-1 downto 0);
    signal inst_o    :  std_ulogic_vector(INSTW-1 downto 0);

    signal re_cmd    :  std_ulogic_vector(2 downto 0);
    signal re_addr   :  unsigned(REGD-1 downto 0);
    signal re_i      :  std_ulogic_vector(WORDWIDTH-1 downto 0);
    signal re_o      :  std_ulogic_vector(WORDWIDTH-1 downto 0);

begin
    i_toplevel : entity work.toplevel
        port map(
            clk       => clk,
            rst       => rst,
            en        => en,
            o         => o,
            inst_cmd  => inst_cmd,
            inst_addr => inst_addr,
            inst_i    => inst_i,
            inst_o    => inst_o,
            re_cmd    => re_cmd,
            re_addr   => re_addr,
            re_i      => re_i,
            re_o      => re_o
    );

    re_cmd <= ('0' & rw) when (xor rw) else "000";
    re_addr <= unsigned(addr) when (xor rw) else (others => '0');
    re_i <= din when rw = "10" else (others => '0');
    dout <= re_o when rw = "01" else (others => '0');

    inst_cmd <= "01" when (and rw) else "00";
    inst_addr <= resize(unsigned(addr), INSTD) when (and rw) else (others => '0');
    inst_i <= din when rw = "11" else (others => '0');

end architecture rtl;
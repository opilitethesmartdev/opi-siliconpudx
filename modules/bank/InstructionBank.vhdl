----------------------------------------------------------------------------
-- Project		:	OPI-siliconPUdx
-- Authors		:	opilitethesmartdev
-- Description	:	Instruction Bank
----------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.core_pkg.all;
use work.register_pkg.all;
use work.instruction_pkg.all;

entity InstructionBank is
    port(
        -- Fundamental signals
        clk : in std_ulogic;

        -- Data interface
        cmd : in std_ulogic_vector(1 downto 0); -- [read][write], xor = enable
        addr : in  unsigned(INSTD - 1 downto 0);
        din  : in  std_ulogic_vector(INSTW - 1 downto 0);
        dout : out std_ulogic_vector(INSTW - 1 downto 0)
    );

end entity InstructionBank;

architecture rtl of InstructionBank is
    signal rden :  std_ulogic;
    signal wren :  std_ulogic;
    signal s0_din  :  std_ulogic_vector(7 downto 0);
    signal s0_dout :  std_ulogic_vector(7 downto 0);

    signal s1_din  :  std_ulogic_vector(7 downto 0);
    signal s1_dout :  std_ulogic_vector(7 downto 0);

    signal s2_din  :  std_ulogic_vector(7 downto 0);
    signal s2_dout :  std_ulogic_vector(7 downto 0);
begin

    rden <= '1' when cmd = "10" else '0';
    wren <= '1' when cmd = "01" else '0';

    s2_din <= din(INSTW - 1 downto WORDWIDTH*2);
    s1_din <= din(WORDWIDTH*2 - 1 downto WORDWIDTH);
    s0_din <= din(WORDWIDTH - 1 downto 0);

    dout <= (s2_dout & s1_dout & s0_dout);

    sram0 : entity work.sram_macro
        port map(
            clk  => clk,
            en   => rden,
            wren => wren,
            mask => (others => '1'),
            addr => addr,
            din  => s0_din,
            dout => s0_dout
    );

    sram1 : entity work.sram_macro
        port map(
            clk  => clk,
            en   => rden,
            wren => wren,
            mask => (others => '1'),
            addr => addr,
            din  => s1_din,
            dout => s1_dout
    );

    sram2 : entity work.sram_macro
        port map(
            clk  => clk,
            en   => rden,
            wren => wren,
            mask => (others => '1'),
            addr => addr,
            din  => s2_din,
            dout => s2_dout
    );
end architecture rtl;
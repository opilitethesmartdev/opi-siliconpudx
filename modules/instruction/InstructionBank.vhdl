----------------------------------------------------------------------------
-- Project		:	OPI-siliconPUdx
-- Authors		:	opilitethesmartdev
-- Description	:	Instruction bank
----------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.instruction_pkg.all;

entity InstructionBank is
    port(
        -- Fundamental signals
        clk : in std_ulogic;
        rst : in std_ulogic;
        fin : out std_ulogic;
        err : out std_ulogic;

        -- Instruction rw interface
        cmd  : in std_ulogic_vector(1 downto 0);        -- read / write cmd ([read][write], xor = enable)
        addr : in unsigned(INST_DEPTH - 1 downto 0);
        insi : in std_ulogic_vector(INST_WIDTH - 1 downto 0);
        inso : out inst_rec_t
    );
end entity InstructionBank;

architecture bhv of InstructionBank is
    signal en : std_ulogic;
    signal inst : inst_array_t;

    signal s0_en :  std_ulogic;
    signal s0_wren :  std_ulogic;
    signal s0_mask :  std_ulogic_vector(7 downto 0);
    signal s0_addr :  unsigned(7 downto 0);
    signal s0_din  :  std_ulogic_vector(7 downto 0);
    signal s0_dout :  std_ulogic_vector(7 downto 0);

    signal s1_en :  std_ulogic;
    signal s1_wren :  std_ulogic;
    signal s1_mask :  std_ulogic_vector(7 downto 0);
    signal s1_addr :  unsigned(7 downto 0);
    signal s1_din  :  std_ulogic_vector(7 downto 0);
    signal s1_dout :  std_ulogic_vector(7 downto 0);


begin
    sram0 : entity work.sram_macro
        generic map(
            CONFIG => "sram256x8m8wm1"
        )
        port map(
            clk  => clk,
            en   => s0_en,
            wren => s0_wren,
            mask => s0_mask,
            addr => s0_addr,
            din  => s0_din,
            dout => s0_dout
    );

    sram1 : entity work.sram_macro
        generic map(
            CONFIG => "sram256x8m8wm1"
        )
        port map(
            clk  => clk,
            en   => s1_en,
            wren => s1_wren,
            mask => s1_mask,
            addr => s1_addr,
            din  => s1_din,
            dout => s1_dout
    );
    en <= cmd(1) and not (rst or cmd(0));

    inso <= v2inst(s1_dout & s0_dout) when en = '1' else v2inst(INSTNULL);

    fin  <= '1' when en = '1' and (
        inst2cmd(inst(to_integer(addr))) = stp or 
        inst2cmd(inst(to_integer(addr))) = nop
        ) else '0';
    err  <= '1' when en = '1' and inst2cmd(inst(to_integer(addr))) = nop else '0';
end architecture bhv;
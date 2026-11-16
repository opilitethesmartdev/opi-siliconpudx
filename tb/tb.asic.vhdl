----------------------------------------------------------------------------
-- Project		:	OPI-siliconPUdx
-- Authors		:	opilitethesmartdev
-- Description	:	ASIC testbench
----------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.stop;

use work.core_pkg.all;
use work.register_pkg.all;
use work.instruction_pkg.all;

entity tb_asic is
end entity tb_asic;

architecture sim of tb_asic is
    signal clk  :  std_ulogic := '0';
    signal en   :  std_ulogic_vector(1 downto 0) := "00";
    signal rst  :  std_ulogic;

    signal o           :  std_ulogic_vector(1 downto 0);
    signal mosi        :  std_ulogic;
    signal t_si        :  std_ulogic;
    signal miso        :  std_ulogic;
    signal t_so        :  std_ulogic;
    signal ram_en      :  std_ulogic;
    signal ram_wren    :  std_ulogic;
    signal ram_mask    :  std_ulogic_vector(IBWIDTH-1 downto 0);
    signal ram_addr    :  unsigned(INSTD-1 downto 0);
    signal ram_din     :  std_ulogic_vector(IBWIDTH-1 downto 0);
    signal ram_dout    :  std_ulogic_vector(IBWIDTH-1 downto 0);
    signal instruction :  std_ulogic;

    constant program : program_arr_t(0 to 16) := (
            x"01" & newinst(0, 0, lda, x"0000"),-- 0  | lda  0x0
            x"02" & newinst(0, 0, atr, 0, 0),   -- 1  | atr  0
            x"08" & newinst(0, 0, lda, x"0001"),-- 2  | lda  0x1
            x"06" & newinst(0, 0, atr, 1, 0),   -- 3  | atr  1
            x"05" & newinst(0, 0, lda, x"0002"),-- 4  | lda  0x2
            x"00" & newinst(0, 0, atr, 2, 0),   -- 5  | atr  2
            x"00" & newinst(0, 0, lda, x"0003"),-- 6  | lda  0x3
            x"00" & newinst(0, 0, atr, 4, 0),   -- 7  | atr  4
            x"00" & newinst(0, 0, lda, x"0004"),-- 8  | lda  0x4
            x"00" & newinst(0, 0, atr, 6, 0),   -- 9  | atr  6
            x"00" & inst2v(INSTNULL(idl)),      -- 10 | idl
            x"00" & newinst(1, 0, isz, 0, 0),   -- 11 | isz >0  0
            x"00" & newinst(0, 0, jmp, x"000E"),-- 12 | jmp  0xE
            x"00" & newinst(0, 0, stp, 0, 0),   -- 13 | stp
            x"00" & newinst(1, 0, dec, 0, 1),   -- 14 | dec >0  1
            x"00" & newinst(1, 0, inc, 4, 1),   -- 15 | inc >4  1
            x"00" & newinst(0, 0, jmp, x"000B") -- 16 | jmp  0xB
        );

begin
    clk <= (not clk) after 5 ns;
    rst <= '1', '0' after 20 ns;

    i_asic_harness : entity work.asic_harness
        port map(
            clk         => clk,
            rst         => rst,
            en          => en,
            o           => o,
            mosi        => mosi,
            t_si        => t_si,
            miso        => miso,
            t_so        => t_so,
            ram_en      => ram_en,
            ram_wren    => ram_wren,
            ram_mask    => ram_mask,
            ram_addr    => ram_addr,
            ram_din     => ram_din,
            ram_dout    => ram_dout,
            instruction => instruction
    );

    testbench : process
    begin
        wait for 10 ns;
        en(0) <= '1';
        wait on o;
        en(0) <= '0';
        report "Finish";
        wait for 400 ns;
        stop;
    end process testbench;
    
end architecture sim;
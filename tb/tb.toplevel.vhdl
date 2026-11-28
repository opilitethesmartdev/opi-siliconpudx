----------------------------------------------------------------------------
-- Project		:	OPI-siliconPUdx
-- Authors		:	opilitethesmartdev
-- Description	:	Toplevel testbench
----------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.stop;

use work.core_pkg.all;
use work.register_pkg.all;
use work.instruction_pkg.all;

entity tb_topl is
end entity tb_topl;

architecture sim of tb_topl is
    signal clk  :  std_ulogic := '0';
    signal en   :  std_ulogic := '0';
    signal rst  :  std_ulogic;
    signal fin  :  std_ulogic;

    signal o    :  std_ulogic_vector(1 downto 0);

    signal re_cmd      :  std_ulogic_vector(1 downto 0);
    signal re_addr     :  unsigned(REGD-1 downto 0);
    signal re_i        :  std_ulogic_vector(WORDWIDTH-1 downto 0);
    signal re_o        :  std_ulogic_vector(WORDWIDTH-1 downto 0) := (others => '0');

    signal instruction :  std_ulogic;
    

    signal sel_ram      :  std_ulogic;

    signal ram_en      :  std_ulogic;
    signal ram_wren    :  std_ulogic;
    signal ram_mask    :  std_ulogic_vector(IBWIDTH-1 downto 0);
    signal ram_addr    :  unsigned(INSTD-1 downto 0);
    signal ram_dout    :  std_ulogic_vector(IBWIDTH-1 downto 0);
    signal ram_din  :  std_ulogic_vector(IBWIDTH-1 downto 0);

    signal man_ram_en   :  std_ulogic;
    signal man_ram_wren :  std_ulogic;
    signal man_ram_mask :  std_ulogic_vector(IBWIDTH-1 downto 0);
    signal man_ram_addr :  unsigned(INSTD-1 downto 0);
    signal man_ram_din  :  std_ulogic_vector(IBWIDTH-1 downto 0);
    signal man_ram_dout :  std_ulogic_vector(IBWIDTH-1 downto 0) := (others => '0');

    signal dut_ram_en   :  std_ulogic;
    signal dut_ram_wren :  std_ulogic;
    signal dut_ram_mask :  std_ulogic_vector(IBWIDTH-1 downto 0);
    signal dut_ram_addr :  unsigned(INSTD-1 downto 0);
    signal dut_ram_din  :  std_ulogic_vector(IBWIDTH-1 downto 0);
    signal dut_ram_dout :  std_ulogic_vector(IBWIDTH-1 downto 0);

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

    fin <= or o;

    --enc <= '0' & en;

    --sim_inst_i <= v2inst(inst_i);

    i_toplevel : entity work.toplevel
        port map(
            clk         => clk,
            rst         => rst,
            en          => en,
            o           => o,
            ram_en      => dut_ram_en,
            ram_wren    => dut_ram_wren,
            ram_mask    => dut_ram_mask,
            ram_addr    => dut_ram_addr,
            ram_dout    => dut_ram_dout,
            re_cmd      => re_cmd,
            re_addr     => re_addr,
            re_i        => re_i,
            re_o        => re_o,
            instruction => instruction
    );

    i_SRAMMuxIf : entity work.SRAMMuxIf
        port map(
            sel        => sel_ram,
            ram_en     => ram_en,
            ram_wren   => ram_wren,
            ram_mask   => ram_mask,
            ram_addr   => ram_addr,
            ram_din    => ram_din,
            ram_dout   => ram_dout,
            ram_0_en   => man_ram_en,
            ram_0_wren => man_ram_wren,
            ram_0_mask => man_ram_mask,
            ram_0_addr => man_ram_addr,
            ram_0_din  => man_ram_din,
            ram_0_dout => man_ram_dout,
            ram_1_en   => dut_ram_en,
            ram_1_wren => dut_ram_wren,
            ram_1_mask => dut_ram_mask,
            ram_1_addr => dut_ram_addr,
            ram_1_din  => dut_ram_din,
            ram_1_dout => dut_ram_dout
    );
    
    i_ext_sram : entity work.ext_sram
        generic map(
            WORDWIDTH => IBWIDTH,
            WORDDEPTH => INSTD
        )
        port map(
            clk  => clk,
            en   => ram_en,
            wren => ram_wren,
            mask => ram_mask,
            addr => ram_addr,
            din  => ram_din,
            dout => ram_dout
    );
    

    testbench : process
    begin
        -- Pull defaults
        re_cmd <= "00";
        re_addr <= to_unsigned(0, REGD);  
        re_i <= (x"00");
        
        man_ram_en <= '0';
        man_ram_wren <= '0';
        man_ram_mask <= (others => '0');
        man_ram_addr <= to_unsigned(0, INSTD);  
        man_ram_din <= x"00" & newinst(0, 0, nop, 0, 0);

        sel_ram <= '0';
        wait for 10 ns;

        -- Write program
        for line in 0 to program'length - 1 loop
            --report "wrote line " & to_string(line);
            man_ram_en <= '1';
            man_ram_wren <= '1';
            man_ram_mask <= (others => '1');
            man_ram_addr <= to_unsigned(line, INSTD);  
            man_ram_din <= program(line);
            wait for 10 ns;
        end loop;
        
        man_ram_en <= '0';
        man_ram_wren <= '0';
        man_ram_mask <= (others => '0');
        man_ram_addr <= to_unsigned(0, INSTD);  
        man_ram_din <= x"00" & newinst(0, 0, nop, 0, 0);
        wait for 10 ns;
        sel_ram <= '1';


        -- Execute
        wait for 10 ns;
        en <= '1';
        wait on fin;
        wait for 10 ns;
        en <= '0';
        report "Finish";
        wait for 40 ns;
        stop;
    end process testbench;
    
end architecture sim;
----------------------------------------------------------------------------
-- Project		:	OPI-siliconPUdx
-- Authors		:	opilitethesmartdev
-- Description	:	Toplevel testbench
----------------------------------------------------------------------------

-- vhdl_ls offd
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


    --signal sim_inst_i : inst_rec_t;



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
        man_ram_din <= x"0" & newinst(0, 0, nop, 0, 0);

        sel_ram <= '0';

        -- Program:
        -- isz >>0   0
        -- jmp   3
        -- stp 
        -- dec >>0   0
        -- inc >>4   0
        -- jmp   0   0

        -- Write instructions
        wait for 10 ns;
            man_ram_en <= '1';
            man_ram_wren <= '1';
            man_ram_mask <= (others => '1');

            man_ram_addr <= to_unsigned(0, INSTD);  
            man_ram_din <= x"0" & newinst(2, 0, isz, 0, 0);
        wait for 10 ns;
            man_ram_addr <= to_unsigned(1, INSTD);  
            man_ram_din <= x"0" & newinst(0, 0, jmp, 0, 3);
        wait for 10 ns;
            man_ram_addr <= to_unsigned(2, INSTD);  
            man_ram_din <= x"0" & newinst(0, 0, stp, 0, 0);
        wait for 10 ns;
            man_ram_addr <= to_unsigned(3, INSTD);  
            man_ram_din <= x"0" & newinst(2, 0, dec, 0, 0);
        wait for 10 ns;
            man_ram_addr <= to_unsigned(4, INSTD);  
            man_ram_din <= x"0" & newinst(2, 0, inc, 4, 0);
        wait for 10 ns;
            man_ram_addr <= to_unsigned(5, INSTD);  
            man_ram_din <= x"0" & newinst(0, 0, jmp, 0, 0);
        wait for 10 ns;
            man_ram_en <= '0';
            man_ram_wren <= '0';
            man_ram_mask <= (others => '0');
            man_ram_addr <= (others => '0');
            man_ram_din <=  (others => '0');
        wait for 10 ns;
        -- Mux SRAM to DUT      
        sel_ram <= '1';

        -- Write registers
        wait for 10 ns;
                re_cmd <= "01";
            re_addr <= to_unsigned(0, REGD);  
            re_i <= (x"01"); --0 ptr
        wait for 10 ns;
            re_addr <= to_unsigned(1, REGD);  
            re_i <= (x"02"); --1 ptr
        wait for 10 ns;
            re_addr <= to_unsigned(2, REGD);  
            re_i <= (x"08"); --2 lit
        wait for 10 ns;
            re_addr <= to_unsigned(3, REGD);  
            re_i <= (x"00"); --3 u
        wait for 10 ns;
            re_addr <= to_unsigned(4, REGD);  
            re_i <= (x"06"); --4 ptr
        wait for 10 ns;
            re_addr <= to_unsigned(5, REGD);  
            re_i <= (x"00"); --5 lit
        wait for 10 ns;
            re_addr <= to_unsigned(6, REGD);  
            re_i <= (x"05"); --6 ptr
        wait for 10 ns;
                --re_cmd <= "000";
                re_cmd <= "00";
                re_addr <= to_unsigned(0, REGD);  
                re_i <= (x"00");
        wait for 10 ns;
        
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
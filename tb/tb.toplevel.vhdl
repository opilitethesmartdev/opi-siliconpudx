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
    signal o    :  std_ulogic_vector(1 downto 0);

    signal ins_ram_en      :  std_ulogic;
    signal ins_ram_wren    :  std_ulogic;
    signal ins_ram_mask    :  std_ulogic_vector(IBWIDTH-1 downto 0);
    signal ins_ram_addr    :  unsigned(INSTD-1 downto 0);
    signal ins_ram_dout    :  std_ulogic_vector(IBWIDTH-1 downto 0);

    signal re_cmd      :  std_ulogic_vector(1 downto 0);
    signal re_addr     :  unsigned(REGD-1 downto 0);
    signal re_i        :  std_ulogic_vector(WORDWIDTH-1 downto 0);
    signal re_o        :  std_ulogic_vector(WORDWIDTH-1 downto 0);

    signal instruction :  std_ulogic;
    

    signal ram_en      :  std_ulogic;
    signal ram_wren    :  std_ulogic;
    signal ram_mask    :  std_ulogic_vector(IBWIDTH-1 downto 0);
    signal ram_addr    :  unsigned(INSTD-1 downto 0);
    signal ram_dout    :  std_ulogic_vector(IBWIDTH-1 downto 0);
    signal ram_din  :  std_ulogic_vector(IBWIDTH-1 downto 0);

    --signal sim_inst_i : inst_rec_t;



begin
    clk <= (not clk) after 5 ns;
    rst <= '1', '0' after 20 ns;

    --enc <= '0' & en;

    --sim_inst_i <= v2inst(inst_i);

    i_toplevel : entity work.toplevel
        port map(
            clk         => clk,
            rst         => rst,
            en          => en,
            o           => o,
            ram_en      => ins_ram_en,
            ram_wren    => ins_ram_wren,
            ram_mask    => ins_ram_mask,
            ram_addr    => ins_ram_addr,
            ram_dout    => ins_ram_dout,
            re_cmd      => re_cmd,
            re_addr     => re_addr,
            re_i        => re_i,
            re_o        => re_o,
            instruction => instruction
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

        -- Program:
        -- isz **0   0
        -- jmp   3 **0
        -- stp 
        -- dec **0   0
        -- inc **4   0
        -- jmp   0   0

        -- Write instructions
        wait for 10 ns;
            ram_en <= '1';
            ram_wren <= '1';
            ram_mask <= (others => '1');

            ram_addr <= to_unsigned(0, INSTD);  
            ram_din <= x"0" & newinst(2, 0, isz, 0, 0);
        wait for 10 ns;
            ram_addr <= to_unsigned(1, INSTD);  
            ram_din <= x"0" & newinst(0, 2, jmp, 3, 0);
        wait for 10 ns;
            ram_addr <= to_unsigned(2, INSTD);  
            ram_din <= x"0" & newinst(0, 0, stp, 0, 0);
        wait for 10 ns;
            ram_addr <= to_unsigned(3, INSTD);  
            ram_din <= x"0" & newinst(2, 0, dec, 0, 0);
        wait for 10 ns;
            ram_addr <= to_unsigned(4, INSTD);  
            ram_din <= x"0" & newinst(2, 0, inc, 4, 0);
        wait for 10 ns;
            ram_addr <= to_unsigned(5, INSTD);  
            ram_din <= x"0" & newinst(0, 0, jmp, 0, 0);
        wait for 10 ns;
            ram_en <= '0';
            ram_wren <= '0';
            ram_mask <= (others => '0');
            ram_addr <= (others => '0');
            ram_din <=  (others => '0');
        wait for 10 ns;
        -- Wire the SRAM to Toplevel
            ram_en <= ins_ram_en;
            ram_wren <= ins_ram_wren;
            ram_mask <= ins_ram_mask;
            ram_addr <= ins_ram_addr;
            ins_ram_dout <= ram_dout;

        -- Write registers
        wait for 10 ns;
                --re_cmd <= "001";
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
        wait on o(1);
        en <= '0';
        report "Finish";
        wait for 400 ns;
        stop;
    end process testbench;
    
end architecture sim;
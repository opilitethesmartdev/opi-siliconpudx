----------------------------------------------------------------------------
-- Project		:	OPI-siliconPUdx
-- Authors		:	opilitethesmartdev
-- Description	:	Toplevel testbench
----------------------------------------------------------------------------

-- vhdl_ls off
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

    signal enc       :  std_ulogic_vector(1 downto 0);
    signal inst_cmd  :  std_ulogic_vector(1 downto 0);
    signal inst_addr :  unsigned(INSTD-1 downto 0);
    signal inst_i    :  std_ulogic_vector(INSTW-1 downto 0);
    signal inst_o    :  std_ulogic_vector(INSTW-1 downto 0);
    signal re_cmd    :  std_ulogic_vector(2 downto 0);
    signal re_addr   :  unsigned(REGD-1 downto 0);
    signal re_i      :  std_ulogic_vector(WORDWIDTH-1 downto 0);
    signal re_o      :  std_ulogic_vector(WORDWIDTH-1 downto 0);

    signal sim_inst_i : inst_rec_t;

begin
    clk <= (not clk) after 5 ns;
    rst <= '1', '0' after 20 ns;

    enc <= '0' & en;

    sim_inst_i <= v2inst(inst_i);

    i_toplevel : entity work.toplevel
        port map(
            clk       => clk,
            rst       => rst,
            en        => enc,
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

    testbench : process
    begin
        -- Pull defaults
        re_cmd <= "000";
        re_addr <= to_unsigned(0, REGD);  
        re_i <= (x"00");

        inst_cmd <= "00";
        inst_addr <= to_unsigned(0, INSTD);
        inst_i <= newinst(0, 0, nop, 0, 0);

        -- Write instructions
        wait for 20 ns;
                inst_cmd <= "01";
            inst_addr <= to_unsigned(0, INSTD);
            inst_i <= newinst(3, 0, isz, 0, 0);
        wait for 10 ns;
            inst_addr <= to_unsigned(1, INSTD);  
            inst_i <= newinst(0, 0, jmp, 3, 0);
        wait for 10 ns;
            inst_addr <= to_unsigned(2, INSTD);       
            inst_i <= newinst(0, 0, stp, 0, 0);
        wait for 10 ns;
            inst_addr <= to_unsigned(3, INSTD);
            inst_i <= newinst(2, 0, dec, 0, 0);
        wait for 10 ns;
            inst_addr <= to_unsigned(4, INSTD);
            inst_i <= newinst(2, 0, inc, 4, 0);
        wait for 10 ns;
            inst_addr <= to_unsigned(5, INSTD);
            inst_i <= newinst(0, 0, jmp, 0, 0);
        wait for 10 ns;
                inst_cmd <= "00";
                inst_addr <= to_unsigned(0, INSTD);
                inst_i <= newinst(0, 0, nop, 0, 0);
        wait for 10 ns;

        -- Write registers
        wait for 10 ns;
                re_cmd <= "001";
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
                re_cmd <= "000";
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
----------------------------------------------------------------------------
-- Project		:	OPI-siliconPUdx
-- Authors		:	opilitethesmartdev
-- Description	:	Testbench
----------------------------------------------------------------------------

-- vhdl_ls off
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.stop;

use work.core_pkg.all;
use work.register_pkg.all;
use work.instruction_pkg.all;

entity tb is
end entity tb;

architecture sim of tb is
    signal clk  :  std_ulogic := '0';
    signal en   :  std_ulogic := '0';
    signal rst  :  std_ulogic;
    signal o         :  std_ulogic_vector(1 downto 0);
    signal inst_wr   :  std_ulogic := '0';
    signal inst_addr :  unsigned(INST_DEPTH-1 downto 0) := (others => '0');
    signal inst_i    :  std_ulogic_vector(INST_WIDTH-1 downto 0) := (others => '0');
    signal re_cmd    :  std_ulogic_vector(1 downto 0) := (others => '0');
    signal re_addr   :  unsigned(REGDEPTH-1 downto 0) := (others => '0');
    signal re_regi   :  std_ulogic_vector(REGWIDTH-1 downto 0) := (others => '0');
    signal re_rego   :  std_ulogic_vector(REGWIDTH-1 downto 0) := (others => '0');

begin
    clk <= (not clk) after 5 ns;
    rst <= '1', '0' after 20 ns;

    i_toplevel : entity work.toplevel
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


    testbench : process
    begin

        wait for 20 ns;
                inst_wr <= '1';
            inst_addr <= to_unsigned(0, INST_DEPTH);
            inst_i <= newinst(3, isz, 0);
        wait for 10 ns;
            inst_addr <= to_unsigned(1, INST_DEPTH);  
            inst_i <= newinst(0, jmp, 3);
        wait for 10 ns;
            inst_addr <= to_unsigned(2, INST_DEPTH);       
            inst_i <= newinst(0, stp, 0);
        wait for 10 ns;
            inst_addr <= to_unsigned(3, INST_DEPTH);
            inst_i <= newinst(2, dec, 0);
        wait for 10 ns;
            inst_addr <= to_unsigned(4, INST_DEPTH);
            inst_i <= newinst(2, inc, 4);
        wait for 10 ns;
            inst_addr <= to_unsigned(5, INST_DEPTH);
            inst_i <= newinst(0, jmp, 0);
        wait for 10 ns;
                inst_wr <= '0';
        wait for 10 ns;

        wait for 10 ns;
                re_cmd <= "01";
            re_addr <= to_unsigned(0, REGDEPTH);  
            re_regi <= ("00" & x"01"); --0 ptr
        wait for 10 ns;
            re_addr <= to_unsigned(1, REGDEPTH);  
            re_regi <= ("00" & x"02"); --1 ptr
        wait for 10 ns;
            re_addr <= to_unsigned(2, REGDEPTH);  
            re_regi <= ("00" & x"08"); --2 lit
        wait for 10 ns;
            re_addr <= to_unsigned(3, REGDEPTH);  
            re_regi <= ("00" & x"00"); --3 u
        wait for 10 ns;
            re_addr <= to_unsigned(4, REGDEPTH);  
            re_regi <= ("00" & x"06"); --4 ptr
        wait for 10 ns;
            re_addr <= to_unsigned(5, REGDEPTH);  
            re_regi <= ("00" & x"00"); --5 lit
        wait for 10 ns;
            re_addr <= to_unsigned(6, REGDEPTH);  
            re_regi <= ("00" & x"05"); --6 ptr
        wait for 10 ns;
                re_cmd <= "00";
        wait for 10 ns;

        wait for 10 ns;
        en <= '1';
        wait on o(0);
        en <= '0';
        report "Finish";
        wait for 400 ns;
        stop;
    end process testbench;
    
end architecture sim;
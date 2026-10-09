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
        wait for 10 ns;
        en <= '1';
        wait on o(0);
        en <= '0';
        report "Finish";
        wait for 400 ns;
        stop;
    end process testbench;
    
end architecture sim;
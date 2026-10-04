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

entity tb is
end entity tb;

architecture sim of tb is
    signal clk  :  std_ulogic := '0';
    signal en   :  std_ulogic := '0';
    signal rst  :  std_ulogic;
    signal done :  std_ulogic;
begin
    clk <= not clk after 5ns;
    rst <= '1', '0' after 20ns;

    i_toplevel : entity work.toplevel
        port map(
            clk  => clk,
            rst  => rst,
            done => done,
            en   => en
    );

    enable : process
    begin
        wait for 10ns;
        en <= '1';
        wait on done;
        en <= '0';
        report "Finish";
        wait for 400ns;
        stop;
    end process enable;
    
end architecture sim;
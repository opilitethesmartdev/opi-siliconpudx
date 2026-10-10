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

entity tb is
end entity tb;

architecture sim of tb is
    signal clk  :  std_ulogic := '0';
    signal en   :  std_ulogic := '0';
    signal rst  :  std_ulogic;
    signal o         :  std_ulogic_vector(1 downto 0);

signal ui_in   :  std_ulogic_vector(7 downto 0);
signal uo_out  :  std_ulogic_vector(7 downto 0);
signal uio_in  :  std_ulogic_vector(7 downto 0);
signal uio_out :  std_ulogic_vector(7 downto 0);
signal uio_oe  :  std_ulogic_vector(7 downto 0);


begin
    clk <= (not clk) after 5 ns;
    rst <= '0', '1' after 20 ns;

    i_tt_um_opi_siliconpudx : entity work.tt_um_opi_siliconpudx
        port map(
            clk     => clk,
            rst_n   => rst_n,
            ena     => en,
            ui_in   => ui_in,
            uo_out  => uo_out,
            uio_in  => uio_in,
            uio_out => uio_out,
            uio_oe  => uio_oe
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
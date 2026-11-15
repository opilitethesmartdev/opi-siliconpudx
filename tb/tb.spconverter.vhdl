----------------------------------------------------------------------------
-- Project		:	OPI-siliconPUdx
-- Authors		:	opilitethesmartdev
-- Description	:	SPconverter testbench
----------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.stop;

use work.core_pkg.all;
use work.register_pkg.all;
use work.instruction_pkg.all;

entity tb_spc is
end entity tb_spc;

architecture sim of tb_spc is
    constant DW :  natural := 43;

    signal clk   :  std_ulogic := '0';
    signal rst   :  std_ulogic := '0';
    signal mosi  :  std_ulogic;
    signal t_si  :  std_ulogic;
    signal miso  :  std_ulogic;
    signal t_so  :  std_ulogic;
    signal mo_en :  std_ulogic;
    signal d_mo  :  std_ulogic_vector(DW-1 downto 0);
    signal mo_fn :  std_ulogic;
    signal mi_av :  std_ulogic;
    signal d_mi  :  std_ulogic_vector(DW-1 downto 0);

    signal data_so : std_ulogic_vector(DW-1 downto 0);


begin
    clk <= (not clk) after 5 ns;
    rst <= '1', '0' after 20 ns;

    i_spconverter : entity work.spconverter
        generic map(
            DW => DW
        )
        port map(
            clk   => clk,
            rst   => rst,
            mosi  => mosi,
            t_si  => t_si,
            miso  => miso,
            t_so  => t_so,
            mo_en => mo_en,
            d_mo  => d_mo,
            mo_fn => mo_fn,
            mi_av => mi_av,
            d_mi  => d_mi
    );


    testbench : process
    begin
        -- Pull defaults
        t_so <= '0';
        miso <= '0';

        mo_en <= '0';
        d_mo <= (others => '0');

        data_so <= (others => '0');

        wait for 10 ns;
        t_so <= '1';
        wait for 10 ns;

        data_so <= "010" & x"DEADBEEF67";
        for i in 0 to DW - 1 loop
            miso <= data_so(DW - 1 - i);
            wait for 10 ns;
        end loop;

        t_so <= '0';
        wait for 20 ns;
        mo_en <= '1';
        d_mo <= "101" & x"5555555555";
        wait for 10 ns;
        mo_en <= '0';
        
        wait on mo_fn;
        wait for 50 ns;

        report "Finish";
        wait for 100 ns;
        stop;
    end process testbench;
    
end architecture sim;
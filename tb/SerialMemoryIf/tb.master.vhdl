----------------------------------------------------------------------------
-- Project		:	OPI-siliconPUdx
-- Authors		:	opilitethesmartdev
-- Description	:	Testbench for SerialMemoryMasterIf
----------------------------------------------------------------------------

-- vhdl_ls off
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use std.env.stop;
entity tb_serialmemoryif_master is
end tb_serialmemoryif_master;

architecture sim of tb_serialmemoryif_master is
    constant SDATAWIDTH : natural := 4;
    constant SADDRWIDTH : natural := 2;
    constant DATAWIDTH : natural := 32;
    constant ADDRWIDTH : natural := 16;

    signal clk  :  std_ulogic := '0';
    signal int  :  std_ulogic;
    signal ctrl  :  std_ulogic;
    signal addr :  std_ulogic_vector(SADDRWIDTH-1 downto 0);
    signal doe  :  std_ulogic_vector(SDATAWIDTH-1 downto 0);
    signal dmo  :  std_ulogic_vector(SDATAWIDTH-1 downto 0);
    signal dmi  :  std_ulogic_vector(SDATAWIDTH-1 downto 0);
    signal cmd  :  std_ulogic_vector(1 downto 0);
    signal addr :  unsigned(ADDRWIDTH-1 downto 0);
    signal dso  :  std_ulogic_vector(DATAWIDTH-1 downto 0);
    signal dsi  :  std_ulogic_vector(DATAWIDTH-1 downto 0);

begin
    clk <= (not clk) after 5 ns;

    i_SerialMemoryMasterIf : entity work.SerialMemoryMasterIf
        generic map(
            SDATAWIDTH => SDATAWIDTH,
            SADDRWIDTH => SADDRWIDTH,
            DATAWIDTH  => DATAWIDTH,
            ADDRWIDTH  => ADDRWIDTH 
        )
        port map(
            clk  => clk,

            int  => int,
            ctrl  => ctrl,
            addr => addr,
            doe  => doe,
            dmo  => dmo,
            dmi  => dmi,
            
            cmd  => cmd,
            addr => addr,
            dso  => dso,
            dsi  => dsi
    );
   
    testbench : process
    begin
        wait for 10 ns;
        cmd <= "10";
        addr <= to_unsigned(x"0F0F");
        dsi <= (others => '0');
        wait for 400 ns;
        report "Finish";
        stop;
    end process testbench;
    
end sim ;
----------------------------------------------------------------------------
-- Project		:	OPI-siliconPUdx
-- Authors		:	opilitethesmartdev
-- Description	:	UART testbench
----------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.stop;

use work.core_pkg.all;
use work.register_pkg.all;
use work.instruction_pkg.all;

entity tb_uart is
end entity tb_uart;

architecture sim of tb_uart is
    signal clk  :  std_ulogic := '0';
    signal uart_clk  :  std_ulogic := '0';
    signal rst  :  std_ulogic;

    constant W      :  natural := 8;
    --constant P      :  natural := 1;
    constant CLK_HZ :  natural := 25_000_000;
    constant BAUD   :  natural := 115200;

    constant TICKS   :  natural := 217; --(CLK_HZ/BAUD)

    signal rx_av :  std_ulogic;
    signal rx_o  :  std_ulogic_vector(W-1 downto 0);
    signal rx_p  :  std_ulogic;
    signal ack   :  std_ulogic;

    signal rx    :  std_ulogic;

    signal payload : std_ulogic_vector(8 downto 0);

begin
    clk <= (not clk) after 20 ns;
    rst <= '1', '0' after 40 ns;
    
    uart_clk <= (not uart_clk) after TICKS*40 ns;

    i_UARTrxIf : entity work.UARTrxIf
        generic map(
           -- P      => P,
            W      => W,
            CLK_HZ => CLK_HZ,
            BAUD   => BAUD
        )
        port map(
            clk   => clk,
            rst   => rst,
            rx_av => rx_av,
            rx_o  => rx_o,
            rx_p  => rx_p,
            ack   => ack,
            rx    => rx
    );

    testbench : process
    begin
        ack <= '0';

        rx <= '1';
        payload <= '0' & x"67";
        --payload <= x"67" & '0';

        wait on uart_clk;

        rx <= '0';

        for i in 0 to 8 loop
            wait on uart_clk;
            rx <= payload(i);
        end loop;

        wait on uart_clk;
        rx <= '0';
        wait on uart_clk;
        rx <= '1';

        report "Sent";
        wait for 400 ns;
        stop;
    end process testbench;
    
end architecture sim;
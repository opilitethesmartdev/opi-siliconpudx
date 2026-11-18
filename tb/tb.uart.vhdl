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

    signal rx_av  :  std_ulogic;
    signal rx_o   :  std_ulogic_vector(W-1 downto 0);
    signal rx_ack :  std_ulogic;
    signal tx_en  :  std_ulogic;
    signal tx_i   :  std_ulogic_vector(W-1 downto 0);
    signal tx_fin :  std_ulogic;
    signal tx_ack :  std_ulogic;
    signal tx     :  std_ulogic;
    signal rx     :  std_ulogic;


    signal payload : std_ulogic_vector(7 downto 0);
    signal receive : std_ulogic_vector(7 downto 0);

begin
    clk <= (not clk) after 20 ns;
    rst <= '1', '0' after 80 ns;
    
    uart_clk <= (not uart_clk) after TICKS*40 ns;

    UARTif : entity work.UARTIf
        generic map(
            W      => W,
            CLK_HZ => CLK_HZ,
            BAUD   => BAUD
        )
        port map(
            clk    => clk,
            rst    => rst,
            rx_av  => rx_av,
            rx_o   => rx_o,
            rx_ack => rx_ack,
            tx_en  => tx_en,
            tx_i   => tx_i,
            tx_fin => tx_fin,
            tx_ack => tx_ack,
            tx     => tx,
            rx     => rx
    );


    testbench : process
    begin
        rx_ack <= '0';
        tx_ack <= '0';

        tx_en <= '0';
        tx_i <= (others => '0');

        rx <= '1';
        payload <= x"67";
        receive <= x"00";

        wait on uart_clk;

        rx <= '0';

        for i in 0 to 7 loop
            wait on uart_clk;
            rx <= payload(i);
        end loop;

        wait on uart_clk;
        rx <= '0';
        wait on uart_clk;
        rx <= '1';

        report "Sent";
        wait on uart_clk;
        tx_en <= '1';
        tx_i  <= x"69";
        wait for 40 ns;
        tx_en <= '0';
        tx_i  <= (others => '0');
        
        wait on tx;
        wait on uart_clk;
        for i in 0 to 7 loop
            wait for (TICKS/2)*40 ns;
            receive(i) <= tx;
            wait for (TICKS/2)*40 ns;
        end loop;
        
        report "Received: " & to_hex_string(receive);
        tx_ack <= '1';
        wait for 20 ns;
        wait for 400 ns;
        stop;
    end process testbench;
    
end architecture sim;
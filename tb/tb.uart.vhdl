----------------------------------------------------------------------------
-- Project		:	OPI-siliconPUdx
-- Authors		:	opilitethesmartdev
-- Description	:	UART testbench
----------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.stop;

use work.uart_pkg.all;
use work.core_pkg.all;
use work.register_pkg.all;
use work.instruction_pkg.all;

entity tb_uart is
end entity tb_uart;

architecture sim of tb_uart is
    signal clk  :  std_ulogic := '0';
    signal rst  :  std_ulogic;

    constant W      :  natural := 8;
    constant CLK_HZ :  natural := 25_000_000;
    constant BAUD   :  natural := 115200;

    signal tx_en    :  std_ulogic;
    signal tx_i     :  std_ulogic_vector(W-1 downto 0);
    signal tx_ack   :  std_ulogic;
    signal tx_fin   :  std_ulogic;
    signal tx_msg_send :  std_ulogic;
    signal tx_msg_av   :  std_ulogic;
    signal tx_msg_done :  std_ulogic;
    signal tx_msg      :  uart_t(0 to 3);
    
    signal rxtx :  std_ulogic;

    signal rx_av  :  std_ulogic;
    signal rx_o   :  std_ulogic_vector(W-1 downto 0);
    signal rx_ack :  std_ulogic;
    signal rx_msg_av  :  std_ulogic;
    signal rx_msg_ack :  std_ulogic;
    signal rx_msg     :  uart_t(0 to 3);



begin
    clk <= (not clk) after 20 ns;
    rst <= '1', '0' after 80 ns;

    i_UARTIf : entity work.UARTIf
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
            tx     => rxtx,
            rx     => rxtx
    );

    i_LongUARTtxIf : entity work.LongUARTtxIf
        generic map(
            SEND_BYTES => 4,
            WW         => 3
        )
        port map(
            clk      => clk,
            rst      => rst,
            tx_en    => tx_en,
            tx_i     => tx_i,
            tx_ack   => tx_ack,
            tx_fin   => tx_fin,
            msg_send => tx_msg_send,
            msg_av   => tx_msg_av,
            msg_done => tx_msg_done,
            msg      => tx_msg
    );

    i_LongUARTrxIf : entity work.LongUARTrxIf
        generic map(
            EXPECTED_BYTES => 4,
            WW             => 3
        )
        port map(
            clk     => clk,
            rst     => rst,
            rx_av   => rx_av,
            rx_o    => rx_o,
            rx_ack  => rx_ack,
            msg_av  => rx_msg_av,
            msg_ack => rx_msg_ack,
            msg     => rx_msg
    );



    testbench : process
    begin
        tx_msg_send <= '0';
        tx_msg <= (others => x"00");
        wait for 160 ns;

        tx_msg_send <= '1';
        tx_msg <= (x"55", x"67", x"67", x"69");
        wait for 40 ns;

        tx_msg_send <= '0';
        tx_msg <= (others => x"00");
        wait on tx_msg_done;
        report "Sent";
        wait on rx_msg_av;

        report "Finish";
        wait for 400 ns;
        stop;
    end process testbench;
    
end architecture sim;
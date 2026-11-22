----------------------------------------------------------------------------
-- Project		:	OPI-siliconPUdx
-- Authors		:	opilitethesmartdev
-- Description	:	UART Toplevel Interface
----------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.uart_pkg.all;
use work.core_pkg.all;
use work.register_pkg.all;
use work.instruction_pkg.all;

entity UartIf is
    generic(
        CLK_HZ : natural := 27_000_000;
        BAUD   : natural := 115200
    );
    port (
        clk : in std_ulogic;
        rst : in std_ulogic;
        
        -- UART Interface
        rx: in std_ulogic;
        tx: in std_ulogic;
        
        --RX Application Interface
        rx_av  : out std_ulogic;
        rx_o   : out std_ulogic_vector(UWW - 1 downto 0);
        rx_ack : in  std_ulogic;

        -- TX Application Interface
        tx_en  : in std_ulogic;
        tx_i   : in std_ulogic_vector(UWW-1 downto 0);
        tx_ack : in std_ulogic;
        tx_fin : out std_ulogic
    );
end entity UartIf;

architecture rtl of UartIf is
begin
    txif : entity work.UartTxIf
        generic map(
            CLK_HZ => CLK_HZ,
            BAUD   => BAUD
        )
        port map(
            clk => clk,
            rst => rst,
            tx  => tx,
            en  => tx_en,
            i   => tx_i,
            ack => tx_ack,
            fin => tx_fin
    );
    rxif : entity work.UartRxIf
        generic map(
            CLK_HZ => CLK_HZ,
            BAUD   => BAUD
        )
        port map(
            clk => clk,
            rst => rst,
            rx  => rx,
            av  => rx_av,
            o   => rx_o,
            ack => rx_ack
    );
end architecture rtl;
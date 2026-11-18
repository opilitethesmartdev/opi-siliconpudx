----------------------------------------------------------------------------
-- Project		:	Generic
-- Authors		:	opilitethesmartdev
-- Description	:	Complete UART Interface
----------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity UARTIf is
    generic(
        W      : natural := 8;
        CLK_HZ : natural := 27_000_000;
        BAUD   : natural := 115200
    );
    port (
        clk : in std_ulogic;
        rst : in std_ulogic;

        rx_av : out std_ulogic;
        rx_o  : out std_ulogic_vector(W-1 downto 0);
        rx_ack : in std_ulogic;

        tx_en : in std_ulogic;
        tx_i  : in std_ulogic_vector(W-1 downto 0);
        tx_fin : out std_ulogic;
        tx_ack : in std_ulogic;

        tx : out std_ulogic;
        rx : in  std_ulogic
    );
end entity UARTIf;


architecture rtl of UARTIf is
begin
    rxif : entity work.UARTrxIf
        generic map(
            W      => W,
            CLK_HZ => CLK_HZ,
            BAUD   => BAUD
        )
        port map(
            clk   => clk,
            rst   => rst,

            rx_av => rx_av,
            rx_o  => rx_o,

            ack   => rx_ack,
            rx    => rx
        );
    txif : entity work.UARTtxIf
        generic map(
            W      => W,
            CLK_HZ => CLK_HZ,
            BAUD   => BAUD
        )
        port map(
            clk    => clk,
            rst    => rst,
            tx_en  => tx_en,
            tx_i   => tx_i,
            tx_fin => tx_fin,
            ack    => tx_ack,
            tx     => tx
        );
    


end architecture rtl;
----------------------------------------------------------------------------
-- Project		:	Generic
-- Authors		:	opilitethesmartdev
-- Description	:	UART Interface
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

        tx_en : in std_ulogic;
        tx_i  : in std_ulogic_vector(W-1 downto 0);

        tx : out std_ulogic;
        rx : in  std_ulogic
    );
end entity UARTIf;


architecture rtl of UARTIf is
    constant DIV : positive := CLK_HZ / BAUD;

    signal tick : std_ulogic;
    signal tcnt : unsigned(W*2 downto 0);

    signal rx_st  : std_ulogic;
    signal rx_sen : std_ulogic;

begin
    clkdiv: process (clk, rst)
    begin
        if rst = '1'then
            tick <= '0';
            tcnt <= (others => '0');
        elsif rising_edge(clk) then
            if rx_sen = '1' then
                if tcnt = (DIV - 1) then
                    tcnt <= (others => '0');
                    tick <= '1';
                else
                    tcnt <= tcnt + 1;
                    tick <= '0';
                end if;
            else
                tick <= '0';
                tcnt <= (others => '0');
            end if;
        end if;
    end process;

end architecture rtl;
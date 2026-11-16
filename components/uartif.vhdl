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
        CLK_HZ : natural := 25_000_000;
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

    constant DIVISOR : positive := CLK_HZ / BAUD;

    type tx_state_t is (TX_IDLE, TX_START, TX_DATA, TX_STOP);
    type rx_state_t is (RX_IDLE, RX_START, RX_DATA, RX_STOP);

    signal tx_state : tx_state_t := TX_IDLE;
    signal rx_state : rx_state_t := RX_IDLE;

    -- Transmitter
    signal tx_shift : std_ulogic_vector(W-1 downto 0);
    signal tx_count : natural range 0 to DIVISOR-1 := 0;
    signal tx_bit   : natural range 0 to W-1 := 0;

    -- Receiver
    signal rx_shift : std_ulogic_vector(W-1 downto 0);
    signal rx_count : natural range 0 to DIVISOR-1 := 0;
    signal rx_bit   : natural range 0 to W-1 := 0;

    -- RX synchronizer
    signal rx_meta : std_ulogic := '1';
    signal rx_sync : std_ulogic := '1';
    signal rx_prev : std_ulogic := '1';

begin

    assert W >= 1
        report "UARTIf: W must be greater than zero"
        severity failure;

    assert CLK_HZ >= BAUD * 4
        report "UARTIf: clock frequency too low for baud rate"
        severity failure;

    ----------------------------------------------------------------
    -- TRANSMITTER
    ----------------------------------------------------------------

    process(clk)
    begin
        if rising_edge(clk) then

            if rst = '1' then
                tx_state <= TX_IDLE;
                tx <= '1';
                tx_count <= 0;
                tx_bit <= 0;

            else

                case tx_state is

                    when TX_IDLE =>
                        tx <= '1';

                        if tx_en = '1' then
                            tx_shift <= tx_i;
                            tx_state <= TX_START;
                            tx_count <= DIVISOR-1;
                        end if;

                    when TX_START =>
                        if tx_count = 0 then
                            tx <= tx_shift(0);
                            tx_bit <= 0;
                            tx_count <= DIVISOR-1;
                            tx_state <= TX_DATA;
                        else
                            tx_count <= tx_count-1;
                        end if;

                    when TX_DATA =>
                        if tx_count = 0 then

                            if tx_bit = W-1 then
                                tx <= '1';
                                tx_count <= DIVISOR-1;
                                tx_state <= TX_STOP;

                            else
                                tx_bit <= tx_bit+1;
                                tx <= tx_shift(tx_bit+1);
                                tx_count <= DIVISOR-1;
                            end if;

                        else
                            tx_count <= tx_count-1;
                        end if;

                    when TX_STOP =>
                        if tx_count = 0 then
                            tx_state <= TX_IDLE;
                        else
                            tx_count <= tx_count-1;
                        end if;

                end case;

            end if;
        end if;
    end process;


    ----------------------------------------------------------------
    -- RECEIVER
    ----------------------------------------------------------------

    process(clk)
    begin
        if rising_edge(clk) then

            -- Synchronize asynchronous input
            rx_meta <= rx;
            rx_sync <= rx_meta;
            rx_prev <= rx_sync;

            if rst = '1' then
                rx_state <= RX_IDLE;
                rx_av <= '0';
                rx_count <= 0;
                rx_bit <= 0;
                rx_meta <= '1';
                rx_sync <= '1';
                rx_prev <= '1';

            else

                rx_av <= '0';

                case rx_state is

                    when RX_IDLE =>

                        -- Detect falling edge (start bit)
                        if rx_prev = '1' and rx_sync = '0' then
                            rx_count <= DIVISOR/2-1;
                            rx_state <= RX_START;
                        end if;

                    when RX_START =>

                        if rx_count = 0 then

                            -- Verify start bit
                            if rx_sync = '0' then
                                rx_bit <= 0;
                                rx_count <= DIVISOR-1;
                                rx_state <= RX_DATA;
                            else
                                rx_state <= RX_IDLE;
                            end if;

                        else
                            rx_count <= rx_count-1;
                        end if;

                    when RX_DATA =>

                        if rx_count = 0 then

                            -- Sample data bit
                            rx_shift(rx_bit) <= rx_sync;

                            rx_count <= DIVISOR-1;

                            if rx_bit = W-1 then
                                rx_state <= RX_STOP;
                            else
                                rx_bit <= rx_bit+1;
                            end if;

                        else
                            rx_count <= rx_count-1;
                        end if;

                    when RX_STOP =>

                        if rx_count = 0 then

                            -- Validate stop bit
                            if rx_sync = '1' then
                                rx_o <= rx_shift;
                                rx_av <= '1';
                            end if;

                            rx_state <= RX_IDLE;

                        else
                            rx_count <= rx_count-1;
                        end if;

                end case;

            end if;
        end if;
    end process;
end architecture rtl;
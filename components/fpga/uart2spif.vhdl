library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity UARTSerialBridge is
    generic (
        SERIAL_W : positive := 43;
        CLK_HZ   : natural := 27_000_000;
        BAUD     : natural := 115200
    );
    port (
        clk : in std_ulogic;
        rst : in std_ulogic;

        -- UART pins
        rx : in  std_ulogic;
        tx : out std_ulogic;

        -- ASIC serial interface
        mosi : out std_ulogic;
        t_si : out std_ulogic;

        miso : in std_ulogic;
        t_so : in std_ulogic
    );
end entity UARTSerialBridge;

architecture rtl of UARTSerialBridge is

    constant BYTE_W      : positive := 8;
    constant PACKET_W    : positive := 48;
    constant PACKET_BYTES: positive := 6;
    constant UART_DIV    : positive := CLK_HZ / BAUD;

    type tx_state_t is (
        TX_COLLECT,
        TX_TRANSFER_START,
        TX_TRANSFER
    );

    type rx_state_t is (
        RX_IDLE,
        RX_CAPTURE,
        RX_UART_START,
        RX_UART_WAIT
    );

    signal tx_state : tx_state_t := TX_COLLECT;
    signal rx_state : rx_state_t := RX_IDLE;

    -- UART interface
    signal uart_rx_av : std_ulogic;
    signal uart_rx_o  : std_ulogic_vector(7 downto 0);

    signal uart_tx_en : std_ulogic := '0';
    signal uart_tx_i  : std_ulogic_vector(7 downto 0) := (others => '0');

    -- Host -> ASIC
    signal tx_assembly : std_ulogic_vector(PACKET_W-1 downto 0);
    signal tx_packet   : std_ulogic_vector(PACKET_W-1 downto 0);

    signal tx_byte_count : natural range 0 to PACKET_BYTES-1 := 0;
    signal tx_bit_count  : natural range 0 to SERIAL_W-1 := 0;

    -- ASIC -> Host
    signal rx_shift  : std_ulogic_vector(SERIAL_W-1 downto 0);
    signal rx_packet : std_ulogic_vector(PACKET_W-1 downto 0);

    signal rx_bit_count  : natural range 0 to SERIAL_W-1 := 0;
    signal rx_byte_count : natural range 0 to PACKET_BYTES-1 := 0;

    -- UART TX busy tracking
    signal uart_tx_busy : std_ulogic := '0';
    signal uart_tx_timer : natural range 0 to 12*UART_DIV := 0;

begin

    ----------------------------------------------------------------
    -- UART INSTANCE
    ----------------------------------------------------------------

    UART : entity work.UARTIf
        generic map (
            W      => 8,
            CLK_HZ => CLK_HZ,
            BAUD   => BAUD
        )
        port map (
            clk => clk,
            rst => rst,

            rx_av => uart_rx_av,
            rx_o  => uart_rx_o,

            tx_en => uart_tx_en,
            tx_i  => uart_tx_i,

            tx => tx,
            rx => rx
        );


    ----------------------------------------------------------------
    -- UART TRANSMITTER BUSY TIMER
    ----------------------------------------------------------------

    process(clk)
    begin
        if rising_edge(clk) then

            if rst = '1' then
                uart_tx_busy <= '0';
                uart_tx_timer <= 0;

            else

                if uart_tx_en = '1' then
                    uart_tx_busy <= '1';
                    uart_tx_timer <= 10*UART_DIV;

                elsif uart_tx_busy = '1' then

                    if uart_tx_timer = 0 then
                        uart_tx_busy <= '0';
                    else
                        uart_tx_timer <= uart_tx_timer - 1;
                    end if;

                end if;

            end if;
        end if;
    end process;


    ----------------------------------------------------------------
    -- HOST -> ASIC
    ----------------------------------------------------------------

    process(clk)

    begin
        if rising_edge(clk) then

            if rst = '1' then

                tx_state <= TX_COLLECT;
                tx_assembly <= (others => '0');
                tx_packet <= (others => '0');

                tx_byte_count <= 0;
                tx_bit_count <= 0;

                mosi <= '0';
                t_si <= '0';

            else

                case tx_state is

                    when TX_COLLECT =>

                        t_si <= '0';

                        if uart_rx_av = '1' then

                            if tx_byte_count = PACKET_BYTES-1 then

                                tx_packet <=
                                    tx_assembly(39 downto 0) & uart_rx_o;

                                tx_byte_count <= 0;
                                tx_state <= TX_TRANSFER_START;

                            else

                                tx_assembly <=
                                    tx_assembly(39 downto 0) & uart_rx_o;

                                tx_byte_count <= tx_byte_count + 1;

                            end if;

                        end if;


                    when TX_TRANSFER_START =>

                        t_si <= '1';
                        mosi <= tx_packet(47);

                        tx_bit_count <= 0;
                        tx_state <= TX_TRANSFER;


                    when TX_TRANSFER =>

                        if tx_bit_count = SERIAL_W-1 then

                            t_si <= '0';
                            tx_state <= TX_COLLECT;

                        else

                            tx_bit_count <= tx_bit_count + 1;

                            mosi <= tx_packet(46-tx_bit_count);

                        end if;

                end case;

            end if;
        end if;
    end process;


    ----------------------------------------------------------------
    -- ASIC -> HOST
    ----------------------------------------------------------------

    process(clk)

        variable serial_v : std_ulogic_vector(SERIAL_W-1 downto 0);
        variable packet_v : std_ulogic_vector(PACKET_W-1 downto 0);

    begin
        if rising_edge(clk) then

            if rst = '1' then

                rx_state <= RX_IDLE;

                rx_shift <= (others => '0');
                rx_packet <= (others => '0');

                rx_bit_count <= 0;
                rx_byte_count <= 0;

                uart_tx_en <= '0';
                uart_tx_i <= (others => '0');

            else

                uart_tx_en <= '0';

                case rx_state is

                    when RX_IDLE =>

                        if t_so = '1' then

                            serial_v := (others => '0');
                            serial_v(SERIAL_W-1) := miso;

                            rx_shift <= serial_v;

                            rx_bit_count <= 1;
                            rx_state <= RX_CAPTURE;

                        end if;


                    when RX_CAPTURE =>

                        if rx_bit_count = SERIAL_W-1 then

                            serial_v :=
                                rx_shift(SERIAL_W-2 downto 0) & miso;

                            packet_v := (others => '0');

                            packet_v(
                                PACKET_W-1 downto PACKET_W-SERIAL_W
                            ) := serial_v;

                            rx_packet <= packet_v;

                            rx_byte_count <= 0;
                            rx_state <= RX_UART_START;

                        else

                            rx_shift <=
                                rx_shift(SERIAL_W-2 downto 0) & miso;

                            rx_bit_count <= rx_bit_count + 1;

                        end if;


                    when RX_UART_START =>

                        if uart_tx_busy = '0' then

                            uart_tx_i <=
                                rx_packet(47 downto 40);

                            uart_tx_en <= '1';

                            rx_state <= RX_UART_WAIT;

                        end if;


                    when RX_UART_WAIT =>

                        if uart_tx_busy = '0' then

                            if rx_byte_count = PACKET_BYTES-1 then

                                rx_state <= RX_IDLE;

                            else

                                rx_packet <=
                                    rx_packet(39 downto 0) & x"00";

                                rx_byte_count <= rx_byte_count + 1;

                                rx_state <= RX_UART_START;

                            end if;

                        end if;

                end case;

            end if;
        end if;
    end process;

end architecture rtl;

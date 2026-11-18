----------------------------------------------------------------------------
-- Project		:	Generic
-- Authors		:	opilitethesmartdev
-- Description	:	UART Transmitter Interface
----------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity UARTtxIf is
    generic(
        W      : natural := 8;
        CLK_HZ : natural := 27_000_000;
        BAUD   : natural := 115200
    );
    port (
        clk : in std_ulogic;
        rst : in std_ulogic;

        tx_en : in std_ulogic;
        tx_i  : in std_ulogic_vector(W-1 downto 0);

        tx_fin : out std_ulogic;
        ack    : in std_ulogic;

        tx : out  std_ulogic
    );
end entity UARTtxIf;


architecture rtl of UARTtxIf is
    constant DIV : positive := CLK_HZ / BAUD;

    type s_t is (reset, idl, ld, st, sb, w4s, done);
    signal s, sn : s_t;
    signal en  : std_ulogic;

    signal txn, txff, txd  : std_ulogic;

    signal txi_dl : std_ulogic_vector(W-1 downto 0);

    signal tick : std_ulogic;
    signal tcnt : unsigned(W*2-1 downto 0);

    signal bitc, bitcff : unsigned(W/2-1 downto 0);
    signal data, dataff : std_ulogic_vector(W downto 0);
begin
    -- Clock divider
        clkdiv: process (clk, rst)
        begin
            if rst = '1'then
                tick <= '0';
                tcnt <= (others => '0');
            elsif rising_edge(clk) then
                tick <= '0';
                tcnt <= (others => '0');

                if en = '1' then
                    if tcnt = (DIV - 1) then
                        tcnt <= (others => '0');
                        tick <= '1';
                    else
                        tcnt <= tcnt + 1;
                    end if;
                else
                end if;
            end if;
        end process;
    
    -- Signal Primitives
        enff : entity work.sr_ff
            port map(
                clk => clk,
                s   => tx_en,
                r   => txd,
                o   => en
        );

    -- Main Processes
    ff: process (all)
    begin
        if rst = '1' then
            s <= reset;

            txff <= '1';

            bitcff <= (others => '0');
            dataff <= (others => '0');
        elsif rising_edge(clk) then
            s <= sn;

            txff <= txn;
            
            bitcff <= bitc;
            dataff <= data;

            txi_dl <= tx_i;
        end if;
    end process;

    fsm: process(all)
    begin
        sn <= s;
        case s is
            when reset => sn <= idl;
            when idl   => sn <= ld when tx_en = '1' else idl;
            when ld    => sn <= st;
            when st    => sn <= w4s;
            when sb    => sn <= done when bitcff = W else w4s;
            when w4s   => sn <= sb when tick = '1' else w4s;
            when done  => sn <= reset when ack = '1' else done;
            when others => 
        end case;
    end process fsm;

    main: process(all)
    begin
        bitc <= bitcff;
        data <= dataff;
        txn <= txff;

        txd <= '0';

        case s is
            when reset =>
                bitc <= (others => '0');
                data <= (others => '0');
            when idl =>
            when ld =>
                data <= txi_dl & '1'; -- stop bit
            when st => txn <= '0';
            when sb => 
                txn <= dataff(to_integer(bitcff));
                bitc   <= bitcff + 1;
            when done =>
                txd <= '1';
            when others => 
        end case;
    end process main;

    tx <= txff;

    tx_fin <= txd;

end architecture rtl;
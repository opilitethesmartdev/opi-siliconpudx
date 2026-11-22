----------------------------------------------------------------------------
-- Project		:	Generic
-- Authors		:	opilitethesmartdev
-- Description	:	UART Receiver Interface
----------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity UARTrxIf is
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
        ack   : in std_ulogic;

        rx : in  std_ulogic
    );
end entity UARTrxIf;


architecture rtl of UARTrxIf is
    constant DIV : positive := CLK_HZ / BAUD;

    type s_t is (reset, idl, ss, wss, w4b, sb, w4f, sf, done);
    signal s, sn : s_t;
    signal ff_clk  : std_ulogic;

    signal tick : std_ulogic;
    signal ti2  : std_ulogic; -- half offset tick
    signal tcnt : unsigned(W*2-1 downto 0);
    
    signal rx_st_dl  : std_ulogic; -- transmission start delayed

    signal rx_st  : std_ulogic; -- transmission start
    signal rx_sen : std_ulogic; -- sample enable
    
    signal rx_vt : std_ulogic;  -- valid transmission
    signal rx_fin : std_ulogic; -- operation finished

    signal shift, shiftff : std_ulogic_vector(W - 1 downto 0);
    signal scnt, scntff : unsigned(W/2-1 downto 0);

begin
    -- Clock divider
        clkdiv: process (clk, rst)
        begin
            if rst = '1'then
                tick <= '0';
                ti2 <= '0';
                tcnt <= (others => '0');
            elsif rising_edge(clk) then
                tick <= '0';
                ti2  <= '0';
                tcnt <= (others => '0');

                if rx_sen = '1' then
                    if tcnt = (DIV - 1) then
                        tcnt <= (others => '0');
                        tick <= '1';
                    elsif tcnt = (DIV/2 - 1) then
                        tcnt <= tcnt + 1;
                        ti2 <= '1';
                    else
                        tcnt <= tcnt + 1;
                    end if;
                else
                end if;
            end if;
        end process;
    
    -- Signal Primitives
        st_edge : entity work.edge
            generic map(
                polarity => "falling"
            )
            port map(
                clk => clk,
                i   => rx,
                o   => rx_st
        );
        opff : entity work.sr_ff
            port map(
                clk => clk,
                s   => rx_st,
                r   => rx_fin,
                o   => rx_sen
        );
        st_dl : entity work.n_shift1b
            generic map(
                DELAY => 1
            )
            port map(
                clk => clk,
                rst => rst,
                i   => rx_st,
                o   => rx_st_dl
        );


        ff_clk <= ti2 or rx_st;

    -- Main Processes
    ff: process (all)
    begin
        if rst = '1' then
            s <= reset;
            scntff <= (others => '1');
            shiftff <= (others => '0');
        elsif rising_edge(clk) then
            s <= sn;
            scntff <= scnt;
            shiftff <= shift;
        end if;
    end process;

    fsm: process(all)
    begin
        sn <= s;
        case s is
            when reset => 
                sn <= idl;
            when idl =>
                sn <= wss  when rx_st_dl = '1' else idl;
            when wss =>  
                if ti2 = '1' then
                    sn <= w4b when rx = '0' else reset;
                else
                    sn <= wss;
                end if; 
            when w4b => 
                sn <= sb when ti2 = '1';
            when sb => 
                sn <= w4f when scntff = W-1 else w4b;
            when w4f => sn <= sf when ti2 = '1' else w4f;
            when sf => sn <= done when rx = '1' else reset;
            when done =>
                sn <= reset when ack = '1' else done;
            when others => 
        end case;
    end process fsm;

    main: process(all)
    begin
        scnt <= scntff;
        shift <= shiftff;

        rx_fin <= '0';
        rx_av <= '0';
        rx_o  <= (others => '0');

        case s is
            when reset =>
                scnt <= (others => '0');
            when sb =>
                scnt <= scntff + 1;
                shift(to_integer(scntff)) <= rx;
            when sf =>
                rx_fin <= '1';
            when done =>
                rx_av <= '1';
                rx_o <= shiftff(W-1 downto 0);
                --rx_p <= shiftff(W+P-1);
            when others =>
        end case;
    end process main;

end architecture rtl;
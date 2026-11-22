----------------------------------------------------------------------------
-- Project		:	OPI-siliconPUdx
-- Authors		:	opilitethesmartdev
-- Description	:	UART Receiver interface
----------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.uart_pkg.all;
use work.core_pkg.all;
use work.register_pkg.all;
use work.instruction_pkg.all;

entity UartRxIf is
    generic(
        CLK_HZ : natural := 27_000_000;
        BAUD   : natural := 115200
    );
    port (
        clk: in std_ulogic;
        rst: in std_ulogic;

        -- UART Input
        rx: in std_ulogic;

        -- Application Interface
        av  : out std_ulogic;
        o   : out std_ulogic_vector(UWW - 1 downto 0);
        ack : in  std_ulogic
    );
end UartRxIf ;

architecture rtl of UartRxIf is
    type s_t is (res, idl, w4s, ss, w4b, sb, w4f, sf, fin);
    signal s, sn : s_t;

    signal rxf, rxr : std_ulogic;
    signal rx_en : std_ulogic;

    signal cdr, cd : std_ulogic;

    signal bc, bcff : unsigned(2 downto 0);
    signal d, dff : std_ulogic_vector(UWW-1 downto 0);
begin
    -- Signal Primitives
        rxf_edge : entity work.edgendr
            generic map(
                polarity => "falling"
            )
            port map(
                clk => clk,
                rst => rst,
                i   => rx,
                o   => rxf
        );
        rxen : entity work.sr_ff
            port map(
                clk => clk,
                s   => rxf,
                r   => rxr,
                o   => rx_en
        );
    
    -- Clock divider
        clkif : entity work.UartClkIf
            generic map(
                CLK_HZ => CLK_HZ,
                BAUD   => BAUD
            )
            port map(
                clk => clk,
                rst => rst,
                en  => rx_en,
                cx => open,
                cy => cd
        );


    -- FSM Processes
        ff: process(rst, clk)
        begin
            if rst = '1' then
                s <= res;

                bcff <= (others => '0');
                dff  <= (others => '0');
            elsif rising_edge(clk) then
                s <= sn;

                bcff <= bc;
                dff  <= d;
            end if;
        end process ff;

        fsm: process(all)
        begin
            case s is
                when res => sn <= idl;
                when idl => sn <= w4s when rxf = '1' else idl;
                when w4s => sn <= ss when cd = '1' else w4s;
                when ss  => sn <= w4b when rx = '0' else res;
                when w4b => sn <= sb when cd = '1' else w4b;
                when sb  => sn <= w4f when bcff = UWW - 1 else w4b;
                when w4f => sn <= sf when cd = '1' else w4f;
                when sf  => sn <= fin when rx = '1' else res;
                when fin => sn <= res when ack = '1' else fin;
                when others => sn <= s;
            end case;
        end process fsm;

        main: process(all)
        begin
            bc <= bcff;
            d <= dff;

            cdr <= '0';

            av <= '0';
            o <= (others => '0');

            case s is
                when res =>
                    cdr <= '1';
                    bc <= (others => '0');
                    d <= (others => '0');
                when idl =>
                when w4s =>
                when ss  =>
                when w4b =>
                when sb  =>
                    bc <= bcff + 1;
                    d(to_integer(bcff)) <= rx;
                when w4f =>
                when sf  =>
                    cdr <= '1';
                when fin =>
                    av <= '1';
                    o <= dff;
            end case;
        end process main;
end architecture rtl;
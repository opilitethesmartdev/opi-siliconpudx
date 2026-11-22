----------------------------------------------------------------------------
-- Project		:	Generic
-- Authors		:	opilitethesmartdev
-- Description	:	UART Transmitter Interface
----------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.uart_pkg.all;
use work.core_pkg.all;
use work.register_pkg.all;
use work.instruction_pkg.all;

entity UartTxIf is
    generic(
        CLK_HZ : natural := 27_000_000;
        BAUD   : natural := 115200
    );
    port (
        clk : in std_ulogic;
        rst : in std_ulogic;

        tx : out  std_ulogic;

        en  : in std_ulogic;
        i   : in std_ulogic_vector(UWW-1 downto 0);
        ack : in std_ulogic;
        fin : out std_ulogic
    );
end entity UartTxIf;

architecture rtl of UartTxIf is
    type s_t is (res, idl, ld, sb, w4b, w4f, fn);
    signal s, sn : s_t;

    signal txen : std_ulogic;
    signal cx : std_ulogic;

    signal id, idff : std_ulogic_vector((UWW+2)-1 downto 0);
    signal c, cff : unsigned(UWW-1 downto 0);
    signal txn, txff : std_ulogic;
begin
    -- Clock divider
        clkif : entity work.UartClkIf
            generic map(
                CLK_HZ => CLK_HZ,
                BAUD   => BAUD
            )
            port map(
                clk => clk,
                rst => rst,
                en  => txen,
                cx => cx,
                cy => open
        );


    -- FSM Processes
        ff: process(rst, clk)
        begin
            if rst = '1' then
                s <= res;
                cff <= (others => '0');
                idff <= (others => '0');
                txff <= '1';
            elsif rising_edge(clk) then
                s <= sn;
                cff <= c;
                idff <= id;
                txff <= txn;
            end if;
        end process ff;
        
        fsm: process(all)
        begin
            case s is
                when res => sn <= idl;
                when idl => sn <= ld when en = '1' else idl; 
                when ld  => sn <= sb;
                when sb  => sn <= w4f when cff = (UWW+2)-1 else w4b;
                when w4b => sn <= sb when cx = '1' else w4b;
                when w4f => sn <= fn when cx = '1' else w4f;
                when fn  => sn <= res when ack = '1' else fn;
                when others => sn <= s;
            end case;
        end process fsm;
        
        main: process(all)
        begin
            c <= cff;
            id <= idff;
            txn <= txff;

            txen <= '0';

            fin <= '0';

            case s is
                when res => 
                    txn <= '1';
                    c <= (others => '0');
                when idl => 
                when ld  => txen <= '1';
                    id <= '1' & i & '0'; -- start L | data | stop H; LSB
                when sb  => txen <= '1';
                    c <= cff + 1;
                    txn <= idff(to_integer(cff));
                when w4b => txen <= '1';
                when w4f => txen <= '1';
                when fn  => 
                    fin <= '1';
                when others =>
            end case;
        end process main;

        tx <= txff;
end architecture rtl;
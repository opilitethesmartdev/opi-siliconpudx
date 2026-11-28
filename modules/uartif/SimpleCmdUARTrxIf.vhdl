----------------------------------------------------------------------------
-- Project		:	OPI-siliconPUdx
-- Authors		:	opilitethesmartdev
-- Description	:	SImple multi-byte UART Receiver Interface
----------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.uart_pkg.all;
use work.core_pkg.all;
use work.register_pkg.all;
use work.instruction_pkg.all;

entity SimpleCmdUARTrxIf is
    generic(
        BUFD : natural := 16;
        CW   : natural := 5
    );
    port (
        clk: in std_ulogic;
        rst: in std_ulogic;
        
        -- UART RX Application Interface
        rx_av  : in  std_ulogic;
        rx_o   : in  std_ulogic_vector(UWW - 1 downto 0);
        rx_ack : out std_ulogic;

        -- Output
        msg_av  : out std_ulogic;
        msg_len : out unsigned(CW-1 downto 0);
        msg_ack : in std_ulogic;
        msg     : out uart_t(0 to BUFD-1)    
    );
end entity SimpleCmdUARTrxIf;

architecture rtl of SimpleCmdUARTrxIf is
    -- FSM Signals
        type s_t is (res, idl, st, w4b, sb, fin);
        signal s, sn : s_t;

    -- State Control signals
        signal rxv : std_ulogic;

        signal c, cff : unsigned(CW-1 downto 0);
        signal len, lenff : unsigned(CW-1 downto 0);
    
        signal bufn, buf : uart_t(0 to BUFD-1);
begin
    -- FSM Processes
        ff: process(rst, clk)
        begin
            if rst = '1' then
                s <= res;
                
                cff <= (others => '0');
                lenff <= (others => '0');

                buf <= (others => (others => '0'));
            elsif rising_edge(clk) then
                s <= sn;

                cff <= c;
                lenff <= len;

                buf <= bufn;
            end if;
        end process ff;
        
        fsm: process(all)
        begin
            case s is
                when res => sn <= idl;
                when idl => sn <= st when rx_av = '1' else idl;
                when st  => sn <= w4b when rxv = '1' else res;
                when w4b => sn <= sb when rx_av = '1' else w4b;
                when sb  => sn <= fin when cff = lenff-1 else w4b;
                when fin => sn <= res when msg_ack = '1' else fin;
                when others => sn <= s;
            end case;
        end process fsm;
        
        main: process(all)
        begin
            c <= cff;
            len <= lenff;
            bufn <= buf;

            rx_ack <= '0';
            rxv <= '0';

            msg_av <= '0';
            msg_len <= (others => '0');
            msg <= (others => (others => '0'));

            case s is
                when res =>
                    c <= (others => '0');
                    len <= (others => '0');
                    bufn <= (others => (others => '0'));
                when idl =>
                when st  =>
                    rx_ack <= '1';
                    len <= unsigned(rx_o(CW-1 downto 0));

                    rxv <= '1' when unsigned(rx_o) > 0 and unsigned(rx_o) <= to_unsigned(BUFD, UWW) else '0';
                when w4b =>
                when sb  =>
                    rx_ack <= '1';

                    c <= cff + 1;
                    bufn(to_integer(cff)) <= rx_o;
                when fin =>
                    msg_av <= '1';
                    msg_len <= lenff;
                    msg <= buf;
                when others =>
            end case;
        end process main;
end architecture rtl;
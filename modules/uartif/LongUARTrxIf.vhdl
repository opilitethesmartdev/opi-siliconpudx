----------------------------------------------------------------------------
-- Project		:	OPI-siliconPUdx
-- Authors		:	opilitethesmartdev
-- Description	:	Multi-byte UART receiver Interface
----------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.uart_pkg.all;
use work.core_pkg.all;
use work.register_pkg.all;
use work.instruction_pkg.all;

entity LongUARTrxIf is
    generic(
        EXPECTED_BYTES : natural := 6;
        WW : natural := 3
    );
    port (
        clk : in std_ulogic;
        rst : in std_ulogic;

        -- UART Rx Interface
        rx_av  : in  std_ulogic;
        rx_o   : in  std_ulogic_vector(UWW-1 downto 0);
        rx_ack : out std_ulogic;

        -- Control interface
        msg_av : out std_ulogic;
        msg_ack : in std_ulogic;

        msg : out uart_t(0 to EXPECTED_BYTES)
    );
end LongUARTrxIf ;

architecture rtl of LongUARTrxIf is
    type s_t is (res, idl, stb, w4b, fin);
    signal s, sn : s_t;

    signal dc, dcff : unsigned(WW-1 downto 0);
    signal msg_nxt : uart_t(0 to EXPECTED_BYTES);
begin
    ff : process(rst, clk)
    begin
        if rst = '1' then
            s <= res;
            dcff <= (others => '0');
            msg <= (others => (others => '0'));
        elsif rising_edge(clk) then
            s <= sn;
            dcff <= dc;
            msg <= msg_nxt;
        end if;
    end process ff;

    fsm : process(all)
    begin
        case s is
            when res => sn <= idl;
            when idl => sn <= stb when rx_av = '1' else idl;
            when stb => sn <= w4b when dcff = EXPECTED_BYTES-1 else fin;
            when w4b => sn <= stb when rx_av = '1' else w4b;
            when fin => sn <= res when msg_ack = '1' else fin;
        end case;
    end process fsm;

    main: process(all)
    begin
        dc <= dcff;
        msg_nxt <= msg;

        rx_ack <= '0';

        case s is
            when res =>
                dc <= (others => '0');
                msg_nxt <= (others => (others => '0'));
            when idl =>
            when stb =>
                msg_nxt(to_integer(dcff)) <= rx_o;
                rx_ack <= '1';
            when w4b =>
            when fin =>
                msg_av <= '1';
        end case;
    end process main;
end architecture rtl;
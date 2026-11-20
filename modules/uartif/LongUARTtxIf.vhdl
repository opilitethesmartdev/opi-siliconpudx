----------------------------------------------------------------------------
-- Project		:	OPI-siliconPUdx
-- Authors		:	opilitethesmartdev
-- Description	:	Multi-byte UART transmitter Interface
----------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.uart_pkg.all;
use work.core_pkg.all;
use work.register_pkg.all;
use work.instruction_pkg.all;

entity LongUARTtxIf is
    generic(
        SEND_BYTES : natural := 4;
        WW : natural := 3
    );
    port (
        clk : in std_ulogic;
        rst : in std_ulogic;

        -- UART Tx Interface        
        tx_en  : out std_ulogic;
        tx_i   : out std_ulogic_vector(UWW-1 downto 0);
        tx_ack : out std_ulogic;
        tx_fin : in  std_ulogic;

        -- Control interface
        msg_send : in std_ulogic;
        msg_done : out std_ulogic;

        msg : in uart_t(0 to SEND_BYTES)
    );
end LongUARTtxIf ;

architecture rtl of LongUARTtxIf is
    type s_t is (res, idl, ldm, str, w4s, ack, dly, fin);
    signal s, sn : s_t;

    signal dc, dcff : unsigned(WW-1 downto 0);
    signal msgdl, msgff, msg_nxt : uart_t(0 to SEND_BYTES);
begin
    ff : process(rst, clk)
    begin
        if rst = '1' then
            s <= res;
            dcff <= (others => '0');
            msgff <= (others => (others => '0'));
            msgdl <= (others => (others => '0'));
        elsif rising_edge(clk) then
            s <= sn;
            dcff <= dc;
            msgff <= msg_nxt;
            msgdl <= msg;
        end if;
    end process ff;

    fsm : process(all)
    begin
        case s is
            when res => sn <= idl;
            when idl => sn <= ldm when msg_send = '1' else idl;
            when ldm => sn <= str; 
            when str => sn <= fin when dcff = SEND_BYTES - 1 else w4s;
            when w4s => sn <= ack when tx_fin = '1' else  w4s;
            when ack => sn <= dly;
            when dly => sn <= str;
            when fin => sn <= res;
        end case;
    end process fsm;

    main: process(all)
    begin
        dc <= dcff;
        msg_nxt <= msgff;
        
        tx_en <= '0';
        tx_ack <= '0';
        tx_i <= (others => '0');

        msg_done <= '0';

        case s is
            when res =>
                dc <= (others => '0');
                msg_nxt <= (others => (others => '0'));
            when idl =>
            when ldm =>
                msg_nxt <= msgdl;
            when str =>
                tx_en <= '1';
                tx_i <= msgff(to_integer(dcff));
            when ack =>
                tx_ack <= '1';
            when dly =>
            when w4s =>
            when fin =>
                msg_done <= '1';
        end case;
    end process main;
end architecture rtl;
----------------------------------------------------------------------------
-- Project		:	OPI-siliconPUdx
-- Authors		:	opilitethesmartdev
-- Description	:	UART TX Streamer Interface
----------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.uart_pkg.all;
use work.core_pkg.all;
use work.register_pkg.all;
use work.instruction_pkg.all;

entity StreamUARTtxIf is
    generic(
        BUFD : natural := 16;
        CW : natural := 5
    );
    port (
        clk: in std_ulogic;
        rst: in std_ulogic;

        -- UART TX Application Interface
        tx_en  : out std_ulogic;
        tx_i   : out std_ulogic_vector(UWW-1 downto 0);
        tx_ack : out std_ulogic;
        tx_fin : in  std_ulogic;

        -- Application Interface
        str_en  : in std_ulogic;
        str_len : in unsigned(CW-1 - 1 downto 0);
        str_buf : in uart_t(0 to BUFD-1);

        str_ack  : in std_ulogic;
        str_done : out std_ulogic
    );
end entity StreamUARTtxIf;

architecture rtl of StreamUARTtxIf is
    -- FSM Signals
        type s_t is (res, idl, lda, eva, dly, str, w4b, fin);
        signal s,sn : s_t; 
    
    -- Sequential Store Signals
        signal len, lenff : unsigned(CW-1 - 1 downto 0);
        signal c, cff : unsigned(CW - 1 downto 0);
        signal bufn, buf : uart_t(0 to BUFD-1);
begin
        -- FSM Processes
            ff: process(rst, clk)
            begin
                if rst = '1' then
                    s <= res;

                    lenff <= (others => '0');
                    cff <= (others => '0');
                    buf <= (others => (others => '0'));
                elsif rising_edge(clk) then
                    s <= sn;
                    
                    lenff <= len;
                    cff <= c;
                    buf <= bufn;
                end if;
            end process ff;
            
            fsm: process(all)
            begin
                case s is
                    when res => sn <= idl;
                    when idl => sn <= lda when str_en = '1' else idl;
                    when lda => sn <= fin when (str_len = 0 or str_len > BUFD-1) else eva;
                    when eva => sn <= fin when (cff = resize(lenff - 1, CW)) else dly; 
                    when dly => sn <= str;
                    when str => sn <= w4b;
                    when w4b => sn <= eva when tx_fin = '1' else w4b;
                    when fin => sn <= res when str_ack = '1' else fin;
                    when others => sn <= s;
                end case;
            end process fsm;
            
            main: process(all)
            begin
                c <= cff;
                len <= lenff;
                bufn <= buf;

                tx_en <= '0';
                tx_ack <= '0';
                tx_i <= (others => '0');

                str_done <= '0';

                case s is
                    when res =>
                        c <= (others => '0');
                        len <= (others => '0');
                        bufn <= (others => (others => '0'));
                    when idl =>
                    when lda =>
                        len <= str_len;
                        bufn <= str_buf;
                    when eva =>
                        tx_ack <= '1';
                    when dly =>
                    when str =>
                        tx_en <= '1';
                        tx_i <= buf(to_integer(cff));

                        c <= cff + 1;
                    when w4b =>
                        --tx_ack <= tx_fin;
                    when fin =>
                        str_done <= '1';
                    when others =>
                end case;
            end process main;
    
end architecture rtl;
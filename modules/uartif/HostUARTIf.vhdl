----------------------------------------------------------------------------
-- Project		:	OPI-siliconPUdx
-- Authors		:	opilitethesmartdev
-- Description	:	Multi-byte UART Receiver Interface
----------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.uart_pkg.all;
use work.core_pkg.all;
use work.register_pkg.all;
use work.instruction_pkg.all;

entity HostUARTIf is
    generic(
        CLK_HZ : natural := 27_000_000;
        BAUD   : natural := 115200
    );
    port (
        clk : in std_ulogic;
        rst : in std_ulogic;
        
        rx : in  std_ulogic;
        tx : out std_ulogic;

        -- SRAM Interface
        ram_en   : out std_ulogic;
        ram_wren : out std_ulogic;
        ram_mask : out std_ulogic_vector(IBWIDTH - 1 downto 0);
        ram_addr : out unsigned(INSTD - 1 downto 0);
        ram_din  : out std_ulogic_vector(IBWIDTH - 1 downto 0);
        ram_dout : in std_ulogic_vector(IBWIDTH - 1 downto 0);

        -- Register bank interface
        re_cmd  : out std_ulogic_vector(1 downto 0);
        re_addr : out unsigned(REGD-1 downto 0);
        re_i : out std_ulogic_vector(WORDWIDTH-1 downto 0);
        re_o : in  std_ulogic_vector(WORDWIDTH-1 downto 0)
        
    );
end entity HostUARTIf;

architecture rtl of HostUARTIf is
    -- Constants
        constant CW : natural := 6;
        constant RBUFD : natural := 8;
        constant TBUFD : natural := 8;
    
    -- FSM Signals
        type s_t is (res, idl, lda, opf, opr, wb, w4f);
        signal s, sn : s_t;
    
    -- Internal signals
        signal cmdv : std_ulogic;
    -- Sequential Stored signals
        signal len, lenff  : unsigned(CW-1 downto 0);
        signal msgn, msgff : uart_t(0 to RBUFD-1);
        signal str, strff  : uart_t(0 to TBUFD-1);

    -- UART Rx Application If
        signal rx_av  :  std_ulogic;
        signal rx_o   :  std_ulogic_vector(UWW-1 downto 0);
        signal rx_ack :  std_ulogic;

    -- UART Tx Application If
        signal tx_en  :  std_ulogic;
        signal tx_i   :  std_ulogic_vector(UWW-1 downto 0);
        signal tx_ack :  std_ulogic;
        signal tx_fin :  std_ulogic;

    -- Compound Rx Application If
        signal msg_av  :  std_ulogic;
        signal msg_len :  unsigned(CW-1 downto 0);
        signal msg_ack :  std_ulogic;
        signal msg     :  uart_t(0 to RBUFD-1);

    -- Compound Tx Application If
        signal str_en   :  std_ulogic;
        signal str_len  :  unsigned(CW-1-1 downto 0);
        signal str_buf  :  uart_t(0 to TBUFD-1);
        signal str_ack  :  std_ulogic;
        signal str_done :  std_ulogic;
    

begin
    -- Protocol Interface
        uartif : entity work.UartIf
            generic map(
                CLK_HZ => CLK_HZ,
                BAUD   => BAUD
            )
            port map(
                clk    => clk,
                rst    => rst,
                rx     => rx,
                tx     => tx,
                rx_av  => rx_av,
                rx_o   => rx_o,
                rx_ack => rx_ack,
                tx_en  => tx_en,
                tx_i   => tx_i,
                tx_ack => tx_ack,
                tx_fin => tx_fin
        );
    -- Compound Interfaces
        rxif : entity work.SimpleCmdUARTrxIf
            generic map(
                BUFD => RBUFD,
                CW   => CW
            )
            port map(
                clk     => clk,
                rst     => rst,
                rx_av   => rx_av,
                rx_o    => rx_o,
                rx_ack  => rx_ack,
                msg_av  => msg_av,
                msg_len => msg_len,
                msg_ack => msg_ack,
                msg     => msg
        );
        txif : entity work.StreamUARTtxIf
            generic map(
                BUFD => TBUFD,
                CW   => CW
            )
            port map(
                clk      => clk,
                rst      => rst,
                tx_en    => tx_en,
                tx_i     => tx_i,
                tx_ack   => tx_ack,
                tx_fin   => tx_fin,
                str_en   => str_en,
                str_len  => str_len,
                str_buf  => str_buf,
                str_ack  => str_ack,
                str_done => str_done
        );

        -- FSM Processes
            ff: process(rst, clk)
            begin
                if rst = '1' then
                    s <= res;
                    
                    lenff <= (others => '0');
                    strff <= (others => (others => '0'));
                    msgff <= (others => (others => '0'));
                elsif rising_edge(clk) then
                    s <= sn;
                    
                    lenff <= len;
                    strff <= str;
                    msgff <= msgn;
                end if;
            end process ff;
            
            fsm: process(all)
            begin
                case s is
                    when res => sn <= idl;
                    when idl => sn <= lda when msg_av = '1' else idl;
                    when lda => sn <= opf when cmdv = '1' else res;
                    when opf => sn <= opr;
                    when opr => sn <= wb;
                    when wb  => sn <= w4f;
                    when w4f => sn <= res when str_done = '1' else w4f;
                    when others => sn <= s;
                end case;
            end process fsm;
            
            main: process(all)
                variable msg12merge : std_ulogic_vector(UWW*2-1 downto 0);
            begin
                msg12merge := msgff(1) & msgff(2);

                str <= strff;
                len <= lenff;
                msgn <= msgff;

                msg_ack <= '0';
                cmdv <= '0';
                
                ram_en <= '0';
                ram_wren <= '0';
                ram_mask <= (others => '0');
                ram_addr <= (others => '0');
                ram_din <= (others => '0');

                re_cmd <= "00";
                re_addr <= (others => '0');
                re_i <= (others => '0');
                
                str_en <= '0';
                str_ack <= '0';
                str_len <= (others => '0');
                str_buf <= (others => (others => '0'));

                case s is
                    when res =>
                        len <= (others => '0');
                        msgn <= (others => (others => '0'));
                        str_ack <= '1';
                    when idl =>
                    when lda =>
                        msg_ack <= '1';
                        len <= msg_len;
                        msgn <= msg;

                        cmdv <= '1' when --msg_len >= 2 
                                    (msg(0) = x"FA" and msg_len = 2) or
                                    (msg(0) = x"FB" and msg_len = 3) or
                                    (msg(0) = x"FC" and msg_len = 7) or
                                    (msg(0) = x"FD" and msg_len = 3)
                                        -- or msg(0) = x"FE")
                                    else '0';
                    when opf =>
                        case lenff is
                            when to_unsigned(7, CW) =>
                                if msgff(0) = x"FC" then -- instruction write
                                    ram_en <= '1';
                                    ram_wren <= '1';
                                    ram_mask <= (others => '1');
                                    ram_addr <= unsigned(msg12merge(INSTD-1 downto 0));
                                    ram_din <= msgff(3) & msgff(4) & msgff(5) & msgff(6);
                                end if;
                            when to_unsigned(3, CW) =>
                                if msgff(0) = x"FD" then -- instruction read
                                    ram_en <= '1';
                                    ram_mask <= (others => '1');
                                    ram_addr <= unsigned(msg12merge(INSTD-1 downto 0));
                                elsif msgff(0) = x"FB" then -- register write
                                    re_cmd <= "01";
                                    re_addr <= unsigned(msgff(1)(REGD-1 downto 0));
                                    re_i <= msgff(2);
                                end if;
                            when to_unsigned(2, CW) =>
                                if msgff(0) = x"FA" then -- register read
                                    re_cmd <= "10";
                                    re_addr <= unsigned(msgff(1)(REGD-1 downto 0));
                                end if;
                        end case;
                    when opr =>
                        case lenff is
                            when to_unsigned(3, CW) =>
                                if msgff(0) = x"FD" then -- instruction read
                                    str(0) <= ram_dout(UWW*4-1 downto UWW*3);
                                    str(1) <= ram_dout(UWW*3-1 downto UWW*2);
                                    str(2) <= ram_dout(UWW*2-1 downto UWW*1);
                                    str(3) <= ram_dout(UWW*1-1 downto 0);
                                end if;
                            when to_unsigned(2, CW) =>
                                if msgff(0) = x"FA" then -- register read
                                    str(0) <= re_o;
                                end if;
                        end case;
                    when wb  =>
                        case lenff is
                            when to_unsigned(3, CW) =>
                                if msgff(0) = x"FD" then -- instruction read
                                    str_en <= '1';
                                    str_len <= to_unsigned(4, CW-1);
                                    str_buf <= strff;
                                end if;
                            when to_unsigned(2, CW) =>
                                if msgff(0) = x"FA" then -- register read
                                    str_en <= '1';
                                    str_len <= to_unsigned(1, CW-1);
                                    str_buf <= strff;
                                end if;
                        end case;
                    when w4f =>
                    when others =>
                end case;
            end process main;
end architecture rtl;
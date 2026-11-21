----------------------------------------------------------------------------
-- Project		:	OPI-siliconPUdx
-- Authors		:	opilitethesmartdev
-- Description	:	Host UART Interface
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
        CLK_HZ : natural := 25_000_000
    );
    port(
        -- Fundamental signals
        clk : in std_ulogic;
        rst : in std_ulogic;

        -- UART Interface
        tx : out std_ulogic;
        rx : in  std_ulogic;

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
    constant RX_BYTES : natural := 7;
    constant TX_BYTES : natural := 4;

    type s_t is (res, idl, ldd, cmd, opf, opr, w4w, wb);
    signal s, sn : s_t;

    signal rx_av  :  std_ulogic;
    signal rx_o   :  std_ulogic_vector(UWW-1 downto 0);
    signal rx_ack :  std_ulogic;
    signal tx_en  :  std_ulogic;
    signal tx_i   :  std_ulogic_vector(UWW-1 downto 0);
    signal tx_fin :  std_ulogic;
    signal tx_ack :  std_ulogic;

    signal rx_msg_av  :  std_ulogic;
    signal rx_msg_ack :  std_ulogic;
    signal rx_msg     :  uart_t(0 to RX_BYTES-1);
    signal rxff, rxn  :  uart_t(0 to RX_BYTES-1);

    signal tx_msg_send :  std_ulogic;
    signal tx_msg_av   :  std_ulogic;
    signal tx_msg_done :  std_ulogic;
    signal tx_msg      :  uart_t(0 to TX_BYTES-1);
    signal txff, txn  :  uart_t(0 to TX_BYTES-1);

    signal wb_skip, nowb : std_ulogic;

begin
    -- UART Interface
        uartif : entity work.UARTIf
            generic map(
                W      => UWW,
                CLK_HZ => CLK_HZ,
                BAUD   => 115200
            )
            port map(
                clk    => clk,
                rst    => rst,
                rx_av  => rx_av,
                rx_o   => rx_o,
                rx_ack => rx_ack,
                tx_en  => tx_en,
                tx_i   => tx_i,
                tx_fin => tx_fin,
                tx_ack => tx_ack,
                tx     => tx,
                rx     => rx
        );
    -- Multi-byte UART Controllers
        longrxif : entity work.LongUARTrxIf
            generic map(
                EXPECTED_BYTES => RX_BYTES,
                WW             => 3
            )
            port map(
                clk     => clk,
                rst     => rst,
                
                rx_av   => rx_av,
                rx_o    => rx_o,
                rx_ack  => rx_ack,

                msg_av  => rx_msg_av,
                msg_ack => rx_msg_ack,
                msg     => rx_msg
        );


        longtxif : entity work.LongUARTtxIf
            generic map(
                SEND_BYTES => TX_BYTES,
                WW         => 3
            )
            port map(
                clk      => clk,
                rst      => rst,

                tx_en    => tx_en,
                tx_i     => tx_i,
                tx_ack   => tx_ack,
                tx_fin   => tx_fin,
                
                msg_send => tx_msg_send,
                msg_done => tx_msg_done,
                msg_av   => tx_msg_av,
                msg      => tx_msg
        );

    -- Main Process
        ff : process(rst, clk)
        begin
            if rst = '1' then
                s <= res;

                rxff <= (others => (others => '0'));
                txff <= (others => (others => '0'));

                nowb <= '0';
            elsif rising_edge(clk) then
                s <= sn;
                
                rxff <= rxn;
                txff <= txn;

                nowb <= wb_skip;
            end if;
        end process ff;

        fsm : process(all)
        begin
            case s is
                when res => sn <= idl;
                when idl => sn <= ldd when rx_msg_av = '1' else idl;
                when ldd => sn <= cmd;
                when cmd => sn <= opf;
                when opf => sn <= opr when nowb = '0' else res;
                when opr => sn <= w4w;
                when w4w => sn <= wb when tx_msg_av = '1' else w4w;
                when wb =>  sn <= res;
            end case;
        end process fsm;

        main : process(all)
            variable merged : std_ulogic_vector(UWW*2 - 1 downto 0);
        begin
            merged := rxff(1) & rxff(2);

            rxn <= rxff;
            txn <= txff;
            wb_skip <= nowb;
            
            rx_msg_ack <= '0';
            tx_msg_send <= '0';
            tx_msg <= (others => (others => '0'));

            re_cmd  <= "00";
            re_addr <= (others => '0');
            re_i    <= (others => '0');

            ram_en   <= '0';
            ram_wren <= '0';
            ram_addr <= (others => '0');
            ram_mask <= (others => '0');
            ram_din  <= (others => '0');

            case s is
                when res =>
                    rxn <= (others => (others => '0'));
                    txn <= (others => (others => '0'));
                    wb_skip <= '0';
                when idl =>
                when ldd =>
                    rx_msg_ack <= '1';
                    rxn <= rx_msg;
                when cmd =>
                    case rxff(0) is
                        when x"FA" =>
                        when x"FB" =>
                        when x"FC" =>
                        when x"FD" =>
                        when others => 
                            wb_skip <= '1';
                    end case;
                when opf =>
                    case rxff(0) is
                        when x"FA" =>
                            re_cmd <= "10";
                            re_addr <= unsigned(rxff(2)(REGD - 1 downto 0));
                        when x"FB" =>
                            re_cmd <= "01";
                            re_addr <= unsigned(rxff(2)(REGD - 1 downto 0));
                            re_i <= rxff(3);
                        when x"FC" =>
                            ram_en <= '1';
                            ram_addr <= unsigned(merged(INSTD - 1 downto 0));
                            ram_mask <= (others => '1');
                        when x"FD" =>
                            ram_en <= '1';
                            ram_wren <= '1';
                            ram_addr <= unsigned(merged(INSTD - 1 downto 0));
                            ram_mask <= (others => '1');
                            ram_din <= rxff(3) & rxff(4) & rxff(5) & rxff(6);
                        when others =>
                    end case;
                when opr =>
                    case rxff(0) is
                        when x"FA" =>
                            txn(0) <= re_o;
                        when x"FB" =>
                            txn <= (others => x"FF");
                        when x"FC" =>
                            for i in 0 to 3 loop
                                txn(i) <= ram_dout(UWW*(i+1)-1 downto UWW*i);
                            end loop;
                        when x"FD" =>
                            txn <= (others => x"FF");
                        when others =>
                    end case;
                when w4w =>
                when wb => 
                    tx_msg_send <= '1';
                    tx_msg <= txff;
            end case;
        end process main;
end architecture rtl;
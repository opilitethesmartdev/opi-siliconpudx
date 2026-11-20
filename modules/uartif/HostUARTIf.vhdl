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
    constant TX_BYTES : natural := 6;

    type s_t is (res, idl, ldd, opf, opr, wb);
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
    signal rx_msg     :  uart_t(0 to RX_BYTES);
    signal rxff, rxn  :  uart_t(0 to RX_BYTES);


    signal tx_msg_send :  std_ulogic;
    signal tx_msg_done :  std_ulogic;
    signal tx_msg      :  uart_t(0 to TX_BYTES);
    --signal txff, txn  :  uart_t(0 to TX_BYTES);

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
                EXPECTED_BYTES =>RX_BYTES,
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
                msg      => tx_msg
        );

    -- Main Process
        ff : process(rst, clk)
        begin
            if rst = '1' then
                s <= res;

                rxff <= (others => (others => '0'));
                --txff <= (others => (others => '0'));
            elsif rising_edge(clk) then
                s <= sn;
                
                rxff <= rxn;
                --txff <= txn;
            end if;
        end process ff;

        fsm : process(all)
        begin
            case s is
                when res => sn <= idl;
                when idl => sn <= ldd when rx_msg_av = '1' else idl;
                when ldd => sn <= opf;
                when opf => sn <= opr;
                when opr => sn <= wb;
                when wb =>  sn <= res;
            end case;
        end process fsm;

        main : process(all)
        begin
            rxn <= rxff;
            --txn <= txff;
            
            rx_msg_ack <= '0';

            case s is
                when res =>
                    rxn <= (others => (others => '0'));
                    --txn <= (others => (others => '0'));
                when idl =>
                when ldd =>
                    rx_msg_ack <= '1';
                    rxn <= rx_msg;
                when opf =>
                when opr =>
                when wb => 
            end case;
        end process main;
end architecture rtl;
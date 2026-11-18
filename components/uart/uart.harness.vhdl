----------------------------------------------------------------------------
-- Project		:	OPI-siliconPUdx
-- Authors		:	opilitethesmartdev
-- Description	:	FPGA harness for UART
----------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.core_pkg.all;
use work.register_pkg.all;
use work.instruction_pkg.all;

entity uart_harness is
    port(
        -- Fundamental signals
        clk : in std_ulogic;
        rst : in std_ulogic;

        -- UART
        rx : in  std_ulogic;
        tx : out std_ulogic;

        -- FPGA LED
        led : out std_ulogic_vector(5 downto 0)
    );

end entity uart_harness;

architecture rtl of uart_harness is
    type s_t is (reset, idle, apply, resp, await);
    signal s, sn : s_t;

    signal rx_av  :  std_ulogic;
    signal rx_o   :  std_ulogic_vector(7 downto 0);
    signal rx_ack :  std_ulogic;
    signal tx_en  :  std_ulogic;
    signal tx_i   :  std_ulogic_vector(7 downto 0);
    signal tx_fin :  std_ulogic;
    signal tx_ack :  std_ulogic;
    
    signal rst_n   :  std_ulogic;

    signal ledn : std_ulogic_vector(5 downto 0);
begin
    uartif : entity work.UARTIf
        generic map(
            W      => 8,
            CLK_HZ => 27_000_000,
            BAUD   => 115200
        )
        port map(
            clk    => clk,
            rst    => rst_n,

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

    ff : process(rst_n, clk)
    begin
        if rst_n = '1' then
            s <= reset;
            led <= (others => '1'); -- active low
        elsif rising_edge(clk) then
            s <= sn;
            led <= ledn;
        end if;
    end process ff;

    fsm : process(all)
    begin
        sn <= s;
        case s is
            when reset => sn <= idle;
            when idle =>  sn <= apply when rx_av = '1' else idle;
            when apply => sn <= resp;
            when resp  => sn <= await;
            when await => sn <= reset when tx_fin = '1' else await;
            when others =>
        end case;
    end process fsm;

    main : process(all)
    begin
        rx_ack <= '0';
        tx_ack <= '0';
        
        tx_en <= '0';
        tx_i <= x"00";

        ledn <= led;

        case s is
            when reset => 
                rx_ack <= '1';
                tx_ack <= '1';
            when apply =>
                ledn <= not rx_o(5 downto 0); -- active low
            when resp =>
                tx_en <= '1';
                tx_i <= x"67";
            when others =>
        end case;
    end process main;

    rst_n <= not rst;

end architecture rtl;
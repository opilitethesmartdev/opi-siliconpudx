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
    type s_t is (reset, idle, apply);
    signal s, sn : s_t;

    signal rx_av :  std_ulogic;
    signal rx_o  :  std_ulogic_vector(7 downto 0);
    signal rx_p  :  std_ulogic;
    signal ack   :  std_ulogic;
    
    signal rst_n   :  std_ulogic;

    signal ledn : std_ulogic_vector(5 downto 0);
begin
    i_UARTrxIf : entity work.UARTrxIf
        generic map(
            W      => 8,
            P      => 0,
            CLK_HZ => 27_000_000,
            BAUD   => 115200
        )
        port map(
            clk   => clk,
            rst   => rst_n,
            rx_av => rx_av,
            rx_o  => rx_o,
            rx_p  => rx_p,
            ack   => ack,
            rx    => rx
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
        sn <= reset;
        case s is
            when reset => sn <= idle;
            when idle =>  sn <= apply when rx_av = '1' else idle;
            when others =>
        end case;
    end process fsm;

    main : process(all)
    begin
        ack <= '0';
        ledn <= led;

        case s is
            when reset => 
                ack <= '1';
            when apply =>
                ledn <= not rx_o(5 downto 0); -- active low
            when others =>
        end case;
    end process main;

    rst_n <= not rst;

end architecture rtl;
----------------------------------------------------------------------------
-- Project		:	OPI-siliconPUdx
-- Authors		:	opilitethesmartdev
-- Description	:	FPGA test entity
----------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.core_pkg.all;
use work.register_pkg.all;
use work.instruction_pkg.all;

entity test_fpga is
    port(
        -- Fundamental signals
        clk : in std_ulogic;
        rst : in std_ulogic;

        -- FPGA LED
        led : out std_ulogic_vector(5 downto 0)
    );

end entity test_fpga;

architecture rtl of test_fpga is
    --signal rst_n   :  std_ulogic;
    --signal ledn : std_ulogic_vector(5 downto 0);

    signal divclk : unsigned(31 downto 0);
    signal clk_1 : std_ulogic;

    signal ledcnt : unsigned(2 downto 0);
begin
    clkdiv : process (clk, rst)
    begin
        if rst = not('1') then
            divclk <= (others => '0');
        elsif rising_edge(clk) then
            if divclk = 26_999_999 then
                clk_1 <= '1';
                divclk <= (others => '0');
            else            
                clk_1 <= '0';
                divclk <= divclk + 1;
            end if;
        end if;
    end process;

    led_seq : process (clk_1, rst)
    begin
        if rst = not('1') then
            led <= (others => '1'); -- active low
            ledcnt <= (others => '0');
        elsif rising_edge(clk_1) then
            led <= (others => '1');
            led(to_integer(ledcnt)) <= '0'; 

            if ledcnt = 5 then
                ledcnt <= (others => '0');
            else
                ledcnt <= ledcnt + 1;
            end if;
        end if;
    end process;

end architecture rtl;
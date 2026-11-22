----------------------------------------------------------------------------
-- Project		:	OPI-siliconPUdx
-- Authors		:	opilitethesmartdev
-- Description	:	UART Clock Generator
----------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.uart_pkg.all;
use work.core_pkg.all;
use work.register_pkg.all;
use work.instruction_pkg.all;

entity UartClkIf is
    generic(
        CLK_HZ : natural := 27_000_000;
        BAUD   : natural := 115200
    );
    port (
        clk : in std_ulogic;
        rst : in std_ulogic;
        en  : in std_ulogic;

        cx : out std_ulogic;
        cy : out std_ulogic
    );
end entity UartClkIf;

architecture rtl of UartClkIf is
    signal cdc : unsigned(15 downto 0);
begin
    seq : process(rst, clk)
        begin
            if rst = '1' then
                cdc <= (others => '0');
                cx <= '0';
                cy <= '0';
            elsif rising_edge(clk) then
                cx <= '0';
                cy <= '0';

                if en = '1' then
                    if cdc = (CLK_HZ / BAUD)-1 then
                        cdc <= (others => '0');
                        cx <= '1';
                    else                
                        if cdc = ((CLK_HZ / BAUD)/2-1) then
                            cy <= '1';
                        end if;
                        
                        cdc <= cdc + 1;
                    end if;
                else
                    cdc <= (others => '0'); -- auto-reset on en = 0
                end if;
            end if;
        end process seq;
end architecture rtl;
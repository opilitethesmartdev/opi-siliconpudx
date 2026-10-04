----------------------------------------------------------------------------
-- Project		:	Generic
-- Authors		:	opilitethesmartdev
-- Description	:	Clock divider
----------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity clkdiv is
    generic(
        CLOCKDIV : natural := 10;
        C_WIDTH : natural := 4
    );
    port(
        clkin  : in std_ulogic;
        rst    : in std_ulogic;
        clkout : out std_ulogic;
        clkon  : out std_ulogic; -- clock on signal
        advp    : out std_ulogic; -- pre-rising signal
        advn    : out std_ulogic -- pre-falling signal
    );
end entity clkdiv;

architecture rtl of clkdiv is
    signal cnt : unsigned(C_WIDTH - 1 downto 0);
    signal ci : std_ulogic := '0';
begin
    seq: process(rst, clkin)
    begin
        if rst = '1' then
            cnt <= (others => '0');
            advp <= '0';
            advn <= '0';
            clkon <= '0';
        elsif rising_edge(clkin) then
            advp <= '0';
            advn <= '0';

            if cnt = CLOCKDIV - 1 then  
                clkon <= '1';
                cnt <= (others => '0');
                ci <= not ci;
            else
                if cnt = CLOCKDIV - 2 then
                    if ci = '0' then 
                        advp <= '1';
                    else
                        advn <= '1';
                    end if;
                end if;

                cnt <= cnt + 1;
            end if;
        end if;
    end process;
    
    clkout <= ci;
end architecture rtl;
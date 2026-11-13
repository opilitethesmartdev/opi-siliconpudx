----------------------------------------------------------------------------
-- Project		:	OPI-SiliconPUdx
-- Authors		:	opilitethesmartdev
-- Description	:	Clock Interface
----------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.core_pkg.all;

entity ClockIf is
    port(
        clki : in std_ulogic;
        rst  : in std_ulogic;
        en   : in std_ulogic;
        clko : out clk_rec_t
    );
end entity ClockIf;

architecture rtl of ClockIf is
    signal cnt : unsigned(C_WIDTH - 1 downto 0);
    signal ci, ci_n, clki_n : std_ulogic := '0';
    
    signal clkon  : std_ulogic; -- clock on signal
    signal advp   : std_ulogic; -- pre-rising signal
    signal advn   : std_ulogic; -- pre-falling signal
begin
    seq: process(rst, clki)
    begin
        if rst = '1' then
            cnt <= (others => '0');
            advp <= '0';
            advn <= '0';
            clkon <= '0';
        elsif rising_edge(clki) then
            advp <= '0';
            advn <= '0';

            if en = '1' then
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
        end if;
    end process;

    ci_n <= not ci;
    clki_n <= not clki;
    
    clko <= (i_n => clki_n, o => ci, o_n => ci_n, en => clkon, advp => advp, advn => advn);
end architecture rtl;
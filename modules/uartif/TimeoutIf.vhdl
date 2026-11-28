----------------------------------------------------------------------------
-- Project		:	OPI-siliconPUdx
-- Authors		:	opilitethesmartdev
-- Description	:	Timeout Interface
----------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity TimeoutIf is
    generic(
        TICKS : natural := 1000
    );
    port (
        clk: in std_ulogic;
        rst: in std_ulogic;

        en : in std_ulogic;
        fn : in std_ulogic;

        timeout : out std_ulogic      
    );
end entity TimeoutIf;

architecture Rtl of TimeoutIf is
    signal i : unsigned(15 downto 0);

    signal ffr, ffo : std_ulogic;
begin
    srff : entity work.sr_ff
        port map(
            clk => clk,
            s   => en,
            r   => ffr,
            o   => ffo
    ); ffr <= rst or fn;


    seq: process(rst, clk) 
    begin
        if rst = '1' then
            i <= (others => '0');
            timeout <= '0';
        elsif rising_edge(clk) then
            if ffo = '1' then
                if i = to_unsigned(TICKS, i'length)-1 then
                    timeout <= '1';
                else
                    timeout <= '0';

                    i <= i+1;
                end if;
            else
                timeout <= '0';
                i <= (others => '0');
            end if;
        end if;
    end process seq;
end architecture;
----------------------------------------------------------------------------
-- Project		:	OPI-SiliconPUdx
-- Authors		:	opilitethesmartdev
-- Description	:	Reset synchronizer
----------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity rst_sync is
    generic(
        POL: string := "ah"
    );
    port (
        clk: in std_ulogic;
        
        ri : in  std_ulogic;
        ro : out std_ulogic        
    );
end entity rst_sync;

architecture rtl of rst_sync is
    signal synch, metah : std_ulogic := '1';
    signal syncl, metal : std_ulogic := '0';
begin

    ah: if POL = "ah" generate
        seq: process(ri, clk)
        begin
            if ri = '1' then 
                synch <= '1';
                metah <= '1';
            elsif rising_edge(clk) then
                metah <= '0';
                synch <= metah;
            end if;
        end process seq;

        ro <= synch;
    end generate;

    al: if POL = "al" generate
        seq: process(ri, clk)
        begin
            if ri = '0' then 
                syncl <= '0';
                metal <= '0';
            elsif rising_edge(clk) then
                metal <= '1';
                syncl <= metal;
            end if;
        end process seq;

        ro <= syncl;
    end generate;
end architecture rtl;
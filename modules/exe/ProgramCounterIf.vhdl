----------------------------------------------------------------------------
-- Project		:	OPI-siliconPUdx
-- Authors		:	opilitethesmartdev
-- Description	:	Program Counter Interface
----------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.core_pkg.all;
use work.register_pkg.all;
use work.instruction_pkg.all;

entity ProgramCounterIf is
    port (
        clk : in std_ulogic;
        rst : in std_ulogic;
        en  : in std_ulogic;
        
        cmd : in std_ulogic_vector(1 downto 0); -- [jump][skip]; and = ovr
        ovr : in unsigned(INSTD - 1 downto 0);

        pc : out unsigned(INSTD - 1 downto 0)
    );
end entity ProgramCounterIf;

architecture rtl of ProgramCounterIf is
    --signal i1, i2 : unsigned(INSTD - 1 downto 0);
    signal i1 : unsigned(INSTD - 1 downto 0);
begin   
    seq : process (clk, rst)
    begin
        if rst = '1' then
            i1 <= (others => '0');
            --i2 <= (others => '0');
        elsif rising_edge(clk) then
            if en = '1' then
                case cmd is
                    when "10" => 
                        i1 <= i1 + 1;
                        --i2 <= i1;
                    when "01" => 
                        i1 <= i1 + 2;
                        --i2 <= i1;
                    when "11" => 
                        i1 <= ovr;                        
                        --i2 <= ovr;
                    when others =>
                end case;
            end if;
        end if;
    end process seq;

    pc <= i1;--i2;
end architecture rtl;
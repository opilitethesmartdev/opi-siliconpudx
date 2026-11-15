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
        --en  : in std_ulogic;
        
        cmd : in std_ulogic_vector(1 downto 0); -- [jmp][skip]; and = ovr
        ovr : in unsigned(INSTD - 1 downto 0);

        pc : out unsigned(INSTD - 1 downto 0)
    );
end entity ProgramCounterIf;

architecture rtl of ProgramCounterIf is
    signal i1 : unsigned(INSTD - 1 downto 0);
begin   
    seq : process (clk, rst)
    begin
        if rst = '1' then
            i1 <= (others => '0');
        elsif rising_edge(clk) then
            if (or cmd) = '1' then
                case cmd is
                    when "10" => 
                        i1 <= i1 + 1;
                    when "01" => 
                        i1 <= i1 + 2;
                    when "11" => 
                        i1 <= ovr;    
                    when others =>
                end case;
            end if;
        end if;
    end process seq;

    pc <= i1;
end architecture rtl;
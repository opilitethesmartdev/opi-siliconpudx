----------------------------------------------------------------------------
-- Project		:	OPI-siliconPUdx
-- Authors		:	opilitethesmartdev
-- Description	:	Program Counter interface
----------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.core_pkg.all;
use work.register_pkg.all;
use work.instruction_pkg.all;

entity ProgramCounterIf is
    port(
        -- Fundamental signals
        clk : in std_ulogic; -- fast clock
        rst : in std_ulogic;

        -- Control signals
        cmd : in std_ulogic_vector(1 downto 0); --[nxt][skip], and = ovr
        ovr : in unsigned(INSTD - 1 downto 0);
        pc : out unsigned(INSTD - 1 downto 0)
    );

end entity ProgramCounterIf;

architecture rtl of ProgramCounterIf is
    signal pci : unsigned(INSTD - 1 downto 0);
begin
    seq: process(clk, rst) 
    begin
        if rst = '1' then
            pci <= (others => '0');
            pc <= (others => '0');
        elsif rising_edge(clk) then
            case (cmd) is
                when "10" =>
                    pci <= pci + 1;
                when "01" =>
                    pci <= pci + 2;
                when "11" =>
                    pci <= ovr;
                when others =>
            end case;

            pc <= pci;
        end if;
    end process seq;
end architecture rtl;
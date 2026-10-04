----------------------------------------------------------------------------
-- Project		:	OPI-siliconPUdx
-- Authors		:	opilitethesmartdev
-- Description	:	Program counter interface
----------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.instruction_pkg.all;

entity ProgramCounterIf is
    port(
        -- Fundamental signals
        clk : in std_ulogic;
        rst : in std_ulogic;
        en : in std_ulogic;

        -- Control signals
        ctrl : in std_ulogic_vector(1 downto 0); -- [en][ovr], and ctrl => skip
        ovr : in unsigned(INST_DEPTH - 1 downto 0);

        -- Output
        pc : out unsigned(INST_DEPTH - 1 downto 0)
    );
end entity ProgramCounterIf;

architecture v0 of ProgramCounterIf is
    signal pcint : unsigned(INST_DEPTH - 1 downto 0) := (others => '0');
begin
    seq : process(rst, en, clk)
    begin
        if rst = '1' then
            pcint <= (others => '0');
        elsif rising_edge(clk) then
                
            if en = '1' then
                case (ctrl) is
                    when "01" =>
                        pcint <= ovr;
                    when "10" =>
                        pcint <= pcint + 1;
                    when "11" =>
                        pcint <= pcint + 2;
                    when others =>
                end case;
            end if;
        end if;
    end process seq;   

    pc <= pcint;  

end architecture v0;
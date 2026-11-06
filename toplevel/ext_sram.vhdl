----------------------------------------------------------------------------
-- Project		:	OPI-siliconPUdx
-- Authors		:	opilitethesmartdev
-- Description	:	External SRAM bank
----------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--use work.core_pkg.all;
--use work.register_pkg.all;
--use work.instruction_pkg.all;

entity ext_sram is
    generic(
        WORDWIDTH : natural := 32;
        WORDDEPTH : natural := 10
    );
    port(        
        clk : in std_ulogic;
        en  : in std_ulogic;
        wren : in std_ulogic;
        mask : in std_ulogic_vector(WORDWIDTH - 1 downto 0);
        addr : in unsigned(WORDDEPTH - 1 downto 0);
        din  : in std_ulogic_vector(WORDWIDTH - 1 downto 0);
        dout : out std_ulogic_vector(WORDWIDTH - 1 downto 0)
    );
end entity ext_sram;

architecture bhv of ext_sram is
    type ram_t is array(0 to 2**WORDDEPTH - 1) of std_ulogic_vector(WORDWIDTH - 1 downto 0);

    signal ram : ram_t := (others => x"00000000");
    signal addri : unsigned(WORDDEPTH - 1 downto 0);
begin
    seq: process(clk)
    begin
        if rising_edge(clk) then
            if en = '1' then
                if wren = '1' then
                    ram(to_integer(addr)) <= din and mask;
                else
                    addri <= addr;
                    dout <= ram(to_integer(addri)) and mask;
                end if;
            end if;
        end if;
    end process seq;
end architecture bhv;
----------------------------------------------------------------------------
-- Project		:	OPI-siliconPUdx
-- Authors		:	opilitethesmartdev
-- Description	:	Register storage bank
----------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.register_pkg.all;

entity RegisterBank is
    port(
        -- Fundamental signals
        clk : in std_ulogic;
        rst : in std_ulogic;

        -- rw interface
        cmd  : in std_ulogic_vector(1 downto 0);    -- read / write cmd ([read][write], xor = enable)
        addr : in unsigned(REGDEPTH - 1 downto 0);
        regi : in std_ulogic_vector(REGWIDTH - 1 downto 0);
        rego : out std_ulogic_vector(REGWIDTH - 1 downto 0)
    );
end entity RegisterBank;

architecture bhv of RegisterBank is
    signal regs : reg_array_t;
begin
    seq : process(rst, clk)
    begin
        if rst = '1' then
            regs <= (others => REGNULL);
        elsif rising_edge(clk) then
            if cmd = "01" then
                regs(to_integer(addr)) <= regi;
            end if;
        end if;
    end process seq;

    rego <= regs(to_integer(addr)) when cmd = "10" else REGNULL;
end architecture bhv;
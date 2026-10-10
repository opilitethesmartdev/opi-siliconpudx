----------------------------------------------------------------------------
-- Project		:	OPI-siliconPUdx
-- Authors		:	opilitethesmartdev
-- Description	:	Address Resolution Engine
--                  Recursively resolves address references along configured pointer depth
----------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.core_pkg.all;
use work.register_pkg.all;
use work.instruction_pkg.all;

entity AddressResolutionEngine is
    port(
        -- Fundamental signals
        clk : in std_ulogic;
        rst : in std_ulogic;
        en  : in std_ulogic;

        -- Input configuration
        depth : in unsigned(IPTRW - 1 downto 0);
        param : in std_ulogic_vector(PARAMW - 1 downto 0);

        -- Register interface
        rden : out std_ulogic;
        addr : out unsigned(REGD - 1 downto 0);
        din  : in  std_ulogic_vector(WORDWIDTH - 1 downto 0);

        -- Output
        fin : out std_ulogic;
        tar : out std_ulogic_vector(WORDWIDTH - 1 downto 0)
    );

end entity AddressResolutionEngine;

architecture rtl of AddressResolutionEngine is 
    signal intd : unsigned(IPTRW - 1 downto 0);
    signal inten : std_ulogic;
    signal d, done : std_ulogic;
    signal finrst : std_ulogic;
begin   
    enff : entity work.sr_ff
        port map(
            clk => clk,
            s   => en,
            r   => d,
            o   => inten
    ); d <= done or rst;

    finff : entity work.sr_ff
        port map(
            clk => clk,
            s   => d,
            r   => finrst,
            o   => fin
    ); finrst <= inten or rst;

    seq : process (clk, rst)
        variable int : unsigned(WORDWIDTH - 1 downto 0) := (others => '0');
    begin
        if rst = '1' then
            int := (others => '0');
            intd <= (others => '0');
            tar <= (others => '0');
            done <= '0';
        elsif rising_edge(clk) then
            done <= '0';
            if inten = '1' then
                if intd = 0 then
                    int := unsigned(param);
                else
                    int := unsigned(din);
                end if;

                if intd = depth then
                    tar <= std_ulogic_vector(int);
                    done <= '1';
                else
                    intd <= intd + 1;
                    rden <= '1';
                    addr <= int;
                end if;
            end if;
        end if;
    end process seq;
end architecture rtl;
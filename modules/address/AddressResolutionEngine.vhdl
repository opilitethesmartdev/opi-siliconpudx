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
    signal int : unsigned(WORDWIDTH - 1 downto 0);
    signal intd : unsigned(IPTRW - 1 downto 0);
    signal d, finrst : std_ulogic;
begin  
    fin <= d;
    --finff : entity work.sr_ff
    --    port map(
    --        clk => clk,
    --        s   => d,
    --        r   => finrst,
    --        o   => fin
    --); finrst <= en or rst;

    seq : process (clk, rst)
    begin
        if rst = '1' then
            intd <= (others => '0');
            tar <= (others => '0');
            addr <= (others => '0');
            rden <= '0';
            d <= '0';
        elsif rising_edge(clk) then
            rden <= '0';
            if en = '1' and d = '0' then
                tar <= std_ulogic_vector(int);

                if intd = depth then
                    d <= '1';
                else
                    intd <= intd + 1;
                    rden <= '1';
                    addr <= int(REGD-1 downto 0);
                end if;
            end if;
        end if;
    end process seq;

    seq_n : process(clk, rst)
    begin
        if rst = '1' then
            int <= (others => '0');
        elsif falling_edge(clk) then
            if en = '1' then
                if intd = 0 then
                    int <= unsigned(param);
                else
                    int <= unsigned(din);
                end if;
            end if;
        end if;
    end process seq_n;
end architecture rtl;
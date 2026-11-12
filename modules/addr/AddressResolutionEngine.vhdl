----------------------------------------------------------------------------
-- Project		:	OPI-siliconPUdx
-- Authors		:	opilitethesmartdev
-- Description	:	Address Resolution Engine
----------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.core_pkg.all;
use work.register_pkg.all;
use work.instruction_pkg.all;

entity AddressResolutionEngine is
    port (
        -- Fundamental signals
        clk : in std_ulogic;
        rst : in std_ulogic;
        en  : in std_ulogic;

        -- Register singular access
        rd : out std_ulogic;
        addr : out unsigned(REGD - 1 downto 0);        
        din : in std_ulogic_vector(WORDWIDTH - 1 downto 0);

        -- Input/Output
        i_d : in  unsigned(IPTRW - 1 downto 0);
        i_p : in  std_ulogic_vector(PARAMW - 1 downto 0);
        o_p : out std_ulogic_vector(PARAMW - 1 downto 0)
    );
end entity AddressResolutionEngine;

architecture rtl of AddressResolutionEngine is
    signal ip, cp : unsigned(PARAMW - 1 downto 0);
    signal cd : unsigned(IPTRW - 1 downto 0);
    signal enaff, ena, fin, enffr : std_ulogic;
begin
    enff : entity work.sr_ff
        port map(
            clk => clk,
            s   => en,
            r   => enffr,
            o   => enaff
    ); enffr <= rst or fin;
    ena <= en or enaff;

    seq : process(rst,clk)
    begin
        if rst = '1' then
            cd <= (others => '0');
            ip <= (others => '0');
            cp <= (others => '0');
            o_p <= (others => '0');
        elsif rising_edge(clk) then
            fin <= '0';
            if ena = '1' then
                ip <= unsigned(i_p);
                if i_d = cd then
                    fin <= '1';
                    o_p <= std_ulogic_vector(cp);
                else
                    rd <= '1';

                    if cd = 0 then
                        cp <= ip;
                    else
                        cp <= unsigned(din);
                    end if;

                    addr <= cp;
                    cd <= cd + 1;
                end if;
            end if;
        end if;
    end process seq;
    
end architecture rtl;
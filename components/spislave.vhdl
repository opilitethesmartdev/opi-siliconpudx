----------------------------------------------------------------------------
-- Project		:	Generic
-- Authors		:	opilitethesmartdev
-- Description	:	Data deserializer
----------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

use work.core_pkg.all;
use work.register_pkg.all;
use work.instruction_pkg.all;

entity spislave is
    port(
        clk : in std_ulogic;
        rst : in std_ulogic;
        
        en  : in std_ulogic_vector(1 downto 0); -- [in][out] -- enable transfer

        mosi : in std_ulogic;
        miso : out std_ulogic;

        dmiso : in  std_ulogic_vector(WORDWIDTH*2 - 1 downto 0); -- assert en(1)
        dmosi : out std_ulogic_vector(WORDWIDTH*3 - 1 downto 0)  -- assert en(0)
    );
end entity spislave;

architecture rtl of spislave is
    signal soload : std_ulogic;
    signal sishift : std_ulogic_vector(WORDWIDTH*3 - 1 downto 0);
    signal soshift : std_ulogic_vector(WORDWIDTH*2 - 1 downto 0);
begin
    seq : process(rst, clk)
    begin
        if rst = '1' then
            soload <= '0';

            sishift <= (others => '0');
            soshift <= (others => '0');

            miso <= '0';
            dmosi <= (others => '0');
        elsif rising_edge(clk) then
            if en(0) = '1' then
                sishift <= sishift(WORDWIDTH*3 - 2 downto 0) & mosi;
            else
                dmosi <= sishift;
            end if;
            
            soload <= en(1);
            if en(1) = '1' and soload = '0' then
                soshift <= dmiso;
            elsif soload = '1' then
                miso <= soshift(WORDWIDTH*2 - 1);
                soshift <= soshift(WORDWIDTH*2 - 2 downto 0) & '0';
            end if;

        end if;
    end process seq;
end architecture rtl;
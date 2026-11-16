----------------------------------------------------------------------------
-- Project		:	OPI-siliconPUdx
-- Authors		:	opilitethesmartdev
-- Description	:	Accumulator Interface
----------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.core_pkg.all;
use work.register_pkg.all;
use work.instruction_pkg.all;

entity AccumulatorIf is
    port (
        clk : in std_ulogic;
        rst : in std_ulogic;

        rw : in  std_ulogic_vector(1 downto 0); --[read][write]; xor = en; and = soft rst
        d_i : in  std_ulogic_vector(WORDWIDTH - 1 downto 0);
        d_o : out std_ulogic_vector(WORDWIDTH - 1 downto 0)
    ) ;
end AccumulatorIf ;

architecture rtl of AccumulatorIf is
    signal reg : std_ulogic_vector(WORDWIDTH - 1 downto 0);
begin
    seq: process(rst, clk)
    begin
        if rst = '1' then
            reg <= (others => '0');
            d_o  <= (others => '0');
        elsif rising_edge(clk) then
            case rw is
                when "10" => d_o <= reg;
                when "01" => reg <= d_i;
                when "11" => reg <= (others => '0');
                when others =>
            end case;
        end if;
    end process seq;
end architecture rtl;
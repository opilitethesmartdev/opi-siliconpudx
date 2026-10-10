----------------------------------------------------------------------------
-- Project		:	OPI-siliconPUdx
-- Authors		:	opilitethesmartdev
-- Description	:	Instruction Bank
----------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.core_pkg.all;
use work.register_pkg.all;
use work.instruction_pkg.all;

entity RegisterBank is
    port(
        -- Fundamental signals
        clk : in std_ulogic;
        rst : in std_ulogic;

        -- Data interface
        cmd : in std_ulogic_vector(2 downto 0); -- [sel][read][write]
        addr : in unsigned(REGD - 1 downto 0);
        din  : in std_ulogic_vector(WORDWIDTH - 1 downto 0);
        dout : out std_ulogic_vector(WORDWIDTH - 1 downto 0);

        iodirmask : in  std_ulogic_vector(2**MMIOD - 1 downto 0) -- read = 0
    );

end entity RegisterBank;

architecture rtl of RegisterBank is
    
    signal regs  : reg_array_t(0 to 2**REGD - 1)  := (others => (others => '0'));
    signal regio : reg_array_t(0 to 2**MMIOD - 1) := (others => (others => '0'));
begin
    seq: process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                regs <= (others => (others => '0'));

                regiodefault : for rg in 2**MMIOD - 1 downto 0 loop
                    if(iodirmask(rg) = '1') then
                        regio(rg) <= (others => '0');
                    end if;
                end loop;
            else
                case (cmd) is
                    when "001" =>
                        regs(to_integer(addr)) <= din;
                    when "101" =>
                        if(iodirmask(to_integer(addr(MMIOD - 1 downto 0))) = '0') then
                            regio(to_integer(addr(MMIOD - 1 downto 0))) <= din;
                        end if;
                    when others =>
                end case;
            end if;
        end if;
    end process seq;

    dout <= regs(to_integer(addr))  when cmd = "010" 
       else regio(to_integer(addr)) when cmd = "110" 
       else (others => '0');
end architecture rtl;
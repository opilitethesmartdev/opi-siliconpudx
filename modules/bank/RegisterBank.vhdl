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

        iodirmask : in  std_ulogic_vector(MMIOD**2 - 1 downto 0) -- read = 0
    );

end entity RegisterBank;

architecture rtl of RegisterBank is
    signal regdef   : reg_array_t(REGD - 1 downto 0)  := (others => (others => '0'));
    signal regiodef : reg_array_t(MMIOD - 1 downto 0) := (others => (others => '0'));
    
    signal regs  : reg_array_t(REGD - 1 downto 0)  := (others => (others => '0'));
    signal regio : reg_array_t(MMIOD - 1 downto 0) := (others => (others => '0'));
begin
    seq: process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                regs <= regdef;

                regiodefault : for rg in MMIOD**2 - 1 downto 0 loop
                    if(iodirmask(rg) = '1') then
                        regio(rg) <= regiodef(rg);
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
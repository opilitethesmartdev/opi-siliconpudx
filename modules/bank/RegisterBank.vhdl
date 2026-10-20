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
    signal regio : reg_array_t(0 to 2**MMIOD - 1) := (others => (others => '0'));
    signal io_out : std_ulogic_vector(WORDWIDTH - 1 downto 0);

    signal rden :  std_ulogic;
    signal wren :  std_ulogic;
    signal reg_addr :  unsigned(7 downto 0);
    signal reg_i :  std_ulogic_vector(7 downto 0);
    signal reg_o :  std_ulogic_vector(7 downto 0);

begin
    sram0 : entity work.sram_macro
        generic map(
            CONFIG => "sram64x8m8wm1_3v3"
        )
        port map(
            clk  => clk,
            en   => rden,
            wren => wren,
            mask => (others => '1'),
            addr => reg_addr,
            din  => reg_i,
            dout => reg_o
    );

    seq: process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                regiodefault : for rg in 2**MMIOD - 1 downto 0 loop
                    if(iodirmask(rg) = '1') then
                        regio(rg) <= (others => '0');
                    end if;
                end loop;
            else
                if cmd = "101" then
                    if(iodirmask(to_integer(addr(MMIOD - 1 downto 0))) = '0') then
                        regio(to_integer(addr(MMIOD - 1 downto 0))) <= din;
                    end if;
                elsif cmd = "110" then
                    io_out <= regio(to_integer(addr(MMIOD - 1 downto 0)));
                end if;
            end if;
        end if;
    end process seq;

    dout <= io_out when cmd = "110" 
       else reg_o  when cmd = "010"
       else (others => '0');

    rden <= '1' when cmd = "010" or cmd = "001" else '0';
    wren <= '1' when cmd = "001" else '0';

    reg_addr <= resize(addr, 8) when rden = '1' else (others => '0');
    reg_i <= din when cmd = "001" else (others => '0');
end architecture rtl;
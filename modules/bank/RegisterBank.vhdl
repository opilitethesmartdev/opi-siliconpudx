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
        mode : in std_ulogic; -- mirror mode when 0, singular mode when 1

        -- Data interface
        cmd : in std_ulogic_vector(2 downto 0); -- [sel][read][write] 
        addr : in unsigned(REGD - 1 downto 0);  -- common for mirror mode, sram0 for singular mode
        din  : in std_ulogic_vector(WORDWIDTH - 1 downto 0);-- only mirror mode
        dout : out std_ulogic_vector(WORDWIDTH - 1 downto 0); -- common for mirror mode, sram0 for singular mode

        -- Alternative read for sram1, only usable in mirror mode
        addra : in unsigned(REGD - 1 downto 0);
        douta : out std_ulogic_vector(WORDWIDTH - 1 downto 0);

        iodirmask : in  std_ulogic_vector(2**MMIOD - 1 downto 0) -- read = 0
    );

end entity RegisterBank;

architecture rtl of RegisterBank is
    signal regio : reg_array_t(0 to 2**MMIOD - 1) := (others => (others => '0'));
    signal io_out : std_ulogic_vector(WORDWIDTH - 1 downto 0);

    signal rden :  std_ulogic;
    signal wren :  std_ulogic;
    signal reg_addr1 :  unsigned(7 downto 0);
    signal reg_o0 :  std_ulogic_vector(7 downto 0);
    signal reg_o1 :  std_ulogic_vector(7 downto 0);

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
            addr => addr,
            din  => din,
            dout => reg_o0
    );

    sram1 : entity work.sram_macro
        generic map(
            CONFIG => "sram64x8m8wm1_3v3"
        )
        port map(
            clk  => clk,
            en   => rden,
            wren => wren,
            mask => (others => '1'),
            addr => reg_addr1,
            din  => din,
            dout => reg_o1
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

    rden <= (not cmd(2) and xor cmd(1 downto 0)) or mode;
    wren <= (nor cmd(2 downto 1) and cmd(0)) and not mode;

    dout <= (reg_o0 or reg_o1) when (mode or cmd(2)) = '0' else io_out when cmd(2) = '1' else reg_o0;
    douta <= reg_o1 when mode = '1' else (others => '0');    
    
    reg_addr1 <= addra when mode = '1' else addr;
end architecture rtl;
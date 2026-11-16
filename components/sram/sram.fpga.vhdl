----------------------------------------------------------------------------
-- Project		:	OPI-siliconPUdx
-- Authors		:	opilitethesmartdev
-- Description	:	FPGA SRAM macro emulator
----------------------------------------------------------------------------
library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.core_pkg.all;
use work.register_pkg.all;
use work.instruction_pkg.all;

entity sram_macro is
    generic(
        CONFIG : string := "sram256x8m8wm1_3v3"
    );
    port(        
        clk : in std_ulogic;
        en  : in std_ulogic;
        wren : in std_ulogic;
        mask : in std_ulogic_vector(7 downto 0);
        addr : in unsigned(7 downto 0);
        din  : in std_ulogic_vector(7 downto 0);
        dout : out std_ulogic_vector(7 downto 0)
    );

end entity sram_macro;

architecture rtl of sram_macro is
    type mem_arr_t is array(natural range<>) of std_ulogic_vector(7 downto 0);
    signal mem256 : mem_arr_t(0 to 255) := x"00";
    signal mem64  : mem_arr_t(0 to 63)  := x"00";

    signal CEN  : std_ulogic;
    signal GWEN : std_ulogic;
    signal WEN  : std_ulogic_vector(7 downto 0);
    signal A    : std_ulogic_vector(7 downto 0);
    signal D    : std_ulogic_vector(7 downto 0);
    signal Q    : std_ulogic_vector(7 downto 0);


begin
    sram256x8m8wm1_x : if CONFIG = "sram256x8m8wm1" or CONFIG = "sram256x8m8wm1_3v3" generate
        process(clk)
        begin
            if rising_edge(clk) then
                if en = '1' then
                    if wren = '1' then
                        mem256(to_integer(addr)) <= din;
                    else 
                        dout <= mem256(to_integer(addr));
                    end if;
                end if;
            end if;
        end process;
    end generate;
    sram64x8m8wm1_3v3 : if CONFIG = "sram64x8m8wm1_3v3" generate
        process(clk)
        begin
            if rising_edge(clk) then
                if en = '1' then
                    if wren = '1' then
                        mem64(to_integer(resize(addr, 6))) <= din;
                    else 
                        dout <= mem64(to_integer(addr, 6));
                    end if;
                end if;
            end if;
        end process;
    end generate;

end architecture rtl;

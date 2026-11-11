----------------------------------------------------------------------------
-- Project		:	OPI-siliconPUdx
-- Authors		:	opilitethesmartdev
-- Description	:	SRAM Arbiter
----------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.core_pkg.all;
use work.register_pkg.all;
use work.instruction_pkg.all;

entity SRAMMuxIf is
    port (
        clk : in std_ulogic;
        rst : in std_ulogic;
        sel : in std_ulogic;
        
        -- Source Interface
        ram_en   : out std_ulogic;
        ram_wren : out std_ulogic;
        ram_mask : out std_ulogic_vector(IBWIDTH - 1 downto 0);
        ram_addr : out unsigned(INSTD - 1 downto 0);
        ram_din  : out std_ulogic_vector(IBWIDTH - 1 downto 0);
        ram_dout : in std_ulogic_vector(IBWIDTH - 1 downto 0);
        
        -- Interface 0
        ram_0_en   : in std_ulogic;
        ram_0_wren : in std_ulogic;
        ram_0_mask : in std_ulogic_vector(IBWIDTH - 1 downto 0);
        ram_0_addr : in unsigned(INSTD - 1 downto 0);
        ram_0_din  : in std_ulogic_vector(IBWIDTH - 1 downto 0);
        ram_0_dout : out std_ulogic_vector(IBWIDTH - 1 downto 0);
        
        -- Interface 1
        ram_1_en   : in std_ulogic;
        ram_1_wren : in std_ulogic;
        ram_1_mask : in std_ulogic_vector(IBWIDTH - 1 downto 0);
        ram_1_addr : in unsigned(INSTD - 1 downto 0);
        ram_1_din  : in std_ulogic_vector(IBWIDTH - 1 downto 0);
        ram_1_dout : out std_ulogic_vector(IBWIDTH - 1 downto 0)
    );
end entity SRAMMuxIf;

architecture rtl of SRAMMuxIf is
begin
    ram_en   <= ram_0_en   when sel = '0' else ram_1_en;
    ram_wren <= ram_0_wren when sel = '0' else ram_1_wren;
    ram_mask <= ram_0_mask when sel = '0' else ram_1_mask;
    ram_addr <= ram_0_addr when sel = '0' else ram_1_addr;
    ram_din  <= ram_0_din  when sel = '0' else ram_1_din;

    ram_0_dout <= ram_dout when sel = '0' else (others => '0');
    ram_1_dout <= ram_dout when sel = '1' else (others => '0');
end rtl;
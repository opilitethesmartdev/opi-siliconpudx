----------------------------------------------------------------------------
-- Project		:	OPI-siliconPUdx
-- Authors		:	opilitethesmartdev
-- Description	:	ASIC harness
----------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.core_pkg.all;
use work.register_pkg.all;
use work.instruction_pkg.all;

entity asic_harness is
    port(
        -- Fundamental signals
        clk : in std_ulogic;
        rst : in std_ulogic;
        en : in  std_ulogic_vector(1 downto 0);
        o  : out std_ulogic_vector(1 downto 0);

        rw : in std_ulogic_vector(1 downto 0);
        addr : in std_ulogic_vector(REGD - 1 downto 0);

        din  : in std_ulogic_vector(WORDWIDTH - 1 downto 0);
        dout : out std_ulogic_vector(WORDWIDTH - 1 downto 0);

        -- SRAM Interface
        ram_en   : out std_ulogic;
        ram_wren : out std_ulogic;
        ram_mask : out std_ulogic_vector(IBWIDTH - 1 downto 0);
        ram_addr : out unsigned(INSTD - 1 downto 0);
        ram_din  : out std_ulogic_vector(IBWIDTH - 1 downto 0);
        ram_dout : in std_ulogic_vector(IBWIDTH - 1 downto 0);

        -- Mock output (prevents instruction architecture from being optimized away at synthesis)
        instruction : out std_ulogic
    );

end entity asic_harness;

architecture rtl of asic_harness is
    -- SRAM Access Arbitration
    signal req        :  std_ulogic_vector(1 downto 0);
    signal rsv        :  std_ulogic_vector(1 downto 0);

    -- Toplevel SRAM Access
    signal ram_a_en   :  std_ulogic;
    signal ram_a_wren :  std_ulogic;
    signal ram_a_mask :  std_ulogic_vector(IBWIDTH-1 downto 0);
    signal ram_a_addr :  unsigned(INSTD-1 downto 0);
    signal ram_a_din  :  std_ulogic_vector(IBWIDTH-1 downto 0);
    signal ram_a_dout :  std_ulogic_vector(IBWIDTH-1 downto 0);

    -- Host Serial Converter SRAM Access
    signal  hsc_ram_en   :  std_ulogic;
    signal  hsc_ram_wren :  std_ulogic;
    signal  hsc_ram_mask :  std_ulogic_vector(IBWIDTH-1 downto 0);
    signal  hsc_ram_addr :  unsigned(INSTD-1 downto 0);
    signal  hsc_ram_din  :  std_ulogic_vector(IBWIDTH-1 downto 0);
    signal  hsc_ram_dout :  std_ulogic_vector(IBWIDTH-1 downto 0);


begin
    i_SRAMArbiterIf : entity work.SRAMArbiterIf
        port map(
            clk        => clk,
            rst        => rst,
            req        => req,
            rsv        => rsv,
            ram_en     => ram_en,
            ram_wren   => ram_wren,
            ram_mask   => ram_mask,
            ram_addr   => ram_addr,
            ram_din    => ram_din,
            ram_dout   => ram_dout,
            ram_a_en   => ram_a_en,
            ram_a_wren => ram_a_wren,
            ram_a_mask => ram_a_mask,
            ram_a_addr => ram_a_addr,
            ram_a_din  => ram_a_din,
            ram_a_dout => ram_a_dout,
            ram_b_en   => hsc_ram_en,
            ram_b_wren => hsc_ram_wren,
            ram_b_mask => hsc_ram_mask,
            ram_b_addr => hsc_ram_addr,
            ram_b_din  => hsc_ram_din,
            ram_b_dout => hsc_ram_dout
    );
    

end architecture rtl;
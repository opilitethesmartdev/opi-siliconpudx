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
    signal ram_sel        :  std_ulogic;

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

    signal re_cmd      :  std_ulogic_vector(1 downto 0);
    signal re_addr     :  unsigned(REGD-1 downto 0);
    signal re_i        :  std_ulogic_vector(WORDWIDTH-1 downto 0);
    signal re_o        :  std_ulogic_vector(WORDWIDTH-1 downto 0);



begin
    i_SRAMMuxIf : entity work.SRAMMuxIf
        port map(
            sel        => ram_sel,
            ram_en     => ram_en,
            ram_wren   => ram_wren,
            ram_mask   => ram_mask,
            ram_addr   => ram_addr,
            ram_din    => ram_din,
            ram_dout   => ram_dout,
            ram_0_en   => hsc_ram_en,
            ram_0_wren => hsc_ram_wren,
            ram_0_mask => hsc_ram_mask,
            ram_0_addr => hsc_ram_addr,
            ram_0_din  => hsc_ram_din,
            ram_0_dout => hsc_ram_dout,
            ram_1_en   => ram_a_en,
            ram_1_wren => ram_a_wren,
            ram_1_mask => ram_a_mask,
            ram_1_addr => ram_a_addr,
            ram_1_din  => ram_a_din,
            ram_1_dout => ram_a_dout
    );    

    i_toplevel : entity work.toplevel
        port map(
            clk         => clk,
            rst         => rst,
            en          => en(0),
            o           => o,
            ram_en      => ram_a_en,
            ram_wren    => ram_a_wren,
            ram_mask    => ram_a_mask,
            ram_addr    => ram_a_addr,
            ram_dout    => ram_a_dout,
            re_cmd      => re_cmd,
            re_addr     => re_addr,
            re_i        => re_i,
            re_o        => re_o,
            instruction => instruction
    );


end architecture rtl;
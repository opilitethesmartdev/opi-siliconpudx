----------------------------------------------------------------------------
-- Project		:	OPI-siliconPUdx
-- Authors		:	opilitethesmartdev
-- Description	:	ASIC IO layout interface (Tiny Tapeout wrapper)
----------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.core_pkg.all;
use work.register_pkg.all;
use work.instruction_pkg.all;

entity tt_um_opi_siliconpudx is
    port(
        -- Tiny Tapeout standard signals
        clk     : in  std_ulogic;
        rst_n   : in  std_ulogic;
        ena     : in  std_ulogic;
        ui_in   : in  std_ulogic_vector(7 downto 0);
        uo_out  : out std_ulogic_vector(7 downto 0);
        uio_in  : in  std_ulogic_vector(7 downto 0);
        uio_out : out std_ulogic_vector(7 downto 0);
        uio_oe  : out std_ulogic_vector(7 downto 0)
    );
end entity tt_um_opi_siliconpudx;

architecture rtl of tt_um_opi_siliconpudx is
signal instruction, mock_out  :  std_ulogic;

signal rst  :  std_ulogic;
signal o    :  std_ulogic_vector(1 downto 0);
signal en   :  std_ulogic_vector(1 downto 0);

signal ram_en      :  std_ulogic;
signal ram_wren    :  std_ulogic;
signal ram_mask    :  std_ulogic_vector(IBWIDTH-1 downto 0);
signal ram_addr    :  unsigned(INSTD-1 downto 0);
signal ram_din     :  std_ulogic_vector(IBWIDTH-1 downto 0);
signal ram_dout    :  std_ulogic_vector(IBWIDTH-1 downto 0);

signal mosi        :  std_ulogic;
signal t_si        :  std_ulogic;
signal miso        :  std_ulogic;
signal t_so        :  std_ulogic;


begin
i_asic_harness : entity work.asic_harness
    port map(
        clk         => clk,
        rst         => rst,
        en          => en,
        o           => o,
        mosi        => mosi,
        t_si        => t_si,
        miso        => miso,
        t_so        => t_so,
        ram_en      => ram_en,
        ram_wren    => ram_wren,
        ram_mask    => ram_mask,
        ram_addr    => ram_addr,
        ram_din     => ram_din,
        ram_dout    => ram_dout,
        instruction => instruction
);

mock_shift : entity work.n_shift1b
    generic map(
        DELAY => 5
    )
    port map(
        clk => clk,
        rst => rst,
        i   => instruction,
        o   => mock_out
);

rst <= not rst_n;

uo_out <= mock_out & mosi & t_si & "000" & o;
miso <= ui_in(7);
t_so <= ui_in(6);
en <= '0' & ena;

uio_out <= (others => '0');
uio_oe <= (others => '0');

end architecture rtl;

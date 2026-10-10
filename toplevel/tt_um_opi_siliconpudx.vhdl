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
signal rst  :  std_ulogic;
signal o    :  std_ulogic_vector(1 downto 0);
signal en   :  std_ulogic_vector(1 downto 0);
signal rw   :  std_ulogic_vector(1 downto 0);
signal addr :  std_ulogic_vector(REGD-1 downto 0);
signal din  :  std_ulogic_vector(WORDWIDTH-1 downto 0);
signal dout :  std_ulogic_vector(WORDWIDTH-1 downto 0);

begin
i_asic_harness : entity work.asic_harness
    port map(
        clk  => clk,
        rst  => rst,
        en   => en,
        o    => o,
        rw   => rw,
        addr => addr,
        din  => din,
        dout => dout
);

rst <= not rst_n;

uo_out <= o & "000000";
rw <= ui_in(7 downto 6);
addr <= ui_in(5 downto 1);
en <= ui_in(0) & ena;

din <= uio_in when (rw = "00") else (others => '0');
uio_out <= dout when (rw = "01" or rw = "11") else (others => '0');

uio_oe <= (others =>'1') when (rw = "01" or rw = "11") else (others => '0');

end architecture rtl;

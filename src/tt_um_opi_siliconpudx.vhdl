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
    signal rst  : std_ulogic;
    signal o    : std_ulogic_vector(1 downto 0);
    signal tick : std_ulogic;
    signal rw   : std_ulogic_vector(1 downto 0);
    signal addr : std_ulogic_vector(REGDEPTH - 1 downto 0);
    signal doe : std_ulogic;
    signal di  : std_ulogic_vector(WORDWIDTH - 1 downto 0);
    signal do  : std_ulogic_vector(WORDWIDTH - 1 downto 0);
begin
    -- Reset polarity conversion (active low rst_n to active high rst)
    rst <= not rst_n;

    -- Map ui_in to harness control signals
    tick <= ui_in(0);
    rw   <= ui_in(2 downto 1);
    addr <= ui_in(7 downto 3);

    -- Map harness status to uo_out
    uo_out(1 downto 0) <= o;
    uo_out(7 downto 2) <= (others => '0');

    -- Map bidirectional IOs (uio) to dio
    uio_out <= do;
    uio_oe  <= (others => doe);
    di <= uio_in;

    i_asic_harness : entity work.asic_harness
        port map(
            clk  => clk,
            rst  => rst,
            en   => ena,
            o    => o,
            tick => tick,
            rw   => rw,
            addr => addr,
            di  => di,
            do  => do,
            doe  => doe
    );

end architecture rtl;

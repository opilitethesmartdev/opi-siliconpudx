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

begin

end architecture rtl;

----------------------------------------------------------------------------
-- Project		:	OPI-siliconPUdx
-- Authors		:	opilitethesmartdev
-- Description	:	Host Serial Communication package
----------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package hsc_pkg is
    constant HCMDW : natural := 2;
    constant HDATAW : natural := 41;
    constant HSCW : natural := HCMDW + HDATAW;

    constant HWW : natural := 8;
end package hsc_pkg;
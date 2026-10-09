----------------------------------------------------------------------------
-- Project		:	OPI-siliconPUdx
-- Authors		:	opilitethesmartdev
-- Description	:	GF180MCU SRAM macro wrapper
----------------------------------------------------------------------------
library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.core_pkg.all;
use work.register_pkg.all;
use work.instruction_pkg.all;

entity sram_macro is
    --generic(
    --    CONFIG : string := "sram256x8m8wm1"
    --);
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
    component gf180mcu_fd_ip_sram_sram256x8m8wm1 is
        port(
            CLK : in std_ulogic;
            CEN : in std_ulogic;
            GWEN : in std_ulogic;
            WEN  : in std_ulogic_vector(7 downto 0);
            A : in std_ulogic_vector(7 downto 0);
            D : in std_ulogic_vector(7 downto 0);
            Q : out std_ulogic_vector(7 downto 0)
        );
    end component;

    signal CEN  : std_ulogic;
    signal GWEN : std_ulogic;
    signal WEN  : std_ulogic_vector(7 downto 0);
    signal A    : std_ulogic_vector(7 downto 0);
    signal D    : std_ulogic_vector(7 downto 0);
    signal Q    : std_ulogic_vector(7 downto 0);


begin
    --sram256x8m8wm1 : if CONFIG = "sram256x8m8wm1" generate
        sram : gf180mcu_fd_ip_sram_sram256x8m8wm1
            port map(
                CLK  => CLK,
                CEN  => CEN,
                GWEN => GWEN,
                WEN  => WEN,
                A    => A,
                D    => D,
                Q    => Q
        );
    --end generate;

    CEN <= not en;
    GWEN <= not wren;
    WEN <= not mask;
    A <= std_ulogic_vector(addr);
    D <= din;
    dout <= Q;

end architecture rtl;

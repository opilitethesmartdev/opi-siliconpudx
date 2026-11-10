----------------------------------------------------------------------------
-- Project		:	OPI-siliconPUdx
-- Authors		:	opilitethesmartdev
-- Description	:	8-wire serial interface to external memory
----------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.core_pkg.all;
use work.register_pkg.all;

entity SerialMemoryMasterIf is
    generic(
        SDATAWIDTH : natural := 4;
        SADDRWIDTH : natural := 2;
        DATAWIDTH : natural := 32;
        ADDRWIDTH : natural := 16;
    );
    port (
        clk : in std_ulogic;

        -- Memory Interface       
        int : in std_ulogic;
        ctrl : out std_ulogic;
        saddr : out   std_ulogic_vector(SADDRWIDTH - 1 downto 0);
        -- Tri-state data lines
        doe  : out std_ulogic_vector(SDATAWIDTH - 1 downto 0);
        dmo  : out std_ulogic_vector(SDATAWIDTH - 1 downto 0);
        dmi  : in std_ulogic_vector(SDATAWIDTH - 1 downto 0);
        
        -- Control interface
        cmd : in std_ulogic_vector(1 downto 0); --[rd][wr]; xor = en
        addr : in unsigned(ADDRWIDTH - 1 downto 0);
        dso : in std_ulogic_vector(DATAWIDTH - 1 downto 0);
        dsi : out std_ulogic_vector(DATAWIDTH - 1 downto 0);
    );
end entity SerialMemoryMasterIf;

architecture rtl of SerialMemoryMasterIf is
    signal clk_n, en : std_ulogic;
    signal load_shifts : std_ulogic;
    signal addr_ff : std_ulogic_vector(ADDRWIDTH - 1 downto 0);
begin
    -- Clock / Enable logic
    clk_n <= not clk;
    en <= xor cmd;

loadedge : entity work.edgend
    generic map(
        polarity => polarity
    )
    port map(
        clk => clk,
        i   => en,
        o   => load_shifts
);


    shiftff: process(clk, clk_n) 
    begin
        if rising_edge(clk) or rising_edge(clk_n) then
            if en = '1' then
                if load_shifts = '1' then
                    addr_ff <= addr;
                else
                end if;
            end if;
        end if;
    end process shiftff;
end architecture rtl;
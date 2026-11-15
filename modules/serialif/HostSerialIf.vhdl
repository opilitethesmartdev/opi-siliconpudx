----------------------------------------------------------------------------
-- Project		:	OPI-SiliconPUdx
-- Authors		:	opilitethesmartdev
-- Description	:	Interface for Host Serial Communication
----------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.core_pkg.all;
use work.hsc_pkg.all;
use work.register_pkg.all;
use work.instruction_pkg.all;

entity HostSerialIf is
    port (
        clk : in std_ulogic;
        rst : in std_ulogic;

        -- Serial Interface        
        mosi : out std_ulogic;
        t_si : out std_ulogic;
        miso : in std_ulogic;
        t_so : in std_ulogic;

        -- SRAM Interface
        ram_en   : out std_ulogic;
        ram_wren : out std_ulogic;
        ram_mask : out std_ulogic_vector(IBWIDTH - 1 downto 0);
        ram_addr : out unsigned(INSTD - 1 downto 0);
        ram_din  : out std_ulogic_vector(IBWIDTH - 1 downto 0);
        ram_dout : in std_ulogic_vector(IBWIDTH - 1 downto 0);

        -- Register bank interface
        re_cmd  : out std_ulogic_vector(1 downto 0);
        re_addr : out unsigned(REGD-1 downto 0);
        re_i : out std_ulogic_vector(WORDWIDTH-1 downto 0);
        re_o : in  std_ulogic_vector(WORDWIDTH-1 downto 0)
    );
end HostSerialIf ;

architecture rtl of HostSerialIf is
    type s_t is (idl, eva, op, wb, await);
    signal s, sn : s_t;

    signal spcrst, cycle : std_ulogic;
    signal cmdff, cmd : std_ulogic_vector(1 downto 0);

    signal mo_en :  std_ulogic;
    signal d_mo  :  std_ulogic_vector(HSCW-1 downto 0);
    signal mo_fn :  std_ulogic;
    signal mi_av :  std_ulogic;
    signal d_mi  :  std_ulogic_vector(HSCW-1 downto 0);

begin
    spc : entity work.spconverter
        generic map(
            DW => HSCW
        )
        port map(
            clk   => clk,
            rst   => spcrst,
            mosi  => mosi,
            t_si  => t_si,
            miso  => miso,
            t_so  => t_so,
            mo_en => mo_en,
            d_mo  => d_mo,
            mo_fn => mo_fn,
            mi_av => mi_av,
            d_mi  => d_mi
    ); spcrst <= rst or cycle;

    ff: process(rst, clk)
    begin
        if rst = '1' then
            s <= idl;
            cmdff <= "00";
        elsif rising_edge(clk) then
            s <= sn;
            cmdff <= cmd;
        end if;
    end process ff;

    fsm : process(s, mi_av)
    begin
        case s is
            when idl => sn <= eva when mi_av <= '1' else idl;
            when eva => sn <= op;
        end case;
    end process fsm;

    main : process(s, mi_av)
    begin
        case s is
            when idl =>
            when eva =>
                cmd <= d_mi(DW downto)
        end case;
    end process main;
end architecture rtl;
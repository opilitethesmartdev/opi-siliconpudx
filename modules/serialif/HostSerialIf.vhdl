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

    type s_t is (reset, idl, ldc, eva, opf, opr, wb, sen, await);
    signal s, sn : s_t;

    signal cycle : std_ulogic;
    signal cmdff, cmd : std_ulogic_vector(1 downto 0);

    signal mo_en :  std_ulogic;
    signal mo_fn :  std_ulogic;
    signal mi_av :  std_ulogic;
    signal d_mi, d_mo   : std_ulogic_vector(HSCW-1 downto 0);
    signal cmdi, cmdiff : std_ulogic_vector(HSCW-1 downto 0);
    signal ramo, ramoff : std_ulogic_vector(IBWIDTH-1 downto 0);
    signal rego, regoff : std_ulogic_vector(WORDWIDTH-1 downto 0);

begin
    spc : entity work.spconverter
        generic map(
            DW => HSCW
        )
        port map(
            clk   => clk,
            rst   => rst,
            mosi  => mosi,
            t_si  => t_si,
            miso  => miso,
            t_so  => t_so,
            mo_en => mo_en,
            d_mo  => d_mo,
            mo_fn => mo_fn,
            mi_av => mi_av,
            d_mi  => d_mi,
            ack => cycle
    );

    ff: process(rst, clk)
    begin
        if rst = '1' then
            s <= reset;
            cmdff <= "00";
            cmdiff <= (others => '0');
            ramoff <= (others => '0');
            regoff <= (others => '0');
        elsif rising_edge(clk) then
            s <= sn;
            cmdff <= cmd;
            cmdiff <= cmdi;
            ramoff <= ramo;
            regoff <= rego;
        end if;
    end process ff;

    fsm : process(all)
    begin
        case s is
            when reset =>  sn <= idl;
            when idl =>    sn <= ldc when mi_av = '1' else idl;
            when ldc =>    sn <= eva;
            when eva =>    sn <= opf;
            when opf =>    sn <= sen;
            when sen =>    sn <= wb;
            when wb =>     sn <= await;
            when await =>  sn <= reset when mo_fn = '1' else await;
            when others => sn <= reset;
        end case;
    end process fsm;

    main : process(all)
    begin
        cmd <= cmdff;
        cmdi <= cmdiff;
        ramo <= ramoff;
        rego <= regoff;

        ram_en   <= '0';                                                
        ram_wren <= '0';                                              
        ram_mask <= (others => '0');
        ram_addr <= (others => '0');
        ram_din  <= (others => '0');

        re_cmd  <= "00";
        re_addr <= (others => '0');
        re_i    <= (others => '0');
        
        cycle <= '0';
        
        mo_en <= '0';
        d_mo <= (others => '0');

        case s is
            when reset => 
                cycle <= '1';

                cmd  <= (others => '0');
                cmdi <= (others => '0');

                ramo <= (others => '0');
                rego <= (others => '0');
            when ldc => cmdi <= d_mi;
            when eva =>
                cmd <= cmdiff(HSCW - 1 downto HSCW - HCMDW);
                cycle <= '1';
            when opf =>
                if cmd(1) = '1' then
                    if cmd(0) = '1' then
                        ram_en <= '1';
                        ram_wren <= '1';
                        ram_mask <= (others => '1');
                        ram_addr <= unsigned(cmdiff(HDATAW - 1 downto HDATAW - INSTD));
                        ram_din <= cmdiff(HDATAW - INSTD - 1 downto 0);
                    else
                        re_cmd  <= "01";
                        re_addr <= resize(unsigned(d_mi(HDATAW-1 - 1 downto HDATAW-1 - HWW)), REGD);
                        re_i    <= cmdiff(HDATAW-1 - HWW - 1 downto HDATAW-1 - HWW*2);
                    end if;
                else
                    if cmd(0) = '1' then
                        ram_en <= '1';
                        ram_mask <= (others => '1');
                        ram_addr <= unsigned(cmdiff(HDATAW - 1 downto HDATAW - INSTD));
                    else
                        re_cmd  <= "10";
                        re_addr <= resize(unsigned(cmdiff(HDATAW-1 - 1 downto HDATAW - HWW-1)), REGD);
                    end if;
                end if;
            when sen =>
                mo_en <= '1';

                if cmd(0) = '1' then
                    ramo <= ram_dout;
                else
                    rego <= re_o;
                end if;
            when wb =>
                if cmd(1) = '0' then
                        --mo_en <= '1';
                    if cmd(0) = '1' then
                        d_mo <= cmdff(1) & '0'
                                & cmdiff(HDATAW - 1 downto HDATAW - INSTD)
                                & ramoff;
                    else
                        d_mo <= cmdff(1) & '0'
                                & cmdiff(HDATAW - 1 downto HDATAW - HWW-1) 
                                & regoff & padding(IBWIDTH - WORDWIDTH - 1 downto 0);
                    end if;
                else
                    --mo_en <= '1';
                    d_mo <= cmdff(1) & '0' & padding(HSCW-2 - 1 downto 0);
                end if;
            when others =>
        end case;
    end process main;
end architecture rtl;
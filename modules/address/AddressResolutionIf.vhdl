----------------------------------------------------------------------------
-- Project		:	OPI-siliconPUdx
-- Authors		:	opilitethesmartdev
-- Description	:	Address Resolution Interface

----------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.core_pkg.all;
use work.register_pkg.all;
use work.instruction_pkg.all;

entity AddressResolutionIf is
    port(
        -- Fundamental signals
        clk : in std_ulogic;
        rst : in std_ulogic;
        en  : in std_ulogic;
        
        -- Register interface
        rden : out std_ulogic;
        addr : out unsigned(REGD - 1 downto 0);
        din  : in  std_ulogic_vector(WORDWIDTH - 1 downto 0);

        -- Input command
        inst : in std_ulogic_vector(INSTW - 1 downto 0);
        -- Resolved command
        res : out std_ulogic_vector(INSTW - 1 downto 0)
    );

end entity AddressResolutionIf;

architecture rtl of AddressResolutionIf is
    signal clk_n, valid0, valid1 : std_ulogic; -- [not clk, for falling edge][cmd0 valid for ar][cmd1 valid for ar]

    signal i_cmd    :  std_ulogic_vector(ICMDW-1 downto 0);
    signal i_depth0 :  std_ulogic_vector(IPTRW-1 downto 0);
    signal i_param0 :  std_ulogic_vector(PARAMW-1 downto 0);
    signal i_depth1 :  std_ulogic_vector(IPTRW-1 downto 0);
    signal i_param1 :  std_ulogic_vector(PARAMW-1 downto 0);

    signal a0_en    :  std_ulogic;
    signal a0_rden  :  std_ulogic;
    signal a0_addr  :  unsigned(REGD-1 downto 0);
    signal a0_din   :  std_ulogic_vector(WORDWIDTH-1 downto 0);
    signal a0_fin   :  std_ulogic;
    signal a0_tar   :  std_ulogic_vector(WORDWIDTH-1 downto 0);

    signal a1_en    :  std_ulogic;
    signal a1_rden  :  std_ulogic;
    signal a1_addr  :  unsigned(REGD-1 downto 0);
    signal a1_din   :  std_ulogic_vector(WORDWIDTH-1 downto 0);
    signal a1_fin   :  std_ulogic;
    signal a1_tar   :  std_ulogic_vector(WORDWIDTH-1 downto 0);

begin   
    inst_splitter : entity work.InstructionSplitterIf
        port map(
            i      => inst,
            cmd    => i_cmd,
            depth0 => i_depth0,
            param0 => i_param0,
            depth1 => i_depth1,
            param1 => i_param1
        );

    are0 : entity work.AddressResolutionEngine
        port map(
            clk   => clk,
            rst   => rst,
            en    => a0_en,
            depth => unsigned(i_depth0),
            param => i_param0,
            rden  => a0_rden,
            addr  => a0_addr,
            din   => din,
            fin   => a0_fin,
            tar   => a0_tar
        );

    are1 : entity work.AddressResolutionEngine
        port map(
            clk   => clk_n,
            rst   => rst,
            en    => a1_en,
            depth => unsigned(i_depth1),
            param => i_param1,
            rden  => a1_rden,
            addr  => a1_addr,
            din   => din,
            fin   => a1_fin,
            tar   => a1_tar
        );

    enp: process(rst, clk)
    begin
        if rst = '1' then
            a0_en <= '0';
            a1_en <= '0';
        elsif rising_edge(clk) then
            a0_en <= '1' when unsigned(i_depth0) = 0 and a0_fin = '0' else '0';
            a1_en <= '1' when unsigned(i_depth1) = 0 and a1_fin = '0' else '0';
        end if;
    end process enp;


    -- Combinatorial logic
        clk_n <= not clk;
        rden <= a0_rden when clk = '1' else a1_rden;
        addr <= a0_addr when clk = '1' else a1_addr;

        res <= i_depth0 & i_depth0 & i_cmd & a0_tar & a1_tar;
end architecture rtl;
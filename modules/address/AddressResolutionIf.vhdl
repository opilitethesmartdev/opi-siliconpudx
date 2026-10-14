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
    signal clk_n : std_ulogic;

    signal i :  inst_rec_t;

    signal a0_en    :  std_ulogic;
    signal a0_rden  :  std_ulogic;
    signal a0_addr  :  unsigned(REGD-1 downto 0);
    signal a0_fin   :  std_ulogic;
    signal a0_tar   :  std_ulogic_vector(WORDWIDTH-1 downto 0);

    signal a1_en    :  std_ulogic;
    signal a1_rden  :  std_ulogic;
    signal a1_addr  :  unsigned(REGD-1 downto 0);
    signal a1_fin   :  std_ulogic;
    signal a1_tar   :  std_ulogic_vector(WORDWIDTH-1 downto 0);

begin   
    are0 : entity work.AddressResolutionEngine
        port map(
            clk   => clk,
            rst   => rst,
            en    => a0_en,
            depth => unsigned(i.depth0),
            param => i.param0,
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
            depth => unsigned(i.depth1),
            param => i.param0,
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
            a0_en <= '1' when (unsigned(i.depth0) > 0 and a0_fin = '0' and en = '1') else '0';
            a1_en <= '1' when (unsigned(i.depth1) > 0 and a1_fin = '0' and en = '1') else '0';
        end if;
    end process enp;


    -- Combinatorial logic
        clk_n <= not clk;

        i <= v2inst(inst);
        
        rden <= a0_rden when clk = '1' else a1_rden;
        addr <= a0_addr when clk = '1' else a1_addr;

        res <= inst2v((depth0 => i.depth0, depth1 => i.depth1, cmd => i.cmd, param0 => a0_tar, param1 => a1_tar));
end architecture rtl;
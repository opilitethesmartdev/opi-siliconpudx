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
    signal intrst, dten, enff : std_ulogic;
    signal clk_n : std_ulogic;

    signal i :  inst_rec_t;

    signal a0_res   :  std_ulogic_vector(WORDWIDTH-1 downto 0);
    signal a1_res   :  std_ulogic_vector(WORDWIDTH-1 downto 0);

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
            rst   => intrst,
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
            rst   => intrst,
            en    => a1_en,
            depth => unsigned(i.depth1),
            param => i.param1,
            rden  => a1_rden,
            addr  => a1_addr,
            din   => din,
            fin   => a1_fin,
            tar   => a1_tar
        );

    enedge : entity work.edge
        generic map( polarity => "rising" )
        port map(
            clk => clk,
            i   => en,
            o   => dten
    );
    

    enp: process(rst, clk)
    begin
        if rst = '1' then
            a0_en <= '0';
            a1_en <= '0';

            enff <= '0';
        elsif rising_edge(clk) then
            enff <= en;

            a0_en <= '1' when (unsigned(i.depth0) > 0 and a0_fin = '0' and enff = '1') else '0';
            a1_en <= '1' when (unsigned(i.depth1) > 0 and a1_fin = '0' and enff = '1') else '0';
        end if;
    end process enp;

    -- Combinatorial logic
        clk_n <= not clk;
        intrst <= rst or dten;

        i <= v2inst(inst);
        
        rden <= a0_rden when clk = '1' else a1_rden;
        addr <= a0_addr when clk = '1' else a1_addr;

        a0_res <= a0_tar when (a0_en or a0_fin) = '1' else i.param0;
        a1_res <= a1_tar when (a1_en or a1_fin) = '1' else i.param1;

        res <= inst2v((depth0 => i.depth0, depth1 => i.depth1, cmd => i.cmd, param0 => a0_res, param1 => a1_res));
end architecture rtl;
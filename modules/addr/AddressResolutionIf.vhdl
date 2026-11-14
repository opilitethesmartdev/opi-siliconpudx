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
    port (
        -- Fundamental signals
        clk : in std_ulogic;
        rst : in std_ulogic;
        en  : in std_ulogic;

        -- Register singular access
        rd_a   : out std_ulogic;
        rd_b   : out std_ulogic;
        addr_a : out unsigned(REGD - 1 downto 0);        
        addr_b : out unsigned(REGD - 1 downto 0);        
        din_a  : in std_ulogic_vector(WORDWIDTH - 1 downto 0);
        din_b  : in std_ulogic_vector(WORDWIDTH - 1 downto 0);

        -- Instruction
        ins_i : in inst_rec_t;
        ins_o : out inst_rec_t
    );
end entity AddressResolutionIf;

architecture rtl of AddressResolutionIf is
signal rerst, recycle  :  std_ulogic;

signal en_0  :  std_ulogic;
signal i_d_0  :  unsigned(IPTRW-1 downto 0);
signal i_p_0  :  std_ulogic_vector(PARAMW-1 downto 0);
signal o_p_0  :  std_ulogic_vector(PARAMW-1 downto 0);

signal en_1  :  std_ulogic;
signal i_d_1  :  unsigned(IPTRW-1 downto 0);
signal i_p_1  :  std_ulogic_vector(PARAMW-1 downto 0);
signal o_p_1  :  std_ulogic_vector(PARAMW-1 downto 0);


begin
    -- Resolution Engines
    are0 : entity work.AddressResolutionEngine
        port map(
            clk  => clk,
            rst  => rerst,
            en   => en_0,
            rd   => rd_a,
            addr => addr_a,
            din  => din_a,
            i_d  => i_d_0,
            i_p  => i_p_0,
            o_p  => o_p_0
    );
    are1 : entity work.AddressResolutionEngine
        port map(
            clk  => clk,
            rst  => rerst,
            en   => en_1,
            rd   => rd_b,
            addr => addr_b,
            din  => din_b,
            i_d  => i_d_1,
            i_p  => i_p_1,
            o_p  => o_p_1
    );

    -- Low-level Entities
    endedge : entity work.edge
        generic map(
            polarity => "falling"
        )
        port map(
            clk => clk,
            i   => en,
            o   => recycle
    ); rerst <= rst or recycle;


    -- Seq logic
    resff : process (clk, rst)
    begin
        if rst = '1' then
            ins_o <= INSTNULL;
        elsif rising_edge(clk) then
            if en = '1' then
                ins_o <= v2inst(newinst(
                        to_integer(ins_i.depth0), 
                        to_integer(ins_i.depth1), 
                        ins_i.cmd, 
                        to_integer(unsigned(o_p_0)), 
                        to_integer(unsigned(o_p_1)))
                    );
            end if;
        end if;
    end process;

    en_0 <= '0' when ins_i.depth0 = 0 else en;
    en_1 <= '0' when ins_i.depth1 = 0 else en;

    i_d_0 <= ins_i.depth0;
    i_p_0 <= ins_i.param0;

    i_d_1 <= ins_i.depth1;
    i_p_1 <= ins_i.param1;
end architecture rtl;
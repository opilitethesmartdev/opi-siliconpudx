----------------------------------------------------------------------------
-- Project		:	OPI-siliconPUdx
-- Authors		:	opilitethesmartdev
-- Description	:	Processing Unit toplevel
----------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.core_pkg.all;
use work.register_pkg.all;
use work.instruction_pkg.all;

entity ProcessingElement is
    port(
        -- Fundamental signals
        clk : in clk_record_t;
        rst : in std_ulogic;
        en : in std_ulogic;
    
        -- Register rw interface
        reg_cmd  : out std_ulogic_vector(1 downto 0);    -- read / write cmd ([read][write], xor = enable)
        reg_addr : out unsigned(REGDEPTH - 1 downto 0);
        reg_o : out std_ulogic_vector(REGWIDTH - 1 downto 0);
        reg_i : in std_ulogic_vector(REGWIDTH - 1 downto 0);

        -- Instruction interface
        ins_rd  : out std_ulogic;        -- read / write cmd ([read][write], xor = enable)
        ins_addr : out unsigned(INST_DEPTH - 1 downto 0);
        ins_i : in inst_rec_t
    );

end entity ProcessingElement;

architecture rtl of ProcessingElement is
    signal inten : std_ulogic;
    --signal interr : std_ulogic;

    signal pc_ctrl :  std_ulogic_vector(1 downto 0);
    signal pc_ovr  :  unsigned(INST_DEPTH-1 downto 0) := (others => '0');
    signal pc      :  unsigned(INST_DEPTH-1 downto 0) := (others => '0');

    signal arif_en   : std_ulogic;
    signal arif_fin   : std_ulogic;
    signal arif_rd    : std_ulogic;
    signal arif_addr  : unsigned(REGDEPTH-1 downto 0) := (others => '0');
    signal arif_ins_r :  inst_rec_t;

    signal exu_en   : std_ulogic;
    signal exu_cmd  : std_ulogic_vector(1 downto 0) := (others => '0');  
    signal exu_pc_ctrl : std_ulogic_vector(1 downto 0) := (others => '0');   
    signal exu_addr : unsigned(REGDEPTH - 1 downto 0) := (others => '0');

begin
    -- Low-Level components
        pcshift : entity work.n_shift
            generic map(WIDTH => 2, DELAY => 1)
            port map(
                clk => clk.clk,
                rst => rst,
                i   => exu_pc_ctrl,
                o   => pc_ctrl
            );

    -- Modules           
        pcif : entity work.ProgramCounterIf
            port map(
                clk  => clk.clk_s,
                rst  => rst,
                en   => inten,
                ctrl => pc_ctrl,
                ovr  => pc_ovr,
                pc   => pc
            );

        arif : entity work.AddressResolutionIf
            port map(
                clk   => clk.clk,
                rst   => clk.sadvp,
                en    => arif_en,
                fin   => arif_fin,
                ins_i => ins_i,
                rd    => arif_rd,
                addr  => arif_addr,
                regi  => reg_i,
                ins_o => arif_ins_r
        );

        i_ExecutionUnit : entity work.ExecutionUnit
            port map(
                clk      => clk.clk,
                rst      => clk.sadvn,
                en       => exu_en,
                ins_i    => arif_ins_r,
                reg_cmd  => exu_cmd,
                reg_addr => exu_addr,
                reg_o    => reg_o,
                reg_i    => reg_i,
                pc_ctrl  => exu_pc_ctrl,
                pc_ovr   => pc_ovr
        );

        
        
    -- Combinatorial logic
        inten <= clk.clkon and en;

        ins_rd <= inten;
        ins_addr <= pc;

        arif_en <= clk.clk_s and inten;

        reg_cmd <= (arif_rd & '0') when clk.clk_s = '1' else exu_cmd;
        reg_addr <= arif_addr when clk.clk_s = '1' else exu_addr;

        exu_en <= (not clk.clk_s) and inten;
end architecture rtl;
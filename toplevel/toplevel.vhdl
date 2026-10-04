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

entity toplevel is
    port(
        -- Fundamental signals
        clk : in std_ulogic; -- fast clock
        rst : in std_ulogic;
        en : in std_ulogic;
        done : out std_ulogic;
        err : out std_ulogic
    );

end entity toplevel;

architecture rtl of toplevel is
    signal clk_s   : std_ulogic; -- slow clock
    signal sadvp : std_ulogic; -- clock rise advance signal
    signal sadvn : std_ulogic; -- clock fall advance signal
    signal clkon : std_ulogic; -- slow clock on signal
    signal inten : std_ulogic; -- internal enable signal

    signal pc_ctrl :  std_ulogic_vector(1 downto 0);
    signal pc_ovr  :  unsigned(INST_DEPTH-1 downto 0) := (others => '0');
    signal pc      :  unsigned(INST_DEPTH-1 downto 0);

    signal ins_fin  :  std_ulogic;
    signal ins_cmd  :  std_ulogic_vector(1 downto 0);
    signal ins_addr :  unsigned(INST_DEPTH-1 downto 0);
    signal ins_i :  std_ulogic_vector(INST_WIDTH-1 downto 0);
    signal ins_o :  inst_rec_t;
    --signal ins_o :  std_ulogic_vector(INST_WIDTH-1 downto 0);
    
    signal reg_cmd  : std_ulogic_vector(1 downto 0);
    signal reg_addr : unsigned(REGDEPTH-1 downto 0);
    signal reg_i :  std_ulogic_vector(REGWIDTH-1 downto 0);
    signal reg_o :  std_ulogic_vector(REGWIDTH-1 downto 0);

    signal arif_en   : std_ulogic;
    signal arif_fin   : std_ulogic;
    signal arif_rd    : std_ulogic;
    signal arif_addr  : unsigned(REGDEPTH-1 downto 0);
    signal arif_ins_r :  inst_rec_t;

    signal exu_en   : std_ulogic;
    signal exu_cmd  : std_ulogic_vector(1 downto 0);  
    signal exu_pc_ctrl : std_ulogic_vector(1 downto 0);   
    signal exu_addr : unsigned(REGDEPTH - 1 downto 0);

begin
    -- Low-Level components
        clkdiv : entity work.clkdiv
            generic map(
                CLOCKDIV => 5,
                C_WIDTH  => 3
            )
            port map(
                clkin  => clk,
                rst    => rst,
                clkout => clk_s,
                clkon => clkon,
                advp    => sadvp,
                advn    => sadvn
            );  

            pcshift : entity work.n_shift
                generic map(WIDTH => 2, DELAY => 1)
                port map(
                    clk => clk,
                    rst => rst,
                    i   => exu_pc_ctrl,
                    o   => pc_ctrl
              );

            
    -- Banks

        instbank : entity work.InstructionBank
            port map(
                clk  => clk,
                rst  => rst,
                err  => err,
                fin  => ins_fin,
                cmd  => ins_cmd,
                addr => ins_addr,
                insi => ins_i,
                inso => ins_o
            );

        regbank : entity work.RegisterBank
            port map(
                clk  => clk,
                rst  => rst,
                cmd  => reg_cmd,
                addr => reg_addr,
                regi => reg_i,
                rego => reg_o
        );

    -- Modules       

    
        pcif : entity work.ProgramCounterIf
            port map(
                clk  => clk_s,
                rst  => rst,
                en   => inten,
                ctrl => pc_ctrl,
                ovr  => pc_ovr,
                pc   => pc
            );

        arif : entity work.AddressResolutionIf
            port map(
                clk   => clk,
                rst   => sadvp,
                en    => arif_en,
                fin   => arif_fin,
                ins_i => ins_o,
                rd    => arif_rd,
                addr  => arif_addr,
                regi  => reg_o,
                ins_o => arif_ins_r
        );

        i_ExecutionUnit : entity work.ExecutionUnit
            port map(
                clk      => clk,
                rst      => sadvn,
                en       => exu_en,
                ins_i    => arif_ins_r,
                reg_cmd  => exu_cmd,
                reg_addr => exu_addr,
                reg_o    => reg_i,
                reg_i    => reg_o,
                pc_ctrl  => exu_pc_ctrl,
                pc_ovr   => pc_ovr
        );

        
        
    -- Combinatorial logic
        done <= ins_fin;
        inten <= clkon and en;

        ins_cmd <= inten & '0';
        ins_addr <= pc;

        arif_en <= clk_s and inten;

        reg_cmd <= (arif_rd & '0') when clk_s = '1' else exu_cmd;
        reg_addr <= arif_addr when clk_s = '1' else exu_addr;

        exu_en <= (not clk_s) and inten;
end architecture rtl;
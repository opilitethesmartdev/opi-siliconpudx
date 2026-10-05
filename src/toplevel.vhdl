----------------------------------------------------------------------------
-- Project		:	OPI-siliconPUdx
-- Authors		:	opilitethesmartdev
-- Description	:	siliconpudx toplevel
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
        o  : out std_ulogic_vector(1 downto 0); -- ([done][error])

        -- Instruction write interface
        inst_wr   : in std_ulogic;
        inst_addr : in  unsigned(INST_DEPTH - 1 downto 0);
        inst_i    : in std_ulogic_vector(INST_WIDTH-1 downto 0);
        
        -- External register rw interface
        re_cmd  : in std_ulogic_vector(1 downto 0);    -- read / write cmd ([read][write], xor = enable)
        re_addr : in unsigned(REGDEPTH - 1 downto 0);
        re_regi : in std_ulogic_vector(REGWIDTH - 1 downto 0);
        re_rego : out std_ulogic_vector(REGWIDTH - 1 downto 0)
    );

end entity toplevel;

architecture rtl of toplevel is
    signal clk_s : std_ulogic;
    signal sadvp : std_ulogic; 
    signal sadvn : std_ulogic; 
    signal clkon : std_ulogic; 

    signal fin : std_ulogic;

    signal err : std_ulogic;
    signal inten : std_ulogic;

    signal ins_fin  :  std_ulogic;
    signal ins_cmd  :  std_ulogic_vector(1 downto 0) := (others => '0');
    signal ins_addr :  unsigned(INST_DEPTH-1 downto 0) := (others => '0');
    signal ins_i :  std_ulogic_vector(INST_WIDTH-1 downto 0) := (others => '0');
    signal ins_o :  inst_rec_t;
    
    signal reg_cmd  : std_ulogic_vector(1 downto 0) := (others => '0');
    signal reg_addr : unsigned(REGDEPTH-1 downto 0) := (others => '0');
    signal reg_i :  std_ulogic_vector(REGWIDTH-1 downto 0) := (others => '0');
    signal reg_o :  std_ulogic_vector(REGWIDTH-1 downto 0) := (others => '0');
    
    signal pe_ins_clk :  clk_record_t;
    signal pe_ins_rd  :  std_ulogic;
    signal pe_ins_addr :  unsigned(INST_DEPTH-1 downto 0) := (others => '0');
    signal pe_ins_o :  inst_rec_t;
    signal pe_reg_cmd  : std_ulogic_vector(1 downto 0) := (others => '0');
    signal pe_reg_addr : unsigned(REGDEPTH-1 downto 0) := (others => '0');
    signal pe_reg_i :  std_ulogic_vector(REGWIDTH-1 downto 0) := (others => '0');
    signal pe_reg_o :  std_ulogic_vector(REGWIDTH-1 downto 0) := (others => '0');

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
                en     => inten,
                clkout => clk_s,
                clkon  => clkon,
                advp   => sadvp,
                advn   => sadvn
            );  

        finshift : entity work.n_shift1b
            generic map(
                DELAY => 1
            )
            port map(
                clk => clk,
                rst => rst,
                i   => ins_fin,
                o   => fin
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
        i_ProcessingElement : entity work.ProcessingElement
            port map(
                clk      => pe_ins_clk,
                rst      => rst,
                en       => inten,
                reg_cmd  => pe_reg_cmd,
                reg_addr => pe_reg_addr,
                reg_o    => pe_reg_o,
                reg_i    => pe_reg_i,
                ins_rd   => pe_ins_rd,
                ins_addr => pe_ins_addr,
                ins_i    => pe_ins_o
        );
            
    -- Combinatorial logic
        o <= err & fin when fin = '1' else "00";
        inten <= en when fin = '0' else '0';
 
        pe_ins_clk <= (clk => clk, clk_s => clk_s, clkon => clkon, sadvp => sadvp, sadvn => sadvn);
        pe_ins_o    <= ins_o;

        pe_reg_i <= reg_o when inten = '1' else REGNULL;
        re_rego  <= reg_o when inten = '0' else REGNULL;

        reg_cmd  <= pe_reg_cmd when  inten = '1' else re_cmd;
        reg_addr <= pe_reg_addr when inten = '1' else re_addr;
        reg_i    <= pe_reg_o when clkon = '1' else re_regi when en = '0' else (others => '0');

        ins_cmd  <= (pe_ins_rd & '0') when inten = '1' else ('0' & inst_wr);
        ins_addr <= pe_ins_addr when inten = '1' else inst_addr;
        ins_i <= inst_i when inten = '0' else INSTNULL;

end architecture rtl;
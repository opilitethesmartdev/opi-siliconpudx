----------------------------------------------------------------------------
-- Project		:	OPI-siliconPUdx
-- Authors		:	opilitethesmartdev
-- Description	:	Processor toplevel
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
        en : in  std_ulogic_vector(1 downto 0); -- [imode][en] 
        o  : out std_ulogic_vector(1 downto 0); -- [done][err]
        
        -- Instruction bank
        inst_cmd  : in std_ulogic_vector(1 downto 0);
        inst_addr : in unsigned(INSTD-1 downto 0);
        inst_i : in  std_ulogic_vector(INSTW-1 downto 0);
        inst_o : out std_ulogic_vector(INSTW-1 downto 0); 
        
        -- Register bank
        re_cmd  : in std_ulogic_vector(2 downto 0);
        re_addr : in unsigned(REGD-1 downto 0);
        re_i : in  std_ulogic_vector(WORDWIDTH-1 downto 0);
        re_o : out std_ulogic_vector(WORDWIDTH-1 downto 0);

        -- Mock output (prevents instruction architecture from being optimized away at synthesis)
        instruction : out std_ulogic
    );

end entity toplevel;

architecture rtl of toplevel is
    signal inten : std_ulogic_vector(1 downto 0);
    signal advpff, endt, endtff : std_logic;
    signal nclk, sclk :  clk_rec_t;

    signal ins_cmd  : std_ulogic_vector(1 downto 0);
    signal ins_addr : unsigned(INSTD-1 downto 0);
    signal ins_i : std_ulogic_vector(INSTW-1 downto 0);
    signal ins_o : std_ulogic_vector(INSTW-1 downto 0);
    signal sim_ins_o : inst_rec_t;

    signal reg_mode :  std_ulogic;
    signal reg_cmd  : std_ulogic_vector(2 downto 0);
    signal reg_addr : unsigned(REGD-1 downto 0);
    signal reg_i    : std_ulogic_vector(WORDWIDTH-1 downto 0);
    signal reg_o    : std_ulogic_vector(WORDWIDTH-1 downto 0);
    signal reg_addra : unsigned(REGD-1 downto 0);
    signal reg_oa    : std_ulogic_vector(WORDWIDTH-1 downto 0);
    signal mmio_dirmask : std_ulogic_vector(2**MMIOD-1 downto 0) := (others => '0');

    signal pc_cmd :  std_ulogic_vector(1 downto 0);
    signal pc_ovr :  unsigned(INSTD-1 downto 0);
    signal pc  :  unsigned(INSTD-1 downto 0);
    
    signal arif_en :  std_ulogic;
    signal arif_reg_rden :  std_ulogic;
    signal arif_reg_addr :  unsigned(REGD-1 downto 0);
    signal arif_reg_in  :  std_ulogic_vector(WORDWIDTH-1 downto 0);
    signal inst_res  :  std_ulogic_vector(INSTW-1 downto 0);
    signal sim_ins_res : inst_rec_t;

    signal exu_en    :  std_ulogic;
    signal exu_rst   :  std_ulogic;
    signal exu_fin   :  std_ulogic;
    signal exu_rcmd_s  :  std_ulogic_vector(2 downto 0);
    signal exu_addr_s  :  unsigned(REGD-1 downto 0);
    signal exu_dout_s  :  std_ulogic_vector(WORDWIDTH-1 downto 0);
    signal exu_din   :  std_ulogic_vector(WORDWIDTH-1 downto 0);
  
begin
    enff : process(rst, clk) begin
        if rst = '1' then 
            inten <= "00";
            o <= "00";
            advpff <= '0';
            endt <= '0';
        elsif rising_edge(clk) then 
            inten <= en;
            advpff <= sclk.advp;
            endtff <= endt;
            endt <= '1' when inten(0) = '0' and en(0) = '1' else '0';
            o <=     "10" when sclk.en = '1' and inst2cmd(ins_o) = stp 
                else "11" when sclk.en = '1' and inst2cmd(ins_o) = nop
                else "00";
        end if;
    end process enff;

    nclk_div : entity work.clkdiv
        generic map(
            CLOCKDIV => 5,
            C_WIDTH  => 3
        )
        port map(
            clki => clk,
            rst  => rst,
            en   => en(0),
            clko => nclk
    );

    sclk_div : entity work.clkdiv
        generic map(
            CLOCKDIV => 5,
            C_WIDTH  => 3
        )
        port map(
            clki => nclk.o,
            rst  => rst,
            en   => inten(0),
            clko => sclk
    );


    instb : entity work.InstructionBank
        port map(
            clk  => clk,
            cmd  => ins_cmd,
            addr => ins_addr,
            din  => ins_i,
            dout => ins_o
        );

    regb : entity work.RegisterBank
        port map(
            clk       => clk,
            rst       => rst,
            mode      => reg_mode,
            cmd       => reg_cmd,
            addr      => reg_addr,
            din       => reg_i,
            dout      => reg_o,
            addra     => reg_addra,
            douta     => reg_oa,
            iodirmask => mmio_dirmask
    );

    pcif : entity work.ProgramCounterIf
        port map(
            clk => nclk.o,
            rst => rst,
            cmd => pc_cmd,
            ovr => pc_ovr,
            pc  => pc
    );

    arif : entity work.AddressResolutionIf
        port map(
            clk   => clk,
            clk_s => sclk.o,
            rst  => rst,
            en   => arif_en,
            rden => arif_reg_rden,
            addr => arif_reg_addr,
            din  => arif_reg_in,
            inst => ins_o,
            res  => inst_res
    );

    exu : entity work.ExecutionUnit
        port map(
            clk    => nclk.o,
            rst    => exu_rst,
            en     => exu_en,
            fin    => exu_fin,
            rcmd   => exu_rcmd_s,
            addr   => exu_addr_s,
            dout   => exu_dout_s,
            din    => exu_din,
            inst   => inst_res,
            pc_cmd => pc_cmd,
            pc_ovr => pc_ovr
    );

    --ins_cmd  <= inst_cmd when inten(0) = '0' else (exu_fin or  endt or endtff) & '0';
    ins_cmd  <= inst_cmd when inten(0) = '0' else (sclk.advp or advpff ) & '0';
    ins_addr <=      inst_addr when inten(0) = '0' 
                else pc        when inten(0) = '1' 
                else (others => '0');
    ins_i    <= inst_i when inten(0) = '0' else (others => '0');

        inst_o <= ins_o when inten(0) = '0' else (others => '0');
        sim_ins_o <= v2inst(ins_o) when inten(0) = '1' else v2inst((others => '0'));

    reg_cmd  <=      re_cmd                      when inten(0) = '0' 
                else ('0' & arif_reg_rden & '0') when sclk.o = '1' 
                else exu_rcmd_s                    when sclk.o = '0' 
                else (others => '0');
    reg_addr <=      re_addr         when inten(0) = '0' 
                else (arif_reg_addr) when sclk.o = '1' 
                else exu_addr_s        when sclk.o = '0' 
                else (others => '0');
    reg_i    <=      re_i when inten(0) = '0' 
                else exu_dout_s when sclk.o = '0' 
                else (others => '0');
        re_o <= reg_o when inten(0) = '0' else (others => '0');
        arif_reg_in <= reg_o when (inten(0) = '1' and sclk.o = '1') else (others => '0');
        exu_din <= reg_o when (inten(0) = '1' and sclk.o = '0') else (others => '0');

    arif_en <= sclk.advp or sclk.o;
    sim_ins_res <= v2inst(inst_res);

    exu_en <= not sclk.o;
    exu_rst <= rst or sclk.advn;

    instruction <= or ins_o;

end architecture rtl;
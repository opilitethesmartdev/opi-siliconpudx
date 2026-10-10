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
        re_o : out std_ulogic_vector(WORDWIDTH-1 downto 0)
    );

end entity toplevel;

architecture rtl of toplevel is
    signal inten : std_ulogic_vector(1 downto 0);
    --signal fin : std_logic;
    signal sclk :  clk_rec_t;

    signal ins_cmd  : std_ulogic_vector(1 downto 0);
    signal ins_addr : unsigned(INSTD-1 downto 0);
    signal ins_i : std_ulogic_vector(INSTW-1 downto 0);
    signal ins_o : std_ulogic_vector(INSTW-1 downto 0);
    signal sim_ins_o : inst_rec_t;

    signal reg_cmd  : std_ulogic_vector(2 downto 0);
    signal reg_addr : unsigned(REGD-1 downto 0);
    signal reg_i    : std_ulogic_vector(WORDWIDTH-1 downto 0);
    signal reg_o    : std_ulogic_vector(WORDWIDTH-1 downto 0);
    signal mmio_dirmask : std_ulogic_vector(2**MMIOD-1 downto 0);

    signal pc_cmd :  std_ulogic_vector(1 downto 0);
    signal pc_ovr :  unsigned(INSTD-1 downto 0);
    signal pc  :  unsigned(INSTD-1 downto 0);
    

begin
    enff : process(rst, clk) begin
        if rst = '1' then 
            inten <= "00";
            o <= "00";
        elsif rising_edge(clk) then 
            inten <= en;
            o <=     "10" when sclk.en = '1' and inst2cmd(ins_o) = stp 
                else "11" when sclk.en = '1' and inst2cmd(ins_o) = nop
                else "00";
        end if;
    end process enff;

    clkdiv : entity work.clkdiv
        generic map(
            CLOCKDIV => 5,
            C_WIDTH  => 3
        )
        port map(
            clki => clk,
            rst  => rst,
            en   => inten(0),
            clko => sclk
    );


    inst : entity work.InstructionBank
        port map(
            clk  => clk,
            cmd  => ins_cmd,
            addr => ins_addr,
            din  => ins_i,
            dout => ins_o
        );

    reg : entity work.RegisterBank
        port map(
            clk       => clk,
            rst       => rst,
            cmd       => reg_cmd,
            addr      => reg_addr,
            din       => reg_i,
            dout      => reg_o,
            iodirmask => mmio_dirmask
        );

    pcif : entity work.ProgramCounterIf
        port map(
            clk => sclk.advp,
            rst => rst,
            cmd => pc_cmd,
            ovr => pc_ovr,
            pc  => pc
    );
    

    ins_cmd  <= inst_cmd when en(0) = '0' else en(0) & '0';
    ins_addr <= inst_addr when en(0) = '0' else pc when inten(0) = '1' else(others => '0');
    ins_i    <= inst_i when en(0) = '0' else (others => '0');
        inst_o <= ins_o when en(0) = '0' else (others => '0');
        sim_ins_o <= v2inst(ins_o) when en(0) = '1' else v2inst((others => '0'));

    reg_cmd  <= re_cmd when en(0) = '0' else (others => '0');
    reg_addr <= re_addr when en(0) = '0' else (others => '0');
    reg_i    <= re_i when en(0) = '0' else (others => '0');
        re_o <= reg_o when en(0) = '0' else (others => '0');

    pc_cmd <= en(0) & '0';
    pc_ovr <= (others => '0');

end architecture rtl;
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
            clk : in std_ulogic;
            rst : in std_ulogic;
            en : in  std_ulogic; -- [en] 
            o  : out std_ulogic_vector(1 downto 0); -- [done][err]
        
        -- Instruction SRAM access
            ram_en   : out std_ulogic;
            ram_wren : out std_ulogic;
            ram_mask : out std_ulogic_vector(IBWIDTH - 1 downto 0);
            ram_addr : out unsigned(INSTD - 1 downto 0);
            ram_dout : in std_ulogic_vector(IBWIDTH - 1 downto 0);
        
        -- Register bank external access
            re_cmd  : in std_ulogic_vector(1 downto 0);
            re_addr : in unsigned(REGD-1 downto 0);
            re_i : in  std_ulogic_vector(WORDWIDTH-1 downto 0);
            re_o : out std_ulogic_vector(WORDWIDTH-1 downto 0);

        -- Mock output (prevents instruction architecture from being optimized away at synthesis)
            instruction : out std_ulogic
    );

end entity toplevel;

architecture rtl of toplevel is
    -- State control signals
        signal err : std_ulogic;
        signal s  : clk_rec_t; -- slow clock

    -- Register bank source
        signal reg_err    :  std_ulogic;
        signal reg_cmd    :  std_ulogic_vector(1 downto 0);
        signal reg_addr   :  unsigned(REGD-1 downto 0);
        signal reg_i    :  std_ulogic_vector(WORDWIDTH-1 downto 0);
        signal reg_o   :  std_ulogic_vector(WORDWIDTH-1 downto 0);

    -- Register bank (mirror mode)
        signal rm_cmd    :  std_ulogic_vector(1 downto 0);
        signal rm_addr   :  unsigned(REGD-1 downto 0);
        signal rm_i    :  std_ulogic_vector(WORDWIDTH-1 downto 0);
        signal rm_o   :  std_ulogic_vector(WORDWIDTH-1 downto 0);
    -- Register bank (singular mode)
        signal rs_rd_a   :  std_ulogic;
        signal rs_rd_b   :  std_ulogic;
        signal rs_addr_a :  unsigned(REGD-1 downto 0);
        signal rs_addr_b :  unsigned(REGD-1 downto 0);
        signal rs_dout_a :  std_ulogic_vector(WORDWIDTH-1 downto 0);
        signal rs_dout_b :  std_ulogic_vector(WORDWIDTH-1 downto 0);

    -- Instruction bank
        signal ins_sta        :  std_ulogic_vector(1 downto 0);
        signal ins_cmd      :  std_ulogic_vector(1 downto 0);
        signal ins_addr     :  unsigned(INSTD-1 downto 0);
        signal ins_dout     :  std_ulogic_vector(EMBDWIDTH-1 downto 0);
        signal ins_o     :  inst_rec_t;
    
    -- Program Counter If
        signal pc_cmd :  std_ulogic_vector(1 downto 0);
        signal pc_ovr :  unsigned(INSTD-1 downto 0);
        signal pc_out :  unsigned(INSTD-1 downto 0);

    -- Address Resolution If
        signal arif_en     :  std_ulogic;
        signal arif_ins_o  :  inst_rec_t;

begin
    -- State Entities
        i_clkdiv : entity work.clkdiv
            generic map(
                CLOCKDIV => 5,
                C_WIDTH  => 3
            )
            port map(
                clki => clk,
                rst  => rst,
                en   => en,
                clko => s
        );

    -- Bank Entities
        regb : entity work.RegisterBank
            port map(
                clk    => clk,
                err    => reg_err,
                cmd    => reg_cmd,
                addr   => reg_addr,
                din    => reg_i,
                dout   => reg_o,
                rd_a   => rs_rd_a,
                rd_b   => rs_rd_b,
                addr_a => rs_addr_a,
                addr_b => rs_addr_b,
                dout_a => rs_dout_a,
                dout_b => rs_dout_b
        );

        instb : entity work.InstructionBankIf
            port map(
                clk      => clk,
                rst      => rst,
                ena      => s.en,
                o        => ins_sta,
                cmd      => ins_cmd,
                addr     => ins_addr,
                dout     => ins_dout,
                inst     => ins_o,
                ram_en   => ram_en,
                ram_wren => ram_wren,
                ram_mask => ram_mask,
                ram_addr => ram_addr,
                ram_dout => ram_dout
        );

    
    -- Multiplexers
        regb_mux : entity work.RegBankMuxIf
            port map(
                sel        => en,
                reg_cmd    => reg_cmd,
                reg_addr   => reg_addr,
                reg_i      => reg_i,
                reg_o      => reg_o,
                reg_0_cmd  => re_cmd, 
                reg_0_addr => re_addr,
                reg_0_i    => re_i,
                reg_0_o    => re_o,
                reg_1_cmd  => rm_cmd,
                reg_1_addr => rm_addr,
                reg_1_i    => rm_i,
                reg_1_o    => rm_o
        );
    
    -- Address Resolution
        arif : entity work.AddressResolutionIf
            port map(
                clk    => clk,
                rst    => rst,
                en     => arif_en,
                rd_a   => rs_rd_a,
                rd_b   => rs_rd_b,
                addr_a => rs_addr_a,
                addr_b => rs_addr_b,
                din_a  => rs_dout_a,
                din_b  => rs_dout_b,
                ins_i  => ins_o,
                ins_o  => arif_ins_o
        );



    -- Main Entities
        pcif : entity work.ProgramCounterIf
            port map(
                clk => s.o_n,
                rst => rst,
                en  => en,
                cmd => pc_cmd,
                ovr => pc_ovr,
                pc  => pc_out
        );



    -- Processes
    -- Logic
    err <= reg_err or ins_sta(0);
    o <= ins_sta(1) & err;

    pc_cmd <= en & '0';
    pc_ovr <= (others => '0');

    ins_cmd <= en & '0';
    ins_addr <= pc_out;

    arif_en <= s.advp or s.o;

    rm_cmd  <= "00";
    rm_addr <= (others => '0');
    rm_i    <= (others => '0');    
end architecture rtl;
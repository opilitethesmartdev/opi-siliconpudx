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

    -- Register bank (mirror mode)
        signal reg_err    :  std_ulogic;
        signal reg_cmd    :  std_ulogic_vector(1 downto 0);
        signal reg_addr   :  unsigned(REGD-1 downto 0);
        signal reg_din    :  std_ulogic_vector(WORDWIDTH-1 downto 0);
        signal reg_dout   :  std_ulogic_vector(WORDWIDTH-1 downto 0);
    -- Register bank (singular mode)
        signal rm_rd_a   :  std_ulogic;
        signal rm_rd_b   :  std_ulogic;
        signal rm_addr_a :  unsigned(REGD-1 downto 0);
        signal rm_addr_b :  unsigned(REGD-1 downto 0);
        signal rm_dout_a :  std_ulogic_vector(WORDWIDTH-1 downto 0);
        signal rm_dout_b :  std_ulogic_vector(WORDWIDTH-1 downto 0);

    -- Instruction bank
        signal ins_o        :  std_ulogic_vector(1 downto 0);
        signal cmd      :  std_ulogic_vector(1 downto 0);
        signal addr     :  unsigned(INSTD-1 downto 0);
        signal dout     :  std_ulogic_vector(EMBDWIDTH-1 downto 0);
        signal inst     :  inst_rec_t;


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
                din    => reg_din,
                dout   => reg_dout,
                rd_a   => rm_rd_a,
                rd_b   => rm_rd_b,
                addr_a => rm_addr_a,
                addr_b => rm_addr_b,
                dout_a => rm_dout_a,
                dout_b => rm_dout_b
        );

        instb : entity work.InstructionBankIf
            port map(
                clk      => clk,
                rst      => rst,
                o        => ins_o,
                cmd      => cmd,
                addr     => addr,
                dout     => dout,
                inst     => inst,
                ram_en   => ram_en,
                ram_wren => ram_wren,
                ram_mask => ram_mask,
                ram_addr => ram_addr,
                ram_dout => ram_dout
        );

    
    -- Processes
    -- Logic
    err <= reg_err or o(0);
    o <= ins_o(1) & err;
    
end architecture rtl;
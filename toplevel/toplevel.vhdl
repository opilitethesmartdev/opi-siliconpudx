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
        en : in  std_ulogic; -- [en] 
        o  : out std_ulogic_vector(1 downto 0); -- [done][err]
        
        -- Instruction bank
        inst_cmd  : in std_ulogic_vector(1 downto 0);
        inst_addr : in unsigned(INSTD-1 downto 0);
        inst_i : in  std_ulogic_vector(INSTW-1 downto 0);
        inst_o : out std_ulogic_vector(INSTW-1 downto 0); 
        
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
        signal oi : std_ulogic;
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
    
    -- Processes
    -- Logic
    o <= '0' & reg_err;
end architecture rtl;
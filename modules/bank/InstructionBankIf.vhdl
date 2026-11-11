----------------------------------------------------------------------------
-- Project		:	OPI-siliconPUdx
-- Authors		:	opilitethesmartdev
-- Description	:	Instruction bank
----------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.core_pkg.all;
use work.register_pkg.all;
use work.instruction_pkg.all;

entity InstructionBankIf is
    port (
        clk : in std_ulogic;
        rst : in std_ulogic;
        o : out std_ulogic_vector(1 downto 0); -- [stp][nop]
        
        cmd  : in  std_ulogic_vector(1 downto 0); --[read][write]; xor = en
        addr : in  unsigned(INSTD - 1 downto 0); 

        dout : out std_ulogic_vector(EMBDWIDTH - 1 downto 0);  
        inst : out inst_rec_t;  
        
        ram_en   : out std_ulogic;
        ram_wren : out std_ulogic;
        ram_mask : out std_ulogic_vector(IBWIDTH - 1 downto 0);
        ram_addr : out unsigned(INSTD - 1 downto 0);
        ram_dout : in std_ulogic_vector(IBWIDTH - 1 downto 0)
    );
end entity InstructionBankIf;

architecture rtl of InstructionBankIf is
    signal en, edr, eni : std_ulogic;
    signal isstp, isnop : std_ulogic;
begin
    en <= or cmd;
    edr <= and cmd;
    eni <= en and not edr;

    nopfinff : entity work.sr_ff
        port map(
            clk => clk,
            s   => isnop,
            r   => rst,
            o   => o(0)
    );

    ram_en <= en;
    ram_wren <= '1' when cmd = "01" else '0';

    ram_addr <= addr when en = '1' else (others => '0');  
    ram_mask <= (others => '1') when en = '1' else (others => '0');  
  
    dout <= ram_dout(IBWIDTH - 1 downto INSTW) when edr = '1' else (others => '0');  
    inst <= v2inst(ram_dout(INSTW - 1 downto 0)) when eni = '1' else INSTNULL;  

    isnop <= '1' when v2inst(ram_dout(INSTW - 1 downto 0)).cmd = nop and (eni = '1') else '0';
    isstp <= '1' when v2inst(ram_dout(INSTW - 1 downto 0)).cmd = stp and (eni = '1') else '0';
    o(1) <= isstp;
end architecture rtl;
----------------------------------------------------------------------------
-- Project		:	OPI-siliconPUdx
-- Authors		:	opilitethesmartdev
-- Description	:	Register Access Dual Mux
----------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.core_pkg.all;
use work.register_pkg.all;
use work.instruction_pkg.all;

entity RegBankMuxIf is
    port (
        sel : in std_ulogic;
        
        -- Source Interface
        reg_cmd  : out std_ulogic_vector(1 downto 0);
        reg_addr : out unsigned(REGD-1 downto 0);
        reg_i : out std_ulogic_vector(WORDWIDTH-1 downto 0);
        reg_o : in  std_ulogic_vector(WORDWIDTH-1 downto 0);
        
        -- Interface 0
        reg_0_cmd  : in std_ulogic_vector(1 downto 0);
        reg_0_addr : in unsigned(REGD-1 downto 0);
        reg_0_i : in  std_ulogic_vector(WORDWIDTH-1 downto 0);
        reg_0_o : out std_ulogic_vector(WORDWIDTH-1 downto 0);
        
        -- Interface 1
        reg_1_cmd  : in std_ulogic_vector(1 downto 0);
        reg_1_addr : in unsigned(REGD-1 downto 0);
        reg_1_i : in  std_ulogic_vector(WORDWIDTH-1 downto 0);
        reg_1_o : out std_ulogic_vector(WORDWIDTH-1 downto 0)
    );
end entity RegBankMuxIf;

architecture rtl of RegBankMuxIf is
begin
    reg_cmd <= reg_0_cmd when sel = '0' else reg_1_cmd;
    reg_addr <= reg_0_addr when sel = '0' else reg_1_addr;
    reg_i <= reg_0_i when sel = '0' else reg_1_i;

    reg_0_o <= reg_o when sel = '0' else (others => '0');
    reg_1_o <= reg_o when sel = '1' else (others => '0');
end rtl;

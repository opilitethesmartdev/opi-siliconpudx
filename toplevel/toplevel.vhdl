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
        en : in std_ulogic_vector(1 downto 0); -- [imode][en] 
        
        -- Instruction bank
        inst_cmd  : in std_ulogic_vector(1 downto 0);
        inst_addr : in unsigned(INSTD-1 downto 0);
        inst_i : in  std_ulogic_vector(INSTW-1 downto 0);
        inst_o : out std_ulogic_vector(INSTW-1 downto 0)
    );

end entity toplevel;

architecture rtl of toplevel is
    signal inten : std_ulogic_vector(1 downto 0);

    signal ins_cmd  : std_ulogic_vector(1 downto 0);
    signal ins_addr : unsigned(INSTD-1 downto 0);
    signal ins_i : std_ulogic_vector(INSTW-1 downto 0);
    signal ins_o : std_ulogic_vector(INSTW-1 downto 0);

begin
    enff : process(rst, clk) begin
        if rst = '1' then inten <= "00";
        elsif rising_edge(clk) then inten <= en;
        end if;
    end process enff;

    inst : entity work.InstructionBank
        port map(
            clk  => clk,
            cmd  => ins_cmd,
            addr => ins_addr,
            din  => ins_i,
            dout => ins_o
    );

    ins_cmd  <= inst_cmd when en(0) = '0' else en;
    ins_addr <= inst_addr when en(0) = '0' else (others => '0');
    ins_i    <= inst_i when en(0) = '0' else (others => '0');

    inst_o <= ins_o when en(0) = '0' else (others => '0');

end architecture rtl;
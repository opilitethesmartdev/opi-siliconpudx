----------------------------------------------------------------------------
-- Project		:	OPI-siliconPUdx
-- Authors		:	opilitethesmartdev
-- Description	:	Instruction bank
----------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.instruction_pkg.all;

entity InstructionBank is
    port(
        -- Fundamental signals
        clk : in std_ulogic;
        rst : in std_ulogic;
        fin : out std_ulogic;
        err : out std_ulogic;

        -- Instruction rw interface
        cmd  : in std_ulogic_vector(1 downto 0);        -- read / write cmd ([read][write], xor = enable)
        addr : in unsigned(INST_DEPTH - 1 downto 0);
        insi :  in std_ulogic_vector(INST_WIDTH - 1 downto 0);
        inso : out inst_rec_t
    );
end entity InstructionBank;

architecture mock of InstructionBank is
    signal en : std_ulogic;
    signal inst : inst_array_t := (
                newinst(3, isz, 0),
                newinst(0, jmp, 3),
                newinst(0, stp, 0),
                newinst(2, dec, 0),
                newinst(2, inc, 4),
                newinst(0, jmp, 0),
        others => INSTNULL
    );
begin
    en <= cmd(1) and not rst;
    inso <= v2inst(inst(to_integer(addr))) when en = '1' else v2inst(INSTNULL);
    fin  <= '1' when en = '1' and (
        inst2cmd(inst(to_integer(addr))) = stp or 
        inst2cmd(inst(to_integer(addr))) = nop
        ) else '0';
    err  <= '1' when en = '1' and inst2cmd(inst(to_integer(addr))) = nop else '0';
end architecture mock;
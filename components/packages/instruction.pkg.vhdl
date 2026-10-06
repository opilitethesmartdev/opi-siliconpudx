----------------------------------------------------------------------------
-- Project		:	OPI-siliconPUdx
-- Authors		:	opilitethesmartdev
-- Description	:	Instruction utils package
----------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.MATH_REAL.all;

use work.core_pkg.all;

package instruction_pkg is
    -- Constants
    constant INST_DEPTH : natural := 2;

    constant IPTR_WIDTH  : natural := 2;  
    constant ICMD_WIDTH  : natural := 6;    
    constant PARAM_WIDTH : natural := WORDWIDTH; 
    constant INST_WIDTH : natural := IPTR_WIDTH + ICMD_WIDTH + PARAM_WIDTH;

    -- Instruction Array
    type inst_array_t is array(0 to 2**INST_DEPTH-1) of std_ulogic_vector(INST_WIDTH - 1 downto 0);
    constant INSTNULL  : std_ulogic_vector(INST_WIDTH - 1 downto 0) := (others => '0'); 

    -- Command helper types
    type command_t is (nop, inc, dec, jmp, isz, stp);

    type inst_rec_t is record
        ptr : std_ulogic_vector(IPTR_WIDTH - 1 downto 0);
        cmd : command_t;
        prm : std_ulogic_vector(PARAM_WIDTH - 1 downto 0);
    end record;

    type cmd_array_t is array (0 to 2**ICMD_WIDTH-1) of command_t;
    constant COMMANDS : cmd_array_t := (nop, inc, dec, jmp, isz, stp, others => nop);


    -- Functions
    function inst2cmd ( i : std_ulogic_vector(INST_WIDTH - 1 downto 0) ) 
            return command_t;
    function cmd2inst ( i : command_t ) 
            return std_ulogic_vector;

    function v2inst ( i : std_ulogic_vector(INST_WIDTH - 1 downto 0) ) 
            return inst_rec_t;
    function inst2v ( i : inst_rec_t ) 
            return std_ulogic_vector;

    function newinst (  ptr : natural;
                        cmd : command_t;
                        prm : natural ) 
            return std_ulogic_vector;
    
end package instruction_pkg;

package body instruction_pkg is
    
    function inst2cmd ( i : std_ulogic_vector(INST_WIDTH - 1 downto 0) ) 
        return command_t is
        begin
            return COMMANDS(to_integer(unsigned(i((ICMD_WIDTH + PARAM_WIDTH) - 1 downto PARAM_WIDTH))));
    end function;
    function cmd2inst ( i : command_t ) 
        return std_ulogic_vector is
        begin
            case(i) is
                when nop => return std_ulogic_vector(to_unsigned(0, ICMD_WIDTH));
                when inc => return std_ulogic_vector(to_unsigned(1, ICMD_WIDTH));
                when dec => return std_ulogic_vector(to_unsigned(2, ICMD_WIDTH));
                when jmp => return std_ulogic_vector(to_unsigned(3, ICMD_WIDTH));
                when isz => return std_ulogic_vector(to_unsigned(4, ICMD_WIDTH));
                when stp => return std_ulogic_vector(to_unsigned(5, ICMD_WIDTH));
            end case;
    end function;
    
    function v2inst ( i : std_ulogic_vector(INST_WIDTH - 1 downto 0) ) 
        return inst_rec_t is
            variable ocmd : command_t := nop;
            variable optr : std_ulogic_vector(IPTR_WIDTH - 1 downto 0);
            variable oprm : std_ulogic_vector(PARAM_WIDTH - 1 downto 0);
        begin
            optr := i(INST_WIDTH - 1 downto ICMD_WIDTH + PARAM_WIDTH);
            ocmd := inst2cmd(i);
            oprm := i(PARAM_WIDTH - 1 downto 0);
        return (ptr => optr, cmd => ocmd, prm => oprm);
    end function;
    function inst2v ( i : inst_rec_t ) 
        return std_ulogic_vector is
        begin
        return newinst(natural(to_integer(unsigned(i.ptr))), i.cmd, natural(to_integer(unsigned(i.prm))));
    end function;

    function newinst (  ptr : natural;
                        cmd : command_t;
                        prm : natural) 
        return std_ulogic_vector is
            variable optr : std_ulogic_vector(IPTR_WIDTH - 1 downto 0);
            variable ocmd : std_ulogic_vector(ICMD_WIDTH - 1 downto 0);
            variable oprm : std_ulogic_vector(PARAM_WIDTH - 1 downto 0);
        begin
            optr := std_ulogic_vector(to_unsigned(ptr, IPTR_WIDTH));
            ocmd := cmd2inst(cmd);
            oprm := std_ulogic_vector(to_unsigned(prm, PARAM_WIDTH));
            return  optr & ocmd & oprm;
    end function;

end package body;
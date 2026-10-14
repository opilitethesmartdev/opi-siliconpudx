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
    constant IPTRW  : natural := 2;  
    constant ICMDW  : natural := 4;    
    constant PARAMW : natural := WORDWIDTH; 
    constant PARAMS : natural := 2;
    constant INSTW  : natural := IPTRW*PARAMS + ICMDW + PARAMW*PARAMS; --24

    constant INSTD : natural := WORDWIDTH;

        -- Command helper types
    type command_t is (nop, inc, dec, jmp, isz, stp);

    type inst_rec_t is record
        depth0 : unsigned(IPTRW - 1 downto 0);
        depth1 : unsigned(IPTRW - 1 downto 0);
        cmd    : command_t;
        param0 : std_ulogic_vector(PARAMW - 1 downto 0);
        param1 : std_ulogic_vector(PARAMW - 1 downto 0);
    end record;

    type cmd_array_t is array (0 to 2**ICMDW-1) of command_t;
    constant COMMANDS : cmd_array_t := (nop, inc, dec, jmp, isz, stp, others => nop);

    function inst2cmd ( i : std_ulogic_vector(INSTW - 1 downto 0) ) 
        return command_t;
    function cmd2inst ( i : command_t ) 
            return std_ulogic_vector;

    function v2inst ( i : std_ulogic_vector(INSTW - 1 downto 0) ) 
            return inst_rec_t;
    function inst2v ( i : inst_rec_t ) 
            return std_ulogic_vector;

    function newinst (  depth0 : natural;
                        depth1 : natural;
                        cmd  : command_t;
                        param0 : natural;
                        param1 : natural ) 
            return std_ulogic_vector;
end package instruction_pkg;

package body instruction_pkg is
    
    function inst2cmd ( i : std_ulogic_vector(INSTW - 1 downto 0) ) 
        return command_t is
        begin
            return COMMANDS(to_integer(unsigned(i(ICMDW + PARAMW*PARAMS - 1 downto PARAMW*PARAMS))));
    end function;
    function cmd2inst ( i : command_t ) 
        return std_ulogic_vector is
        begin
            case(i) is
                when nop => return std_ulogic_vector(to_unsigned(0, ICMDW));
                when inc => return std_ulogic_vector(to_unsigned(1, ICMDW));
                when dec => return std_ulogic_vector(to_unsigned(2, ICMDW));
                when jmp => return std_ulogic_vector(to_unsigned(3, ICMDW));
                when isz => return std_ulogic_vector(to_unsigned(4, ICMDW));
                when stp => return std_ulogic_vector(to_unsigned(5, ICMDW));
            end case;
    end function;
    
    function v2inst ( i : std_ulogic_vector(INSTW - 1 downto 0) ) 
        return inst_rec_t is
            variable odpt0 : unsigned(IPTRW - 1 downto 0);
            variable odpt1 : unsigned(IPTRW - 1 downto 0);
            variable ocmd : command_t;
            variable oprm0 : std_ulogic_vector(PARAMW - 1 downto 0);
            variable oprm1 : std_ulogic_vector(PARAMW - 1 downto 0);
        begin
            odpt0 := unsigned(i(INSTW - 1 downto IPTRW + ICMDW + PARAMW*PARAMS));
            odpt1 := unsigned(i(IPTRW + ICMDW + PARAMW*PARAMS - 1 downto ICMDW + PARAMW*PARAMS));
            ocmd := inst2cmd(i);
            oprm0 := i(PARAMW*PARAMS - 1 downto PARAMW);
            oprm1 := i(PARAMW - 1 downto 0);
        return (depth0 => odpt0, depth1 => odpt1, cmd => ocmd, param0 => oprm0, param1 => oprm1);
    end function;

    function inst2v ( i : inst_rec_t ) 
        return std_ulogic_vector is
        begin
        return std_ulogic_vector(i.depth0) & std_ulogic_vector(i.depth1) & cmd2inst(i.cmd) & i.param0 & i.param1;
    end function;

    function newinst (  depth0 : natural;
                        depth1 : natural;
                        cmd  : command_t;
                        param0 : natural;
                        param1 : natural )
        return std_ulogic_vector is
            variable odpt0 : std_ulogic_vector(IPTRW - 1 downto 0);
            variable odpt1 : std_ulogic_vector(IPTRW - 1 downto 0);
            variable ocmd : std_ulogic_vector(ICMDW - 1 downto 0);
            variable oprm0 : std_ulogic_vector(PARAMW - 1 downto 0);
            variable oprm1 : std_ulogic_vector(PARAMW - 1 downto 0);
        begin
            odpt0 := std_ulogic_vector(to_unsigned(depth0, IPTRW));
            odpt1 := std_ulogic_vector(to_unsigned(depth1, IPTRW));
            ocmd := cmd2inst(cmd);
            oprm0 := std_ulogic_vector(to_unsigned(param0, PARAMW));
            oprm1 := std_ulogic_vector(to_unsigned(param1, PARAMW));
            return  odpt0 & odpt1 & ocmd & oprm0 & oprm1;
    end function;

end package body;

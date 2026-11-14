----------------------------------------------------------------------------
-- Project		:	OPI-siliconPUdx
-- Authors		:	opilitethesmartdev
-- Description	:	Address Resolution Engine
----------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.core_pkg.all;
use work.register_pkg.all;
use work.instruction_pkg.all;

entity AddressResolutionEngine is
    port (
        -- Fundamental signals
        clk : in std_ulogic;
        rst : in std_ulogic;
        en  : in std_ulogic;

        -- Register singular access
        rd : out std_ulogic;
        addr : out unsigned(REGD - 1 downto 0);        
        din : in std_ulogic_vector(WORDWIDTH - 1 downto 0);

        -- Input/Output
        i_d : in  unsigned(IPTRW - 1 downto 0);
        i_p : in  std_ulogic_vector(PARAMW - 1 downto 0);
        o_p : out std_ulogic_vector(PARAMW - 1 downto 0)
    );
end entity AddressResolutionEngine;

architecture rtl of AddressResolutionEngine is
    type s_t is (idl, set, res, push, fin);
    signal s, sn : s_t;

    signal cd, cdn : unsigned(IPTRW downto 0);
    signal op, opn : std_ulogic_vector(PARAMW - 1 downto 0);
    signal op_padding : std_ulogic_vector(PARAMW - WORDWIDTH - 1 downto 0) := (others => '0');
begin

    seq : process(rst,clk)
    begin
        if rst = '1' then
            s <= idl;
            cd <= (others => '0');
            op <= (others => '0');
        elsif rising_edge(clk) then
            s <= sn;
            cd <= cdn;
            op <= opn;
        end if;
    end process seq;

    fsm : process(s, en, i_d, cd)
    begin
        case s is
            when idl => sn <= set when en = '1' else idl;
            when set => sn <= res;-- when cd > 0   else set;
            when res => sn <= push when cd = i_d else res;
            when push => sn <= fin;--when cd = i_d + 1 else res;
            when fin => sn <= idl when en = '0' else fin;
        end case;
    end process fsm;

    main : process(s,  cd, i_p, din, op, op_padding)
    begin
        rd <= '0';
        addr <= (others => '0');
        cdn <= cd;
        opn <= op;

        case s is
            when idl => 
            when set =>
                rd <= '1';
                addr <= unsigned(i_p(REGD - 1 downto 0));

                cdn <= cd + 1;
            when res =>
                rd <= '1';
                addr <= unsigned(din(REGD - 1 downto 0));
                
                cdn <= cd + 1;
            when push =>        
                rd <= '1';         
                cdn <= cd + 1;

                opn <= op_padding & din;
            when fin => 
        end case;
    end process main;

    o_p <= op;
    
end architecture rtl;
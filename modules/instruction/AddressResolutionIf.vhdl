----------------------------------------------------------------------------
-- Project		:	OPI-siliconPUdx
-- Authors		:	opilitethesmartdev
-- Description	:	Address resolution interface
----------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.core_pkg.all;
use work.register_pkg.all;
use work.instruction_pkg.all;

entity AddressResolutionIf is
    port(
        -- Fundamental signals
        clk : in std_ulogic;
        rst : in std_ulogic;
        en  : in std_ulogic;
        fin : out std_ulogic;

        -- current instruction
        ins_i : in inst_rec_t;

        -- Register rw interface
        rd : out std_ulogic;
        addr : out unsigned(REGDEPTH - 1 downto 0);
        regi : in std_ulogic_vector(REGWIDTH - 1 downto 0);

        -- resolved instruction
        ins_o : out inst_rec_t
        
    );
end entity AddressResolutionIf;

architecture bhv of AddressResolutionIf is
    signal d : std_ulogic;
    signal depth : unsigned(IPTR_WIDTH downto 0); -- we want the extra bit
    --signal int : std_ulogic_vector(PARAM_WIDTH - 1 downto 0);
begin
    seq : process(rst, clk)
    variable int : std_ulogic_vector(PARAM_WIDTH - 1 downto 0);
    begin
        if rst = '1' then
            d <= '0';
            depth <= (others => '0');
            int := (others => '0');
            ins_o <= v2inst(INSTNULL);
        elsif rising_edge(clk) then
            if d = '0' and en = '1' then
                rd <= '1';
                int := regi(WORDWIDTH - 1 downto 0);

                if depth = 0 then
                    addr <= resize(unsigned(ins_i.prm), REGDEPTH);
                    int := ins_i.prm;
                else                
                    addr <= resize(unsigned(int), REGDEPTH);
                end if;

                if depth < resize(unsigned(ins_i.ptr), IPTR_WIDTH + 1) then
                    depth <= depth + 1;
                else
                    d <= '1';
                    ins_o <= (ptr => ins_i.ptr, cmd => ins_i.cmd, prm => (int));
                end if;
            end if;
        end if;
    end process seq;

    fin <= d;
end architecture bhv;
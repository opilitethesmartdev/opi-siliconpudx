----------------------------------------------------------------------------
-- Project		:	OPI-siliconPUdx
-- Authors		:	opilitethesmartdev
-- Description	:	ExecutionUnit

----------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.core_pkg.all;
use work.register_pkg.all;
use work.instruction_pkg.all;

entity ExecutionUnit is
    port(
        -- Fundamental signals
        clk : in std_ulogic;
        rst : in std_ulogic;
        en  : in std_ulogic;
        fin : out std_ulogic;
        
        -- Register interface
        rcmd : out std_ulogic_vector(2 downto 0);
        addr : out unsigned(REGD - 1 downto 0);
        dout : out std_ulogic_vector(WORDWIDTH - 1 downto 0);
        din  : in  std_ulogic_vector(WORDWIDTH - 1 downto 0);

        -- Input command
        inst : in std_ulogic_vector(INSTW - 1 downto 0);
        
        -- Program Counter interface
        pc_cmd : out std_ulogic_vector(1 downto 0); --[nxt][skip], and = ovr
        pc_ovr : out unsigned(INSTD - 1 downto 0)
    );
end entity ExecutionUnit;

architecture rtl of ExecutionUnit is
    signal p, d : std_ulogic;
    signal dint : std_ulogic_vector(WORDWIDTH - 1 downto 0);
begin 
    seq : process(rst, clk)
        variable internal : unsigned(WORDWIDTH - 1 downto 0);
    begin
        if rst = '1' then
            rcmd <= "000";
            addr <= (others => '0');
            dint <= (others => '0');
            dout <= (others => '0');

            pc_cmd <= "00";
            pc_ovr <= (others => '0');

            p <= '0';
            d <= '0';
        elsif rising_edge(clk) then
            pc_cmd <= "00";
            if en = '1' and d = '0' then
                case (v2inst(inst).cmd) is
                    when jmp => d <= '1';
                        pc_cmd <= "11";
                        pc_ovr <= unsigned(v2inst(inst).param0);
                    when inc =>
                        if p = '0' then
                            pc_cmd <= "10";

                            rcmd <= "010";
                            addr <= unsigned(v2inst(inst).param0(REGD - 1 downto 0));
                            dint <= din;
                            p <= '1';
                        elsif p = '1' then
                            rcmd <= "001";
                            addr <= unsigned(v2inst(inst).param0(REGD - 1 downto 0));

                            if unsigned(v2inst(inst).param1) = 0 then
                                dout <= std_ulogic_vector(unsigned(dint) + 1);
                            else
                                dout <= std_ulogic_vector(unsigned(dint) + unsigned(v2inst(inst).param1));
                            end if;
                            
                            d <= '1';
                        end if;
                    when dec =>
                        if p = '0' then
                            pc_cmd <= "10";

                            rcmd <= "010";
                            addr <= unsigned(v2inst(inst).param0(REGD - 1 downto 0));
                            dint <= din;
                            p <= '1';
                        elsif p = '1' then
                            rcmd <= "01";
                            addr <= unsigned(v2inst(inst).param0(REGD - 1 downto 0));

                            if unsigned(v2inst(inst).param1) = 0 then
                                dout <= std_ulogic_vector(unsigned(dint) - 1);
                            else
                                dout <= std_ulogic_vector(unsigned(dint) - unsigned(v2inst(inst).param1));
                            end if;
                            
                            d <= '1';
                        end if;
                    when isz =>
                        if p = '0' then
                            rcmd <= "010";
                            addr <= unsigned(v2inst(inst).param0(REGD - 1 downto 0));
                            dint <= din;
                            p <= '1';
                        elsif p = '1' then
                            internal := unsigned(dint) - unsigned(v2inst(inst).param0);

                            if internal = 0 then
                                pc_cmd <= "01";
                            else
                                pc_cmd <= "10";
                            end if;

                            d <= '1';
                        end if;
                    when others =>
                end case;
            end if;
        end if;
    end process seq;

    fin <= d;
end architecture rtl;
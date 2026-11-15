----------------------------------------------------------------------------
-- Project		:	OPI-siliconPUdx
-- Authors		:	opilitethesmartdev
-- Description	:	Execution Unit
----------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.core_pkg.all;
use work.register_pkg.all;
use work.instruction_pkg.all;

entity ExecutionUnit is
    port (
        clk : in std_ulogic;
        rst : in std_ulogic;
        en  : in std_ulogic;
        
        -- PCIf
        pc_cmd : out std_ulogic_vector(1 downto 0);
        pc_ovr : out unsigned(INSTD - 1 downto 0);

        -- RegisterBank mirrored access
        reg_cmd  : out std_ulogic_vector(1 downto 0); --[read][write]; xor = en
        reg_addr : out unsigned(REGD - 1 downto 0); 
        reg_din  : out std_ulogic_vector(WORDWIDTH - 1 downto 0);
        reg_dout : in  std_ulogic_vector(WORDWIDTH - 1 downto 0);

        -- InstructionBank embedded data access        
        rden : out std_ulogic;
        addr : out unsigned(INSTD - 1 downto 0); 
        dout : in  std_ulogic_vector(EMBDWIDTH - 1 downto 0);  

        -- Current instruction
        ins_i : in inst_rec_t
    );
end entity ExecutionUnit;

architecture rtl of ExecutionUnit is
    signal phase : unsigned(3 downto 0);
    signal temp, tempff  : std_ulogic_vector(WORDWIDTH - 1 downto 0);
begin
    phaseff: process(clk)
    begin
        if rising_edge(clk) then
            if en = '1' then
                phase <= phase + 1;
                tempff <= temp;
            else
                phase <= (others => '1');
                tempff <= (others => '0');
            end if;
        end if;
    end process phaseff;

    main: process(all)
        variable merged : std_ulogic_vector(PARAMW * 2 - 1 downto 0);
        variable param1valid : std_ulogic_vector(WORDWIDTH - 1 downto 0);
    begin
        merged := ins_i.param0 & ins_i.param1;
        param1valid := ins_i.param1(PARAMW - 1) and ins_i.param1(WORDWIDTH - 1 downto 0);
        
        pc_cmd <= "00";
        pc_ovr <= (others => '0');

        reg_cmd  <= "00";
        reg_addr <= (others => '0');
        reg_din  <= (others => '0');
        
        rden  <= '0';
        addr <= (others => '0');

        if en = '1' then
            case ins_i.cmd is
                when nop =>
                when stp =>
                when jmp =>    
                    case phase is
                        when x"1" =>
                            pc_cmd <= "11";
                            pc_ovr <= resize(unsigned(merged), INSTD);
                        when others =>
                    end case;
                when isz =>    
                    case phase is
                        when x"1" =>
                            reg_cmd  <= "10";
                            reg_addr <= unsigned(ins_i.param0(REGD - 1 downto 0));
                        when x"3" =>
                            if ins_i.param1(PARAMW-1) = '1' then
                                pc_cmd <= "01" when reg_dout = ins_i.param1(WORDWIDTH - 1 downto 0) else "10";
                            else
                                pc_cmd <= "01" when reg_dout = x"00" else "10";
                            end if;
                        when others =>
                    end case;
                when dec =>    
                    case phase is
                        when x"1" =>
                            pc_cmd <= "10";

                            reg_cmd  <= "10";
                            reg_addr <= unsigned(ins_i.param0(REGD - 1 downto 0));
                        when x"2" =>
                            reg_cmd  <= "10";
                            reg_addr <= unsigned(ins_i.param0(REGD - 1 downto 0));
                        when x"3" =>
                            reg_cmd  <= "01";
                            reg_addr <= unsigned(ins_i.param0(REGD - 1 downto 0));
                            if ins_i.param1(PARAMW-1) = '1' then
                                reg_din <= std_ulogic_vector(unsigned(reg_dout) - unsigned(ins_i.param0(WORDWIDTH - 1 downto 0)));
                            else
                                reg_din <= std_ulogic_vector(unsigned(reg_dout) - 1);
                            end if;
                        when others =>
                    end case;
                when inc =>    
                    case phase is
                        when x"1" =>
                            pc_cmd <= "10";

                            reg_cmd  <= "10";
                            reg_addr <= unsigned(ins_i.param0(REGD - 1 downto 0));
                        when x"2" =>
                            reg_cmd  <= "10";
                            reg_addr <= unsigned(ins_i.param0(REGD - 1 downto 0));
                        when x"3" =>
                            reg_cmd  <= "01";
                            reg_addr <= unsigned(ins_i.param0(REGD - 1 downto 0));
                            if ins_i.param1(PARAMW-1) = '1' then
                                reg_din <= std_ulogic_vector(unsigned(reg_dout) + unsigned(ins_i.param0(WORDWIDTH - 1 downto 0)));
                            else
                                reg_din <= std_ulogic_vector(unsigned(reg_dout) + 1);
                            end if;
                        when others =>
                    end case;
                when ldd =>    
                    case phase is
                        when x"0" =>
                            rden  <= '1';
                            addr <= unsigned(ins_i.param0(INSTD - 1 downto 0));
                        when x"1" =>
                            rden  <= '1';
                            addr <= unsigned(ins_i.param0(INSTD - 1 downto 0)) + 1;

                            temp <= dout & x"0";
                        when x"2" =>
                            rden  <= '1';
                            temp(EMBDWIDTH - 1 downto 0) <= dout;
                        when x"3" =>
                            pc_cmd <= "10";

                            reg_cmd  <= "01";
                            reg_addr <= unsigned(ins_i.param1(REGD - 1 downto 0));
                            reg_din <= temp;
                        when others =>
                    end case;
                when others =>
                    case phase is
                        when x"1" => pc_cmd <= "10";
                        when others =>
                    end case;
            end case;
        end if;
    end process main;
end rtl; -- rtl
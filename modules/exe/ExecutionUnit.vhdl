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
        insb_rden : out std_ulogic;
        insb_addr : out unsigned(INSTD - 1 downto 0); 
        insb_dout : in  std_ulogic_vector(EMBDWIDTH - 1 downto 0); 
        
        -- Accumulator interface
        acc_rw : out std_ulogic_vector(1 downto 0); --[read][write]; xor = en; and = soft rst
        acc_di : out std_ulogic_vector(WORDWIDTH - 1 downto 0);
        acc_do : in  std_ulogic_vector(WORDWIDTH - 1 downto 0);

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
    begin
        merged := ins_i.param0 & ins_i.param1;
        
        pc_cmd <= "00";
        pc_ovr <= (others => '0');

        reg_cmd  <= "00";
        reg_addr <= (others => '0');
        reg_din  <= (others => '0');
        
        insb_rden  <= '0';
        insb_addr <= (others => '0');
        
        temp <= tempff;

        acc_rw  <= "00";
        acc_di <= (others => '0');

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
                            pc_cmd <= "01" when reg_dout = ins_i.param1 else "10";
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
                            reg_din <= std_ulogic_vector(unsigned(reg_dout) - unsigned(ins_i.param1));
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
                                reg_din <= std_ulogic_vector(unsigned(reg_dout) + unsigned(ins_i.param1));
                        when others =>
                    end case;
                when lda =>    
                    case phase is
                        when x"1" =>
                            insb_rden  <= '1';
                            insb_addr <= unsigned(merged(INSTD - 1 downto 0));
                        when x"2" =>
                            insb_rden  <= '1';
                            
                            insb_addr <= unsigned(merged(INSTD - 1 downto 0));
                            temp <= insb_dout;
                        when x"3" =>
                            --insb_rden  <= '1';
                            pc_cmd <= "10";
                            acc_rw  <= "01";
                            acc_di <= tempff;
                        when others =>
                    end case;
                when atr =>    
                    case phase is
                        when x"1" =>
                            pc_cmd <= "10";

                            acc_rw  <= "10";
                        when x"2" =>
                            acc_rw <= "11";

                            reg_cmd  <= "01";
                            reg_addr <= unsigned(ins_i.param0(REGD - 1 downto 0));
                            reg_din <= std_ulogic_vector(unsigned(acc_do));
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
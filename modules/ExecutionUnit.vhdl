----------------------------------------------------------------------------
-- Project		:	OPI-siliconPUdx
-- Authors		:	opilitethesmartdev
-- Description	:	Main execution logic
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
        en : in std_ulogic;

        -- current instruction
        ins_i : in inst_rec_t;

        -- Register rw interface
        reg_cmd : out std_ulogic_vector(1 downto 0);    -- read / write cmd ([read][write], xor = enable)
        reg_addr : out unsigned(REGDEPTH - 1 downto 0);
        reg_o : out std_ulogic_vector(REGWIDTH - 1 downto 0);
        reg_i : in std_ulogic_vector(REGWIDTH - 1 downto 0);

        -- Program counter if
        pc_ctrl : out std_ulogic_vector(1 downto 0); -- [en][ovr], and ctrl => skip
        pc_ovr  : out unsigned(INST_DEPTH - 1 downto 0)

    );
end entity ExecutionUnit;

architecture bhv of ExecutionUnit is
    signal rmphase, rmphase2 : std_ulogic; -- register modify phase (kinda state machine for inc & dec)
    signal rmtemp  : std_ulogic_vector(REGWIDTH - 1 downto 0);
begin
i_n_shift1b : entity work.n_shift1b
    generic map(
        DELAY => 1
    )
    port map(
        clk => clk,
        rst => rst,
        i   => rmphase,
        o   => rmphase2
);


    seq: process(rst, clk)
    begin
        if rst = '1' then
            pc_ctrl <= "10";
            pc_ovr <= (others => '0');

            rmphase <= '0';

            reg_cmd <=  "00";
            reg_addr <= (others => '0');
            reg_o <=    (others => '0');
        elsif rising_edge(clk) then
            if en = '1' then
                pc_ctrl <= "10";

                case(ins_i.cmd) is
                    when nop =>
                    when stp =>
                    when inc =>
                        if rmphase2 = '0' then
                            rmphase <= '1';
                            reg_cmd <= "10";
                            reg_addr <= resize(unsigned(ins_i.prm), REGDEPTH);
                            rmtemp <= reg_i;
                        else
                            reg_cmd <= "01";
                            reg_addr <= resize(unsigned(ins_i.prm), REGDEPTH);
                            reg_o <= rmtemp(REGWIDTH - 1 downto WORDWIDTH) & std_ulogic_vector(unsigned(rmtemp(WORDWIDTH - 1 downto 0)) + 1);
                        end if;
                    when dec =>
                        if rmphase2 = '0' then
                            rmphase <= '1';
                            reg_cmd <= "10";
                            reg_addr <= resize(unsigned(ins_i.prm), REGDEPTH);
                            rmtemp <= reg_i;
                        else
                            reg_cmd <= "01";
                            reg_addr <= resize(unsigned(ins_i.prm), REGDEPTH);
                            reg_o <= rmtemp(REGWIDTH - 1 downto WORDWIDTH) & std_ulogic_vector(unsigned(rmtemp(WORDWIDTH - 1 downto 0)) - 1);
                        end if;
                    when jmp =>
                        pc_ctrl <= "01";
                        pc_ovr <= resize(unsigned(ins_i.prm), INST_DEPTH);
                    when isz =>
                        if unsigned(ins_i.prm) = 0 then
                            pc_ctrl <= "11";
                        end if;
                end case;
            end if;
        end if;
    end process seq;
end architecture bhv;
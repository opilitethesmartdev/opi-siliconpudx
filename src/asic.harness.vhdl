----------------------------------------------------------------------------
-- Project		:	OPI-siliconPUdx
-- Authors		:	opilitethesmartdev
-- Description	:	ASIC harness
----------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.core_pkg.all;
use work.register_pkg.all;
use work.instruction_pkg.all;

entity asic_harness is
    port(
        -- Fundamental signals
        clk : in std_ulogic; -- fast clock
        rst : in std_ulogic;
        en : in std_ulogic;
        o  : out std_ulogic_vector(1 downto 0); -- ([done][error])

        -- Data IO Interface
        tick : in std_ulogic;
        rw : in std_ulogic_vector(1 downto 0); -- read / write cmd ([read][write], xor = enable, and = inst_wr)
        addr : in std_ulogic_vector(REGDEPTH - 1 downto 0);

        dio : inout std_ulogic_vector(WORDWIDTH - 1 downto 0)
        
    );

end entity asic_harness;

architecture rtl of asic_harness is
    signal phase : std_ulogic; 
    signal intpl : std_ulogic_vector(WORDWIDTH-1 downto 0);
    signal instaddr : unsigned(INST_DEPTH-1 downto 0);
 
    --signal proc_en   : std_ulogic;
    signal inst_wr   : std_ulogic;
    signal inst_addr : unsigned(INST_DEPTH-1 downto 0);
    signal inst_i    : std_ulogic_vector(INST_WIDTH-1 downto 0);
    signal re_cmd    : std_ulogic_vector(1 downto 0);
    signal re_addr   : unsigned(REGDEPTH-1 downto 0);
    signal reg_addr   : unsigned(REGDEPTH-1 downto 0);
    signal re_regi   : std_ulogic_vector(REGWIDTH-1 downto 0);
    signal re_rego   : std_ulogic_vector(REGWIDTH-1 downto 0);

begin
    -- Modules
        i_toplevel : entity work.toplevel
            port map(
                clk       => clk,
                rst       => rst,
                en        => en,
                o         => o,
                inst_wr   => inst_wr,
                inst_addr => inst_addr,
                inst_i    => inst_i,
                re_cmd    => re_cmd,
                re_addr   => re_addr,
                re_regi   => re_regi,
                re_rego   => re_rego
        );

    -- Logic
        tickff : entity work.t_ff
            port map(
                clk => clk,
                i   => tick,
                o   => phase
        );

    dio <= re_rego(WORDWIDTH - 1 downto 0) when rw = "10" else (others => 'Z');

    re_addr <= unsigned(addr) when rw = "10" else reg_addr;

    seq : process (clk, rst)
    begin
        if rst = '1' then
            intpl <= (others => '0');
            
            re_cmd <= "00";
            reg_addr <= (others => '0');
            re_regi <= (others => '0');
            
            inst_wr <= '0';
            instaddr <= (others => '0');
            inst_addr <= (others => '0');
            inst_i <= (others => '0');
        elsif rising_edge(clk) then
            intpl <= (others => '0');
            
            re_cmd <= "00";
            reg_addr <= (others => '0');
            re_regi <= (others => '0');
            
            inst_wr <= '0';
            inst_addr <= (others => '0');
            inst_i <= (others => '0');

            case(rw) is
                when "01" =>
                    if tick = '1' then
                        intpl <= dio;
                    else 
                        intpl <= (others => '0');

                        re_cmd <= "10";
                        reg_addr <= unsigned(addr);
                        re_regi <= intpl(CFGWIDTH - 1 downto 0) & dio;
                    end if;
                when "11" =>
                    if tick = '1' then
                        intpl <= dio;
                    else 
                        intpl <= (others => '0');

                        inst_wr <= '1';
                        instaddr <= instaddr + 1;
                        inst_addr <= instaddr;
                        inst_i <= intpl & dio;
                    end if;
                when others =>
            end case;
        end if;
    end process seq;
end architecture rtl;
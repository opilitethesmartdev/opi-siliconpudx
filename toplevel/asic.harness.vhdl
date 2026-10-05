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

        -- Serial IO Interface
        --ti : in std_ulogic; -- transfer init
        rw : in std_ulogic_vector(1 downto 0); -- read / write cmd ([read][write], xor = enable, and = inst_wr)
        --addr : in std_ulogic_vector(REGDEPTH - 1 downto 0);
        mosi : in std_ulogic;
        miso : out std_ulogic

        --dio : inout std_ulogic_vector(WORDWIDTH - 1 downto 0)
        
    );

end entity asic_harness;

architecture rtl of asic_harness is
    signal rwop : std_ulogic; -- r/w operaion ongoing
    signal rwfn : std_ulogic; -- r/w operation finish
    signal rwei : std_ulogic; -- r/w edge detector in
    signal rwdel : std_ulogic_vector(1 downto 0); -- delayed rw signal

    signal dmiso : std_ulogic_vector(WORDWIDTH*2-1 downto 0);
    signal dmosi : std_ulogic_vector(WORDWIDTH*3-1 downto 0);
    signal spien : std_ulogic_vector(1 downto 0);
 
    signal proc_en   : std_ulogic;
    signal inst_wr   : std_ulogic;
    signal inst_addr : unsigned(INST_DEPTH-1 downto 0);
    signal inst_i    : std_ulogic_vector(INST_WIDTH-1 downto 0);
    signal re_cmd    : std_ulogic_vector(1 downto 0);
    signal re_addr   : unsigned(REGDEPTH-1 downto 0);
    signal re_regi   : std_ulogic_vector(REGWIDTH-1 downto 0);
    signal re_rego   : std_ulogic_vector(REGWIDTH-1 downto 0);

begin
    -- Modules
        i_toplevel : entity work.toplevel
            port map(
                clk       => clk,
                rst       => rst,
                en        => proc_en,
                o         => o,
                inst_wr   => inst_wr,
                inst_addr => inst_addr,
                inst_i    => inst_i,
                re_cmd    => re_cmd,
                re_addr   => re_addr,
                re_regi   => re_regi,
                re_rego   => re_rego
        );

        i_spislave : entity work.spislave
            port map(
                clk   => clk,
                rst   => rst,
                en    => spien,
                mosi  => mosi,
                miso  => miso,
                dmiso => dmiso,
                dmosi => dmosi
            );
        
    -- Logic
        spien <= rwop & '0';

        rwei <= or rw;

        rwedge : entity work.edgend
            generic map(
                polarity => "falling"
            )
            port map(
                clk => clk,
                i   => rwei,
                o   => rwfn
            );

        rwff : entity work.sr_ff
            port map(
                clk => clk,
                s   => mosi,
                r   => rwfn,
                o   => rwop
            );

        rwshift : entity work.n_shift
            generic map( WIDTH => 2, DELAY => 1 )
            port map(
                clk => clk,
                rst => rst,
                i   => rw,
                o   => rwdel
            );



end architecture rtl;
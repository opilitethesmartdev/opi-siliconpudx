----------------------------------------------------------------------------
-- Project		:	OPI-siliconPUdx
-- Authors		:	opilitethesmartdev
-- Description	:	Register bank
----------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.core_pkg.all;
use work.register_pkg.all;

entity RegisterBank is
    port (
        clk : in std_ulogic;
        err : out std_ulogic; -- high when mirror sram contents don't match (on reads)
        
        cmd  : in  std_ulogic_vector(1 downto 0); --[read][write]; xor = en
        
        -- Mirror mode
        addr : in  unsigned(REGD - 1 downto 0); 
        din  : in  std_ulogic_vector(WORDWIDTH - 1 downto 0);
        dout : out std_ulogic_vector(WORDWIDTH - 1 downto 0);
        
        -- Singular mode
        rd_a : in std_ulogic;
        rd_b : in std_ulogic;

        addr_a : in unsigned(REGD - 1 downto 0);
        addr_b : in unsigned(REGD - 1 downto 0);
        
        dout_a : out std_ulogic_vector(WORDWIDTH - 1 downto 0);
        dout_b : out std_ulogic_vector(WORDWIDTH - 1 downto 0)        
    );
end entity RegisterBank;

architecture rtl of RegisterBank is
    signal en, mode  : std_ulogic;
    signal errc : std_ulogic;

    signal a_en   :  std_ulogic;
    signal a_wren :  std_ulogic;
    signal a_addr :  unsigned(REGD - 1 downto 0);
    signal a_din  :  std_ulogic_vector(7 downto 0);
    signal a_dout :  std_ulogic_vector(7 downto 0);

    signal b_en   :  std_ulogic;
    signal b_wren :  std_ulogic;
    signal b_addr :  unsigned(REGD - 1 downto 0);
    signal b_din  :  std_ulogic_vector(7 downto 0);
    signal b_dout  :  std_ulogic_vector(7 downto 0);
    
    -- Debug statements (optimize away)
    signal debug_xor_dout :  std_ulogic_vector(7 downto 0);
    signal debug_diff_dout   :  std_ulogic;

begin   
    -- SRAM Entities
        sram_a : entity work.sram_macro
            generic map(
                CONFIG => "sram64x8m8wm1_3v3"
            )
            port map(
                clk  => clk,
                en   => a_en,
                wren => a_wren,
                mask => (others => a_en),
                addr => resize(a_addr, 8),
                din  => a_din,
                dout => a_dout
        );
        sram_b : entity work.sram_macro
            generic map(
                CONFIG => "sram64x8m8wm1_3v3"
            )
            port map(
                clk  => clk,
                en   => b_en,
                wren => b_wren,
                mask => (others => b_en),
                addr => resize(b_addr, 8),
                din  => b_din,
                dout => b_dout
        );
    
    -- FFs
        errenshift : entity work.n_shift1b
            generic map( DELAY => 1 )
            port map(
                clk => clk,
                rst => '0',
                i   => en,
                o   => errc
        );


        errdetff : process(clk)
        begin
            if rising_edge(clk) then
                debug_xor_dout <= a_dout xor b_dout;
                debug_diff_dout <= or (a_dout xor b_dout);

                err <= '1' when (or (a_dout xor b_dout)) = '1' and ((not mode) and errc) = '1' else '0';
            end if;
        end process errdetff;

    mode <= rd_a or rd_b;
    en <= (xor cmd);
    
    a_en <= rd_a when mode = '1' else en;
    b_en <= rd_b when mode = '1' else en;

    a_wren <= '0' when mode = '1' else cmd(0);
    b_wren <= '0' when mode = '1' else cmd(0);

    a_addr <= addr_a when mode = '1' else addr;
    b_addr <= addr_b when mode = '1' else addr;

    a_din <= (others => '0') when mode = '1' else din;
    b_din <= (others => '0') when mode = '1' else din;

    dout_a <= a_dout when mode = '1' else (others => '0');
    dout_b <= b_dout when mode = '1' else (others => '0');

    dout <= a_dout and b_dout when mode = '0' else (others => '0');
end architecture;
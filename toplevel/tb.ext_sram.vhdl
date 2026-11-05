----------------------------------------------------------------------------
-- Project		:	OPI-siliconPUdx
-- Authors		:	opilitethesmartdev
-- Description	:	Simple Testbench for external SRAM bank
----------------------------------------------------------------------------

-- vhdl_ls off
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use std.env.stop;
entity tb_ext_sram is
end tb_ext_sram ;

architecture sim of tb_ext_sram is
    constant WORDWIDTH : natural := 32;
    constant WORDDEPTH : natural := 10;

    signal clk  :  std_ulogic := '0';
    signal en   :  std_ulogic := '0';
    signal wren :  std_ulogic;
    signal mask :  std_ulogic_vector(WORDWIDTH-1 downto 0);
    signal addr :  unsigned(WORDDEPTH-1 downto 0);
    signal din  :  std_ulogic_vector(WORDWIDTH-1 downto 0);
    signal dout :  std_ulogic_vector(WORDWIDTH-1 downto 0);
begin

    clk <= (not clk) after 5 ns;

    i_ext_sram : entity work.ext_sram
        generic map(
            WORDWIDTH => WORDWIDTH,
            WORDDEPTH => WORDDEPTH
        )
        port map(
            clk  => clk,
            en   => en,
            wren => wren,
            mask => mask,
            addr => addr,
            din  => din,
            dout => dout
    );

    tb : process 
    begin
        wait for 15ns;
        en <= '1';
        wren <= '1';
        mask <= x"1111";

        addr <= to_unsigned(0, WORDDEPTH);
        din <= x"dead";
        
        wait for 10ns;
        addr <= to_unsigned(1, WORDDEPTH);
        din <= x"beef";
        
        wait for 10ns;
        addr <= to_unsigned(254, WORDDEPTH);
        din <= x"d3ad";
        
        wait for 10ns;
        addr <= to_unsigned(255, WORDDEPTH);
        din <= x"b3ef";
        
        wait for 10ns;
        addr <= to_unsigned(510, WORDDEPTH);
        din <= x"de4d";
        
        wait for 10ns;
        addr <= to_unsigned(511, WORDDEPTH);
        din <= x"be3f";
        
        wait for 10ns;
        addr <= to_unsigned(1022, WORDDEPTH);
        din <= x"d34d";
        
        wait for 10ns;
        addr <= to_unsigned(1023, WORDDEPTH);
        din <= x"b33f";
        
        wait for 10ns;
        en <= '0';
        wren <= '0';
        mask <= x"0000";
        din <= x"0000";

        wait for 20ns;
        en <= '1';
        wren <= '0';
        mask <= x"1111";

        addr <= to_unsigned(0, WORDDEPTH);
        wait for 10ns;
        assert dout = x"dead" report "Address 0 not dead but: " & to_hstring(to_signed(dout, WORDWIDTH)) severity error;
        wait for 10ns;

        addr <= to_unsigned(1, WORDDEPTH);
        wait for 10ns;
        assert dout = x"beef" report "Address 1 not beef but: " & to_hstring(to_signed(dout, WORDWIDTH)) severity error;
        wait for 10ns;

        addr <= to_unsigned(254, WORDDEPTH);
        wait for 10ns;
        assert dout = x"d3ad" report "Address 254 not d3ad but: " & to_hstring(to_signed(dout, WORDWIDTH)) severity error;
        wait for 10ns;

        addr <= to_unsigned(255, WORDDEPTH);
        wait for 10ns;
        assert dout = x"b3ef" report "Address 255 not b3ef but: " & to_hstring(to_signed(dout, WORDWIDTH)) severity error;
        wait for 10ns;

        addr <= to_unsigned(510, WORDDEPTH);
        wait for 10ns;
        assert dout = x"de4d" report "Address 510 not de4d but: " & to_hstring(to_signed(dout, WORDWIDTH)) severity error;
        wait for 10ns;

        addr <= to_unsigned(511, WORDDEPTH);
        wait for 10ns;
        assert dout = x"be3f" report "Address 511 not be3f but: " & to_hstring(to_signed(dout, WORDWIDTH)) severity error;
        wait for 10ns;

        addr <= to_unsigned(1022, WORDDEPTH);
        wait for 10ns;
        assert dout = x"d34d" report "Address 1022 not d34d but: " & to_hstring(to_signed(dout, WORDWIDTH)) severity error;
        wait for 10ns;

        addr <= to_unsigned(1023, WORDDEPTH);
        wait for 10ns;
        assert dout = x"b33f" report "Address 1023 not b33f but: " & to_hstring(to_signed(dout, WORDWIDTH)) severity error;
        wait for 10ns;

        report "External SRAM passes testbench !!" severity note;

        en <= '0';
        wren <= '0';
        mask <= x"0000";
        
        wait for 50ns;
        stop;
    end process tb;
end architecture ; -- sim
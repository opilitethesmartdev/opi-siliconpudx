----------------------------------------------------------------------------
-- Project		:	OPI-siliconPUdx
-- Authors		:	opilitethesmartdev
-- Description	:	Gate level testbench driver
----------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.stop;

use work.hsc_pkg.all;
use work.core_pkg.all;
use work.register_pkg.all;
use work.instruction_pkg.all;

entity tb_driver is
    port(
        clk : in std_ulogic;
        rst : in std_ulogic;
        ena : in std_ulogic;
        
        start : in std_ulogic;

        mosi : out std_ulogic;
        t_si : out std_ulogic
    );
end entity tb_driver;

architecture sim of tb_driver is
    signal en  :  std_ulogic_vector(1 downto 0) := "00";
    signal o   :  std_ulogic_vector(1 downto 0) := "00";

    signal instruction :  std_ulogic;
    
    signal ram_en      :  std_ulogic;
    signal ram_wren    :  std_ulogic;
    signal ram_mask    :  std_ulogic_vector(IBWIDTH-1 downto 0);
    signal ram_addr    :  unsigned(INSTD-1 downto 0);
    signal ram_dout    :  std_ulogic_vector(IBWIDTH-1 downto 0);
    signal ram_din     :  std_ulogic_vector(IBWIDTH-1 downto 0);

    signal miso        :  std_ulogic;
    signal t_so        :  std_ulogic;

    signal raw_lv : std_ulogic_vector(HSCW - 1 downto 0);

    constant program : program_arr_t(0 to 16) := (
            x"01" & newinst(0, 0, lda, x"0000"),-- 0  | lda  0x0
            x"02" & newinst(0, 0, atr, 0, 0),   -- 1  | atr  0
            x"08" & newinst(0, 0, lda, x"0001"),-- 2  | lda  0x1
            x"06" & newinst(0, 0, atr, 1, 0),   -- 3  | atr  1
            x"05" & newinst(0, 0, lda, x"0002"),-- 4  | lda  0x2
            x"00" & newinst(0, 0, atr, 2, 0),   -- 5  | atr  2
            x"00" & newinst(0, 0, lda, x"0003"),-- 6  | lda  0x3
            x"00" & newinst(0, 0, atr, 4, 0),   -- 7  | atr  4
            x"00" & newinst(0, 0, lda, x"0004"),-- 8  | lda  0x4
            x"00" & newinst(0, 0, atr, 6, 0),   -- 9  | atr  6
            x"00" & inst2v(INSTNULL(idl)),      -- 10 | idl
            x"00" & newinst(1, 0, isz, 0, 0),   -- 11 | isz >0  0
            x"00" & newinst(0, 0, jmp, x"000E"),-- 12 | jmp  0xE
            x"00" & newinst(0, 0, stp, 0, 0),   -- 13 | stp
            x"00" & newinst(1, 0, dec, 0, 1),   -- 14 | dec >0  1
            x"00" & newinst(1, 0, inc, 4, 1),   -- 15 | inc >4  1
            x"00" & newinst(0, 0, jmp, x"000B") -- 16 | jmp  0xB
        );


begin
    en <= '0' & ena;

    i_asic_harness : entity work.asic_harness
        port map(
            clk         => clk,
            rst         => rst,
            en          => en,
            o           => o,
            mosi        => mosi,
            t_si        => t_si,
            miso        => miso,
            t_so        => t_so,
            ram_en      => ram_en,
            ram_wren    => ram_wren,
            ram_mask    => ram_mask,
            ram_addr    => ram_addr,
            ram_din     => ram_din,
            ram_dout    => ram_dout,
            instruction => instruction
    );


    
    i_ext_sram : entity work.ext_sram
        generic map(
            WORDWIDTH => IBWIDTH,
            WORDDEPTH => INSTD
        )
        port map(
            clk  => clk,
            en   => ram_en,
            wren => ram_wren,
            mask => ram_mask,
            addr => ram_addr,
            din  => ram_din,
            dout => ram_dout
    );
    

    testbench : process
    begin
        wait until start = '1';

        for line in 0 to program'length-1 loop
            raw_lv <= "11" 
                      & std_ulogic_vector(to_unsigned(line, INSTD))
                      & program(line);
            
            t_so <= '1';

            for bit in 0 to raw_lv'length-1 loop
                wait for 10 ns;
                miso <= raw_lv(bit);
            end loop;

            wait for 10 ns;
            miso <= '0';
            t_so <= '0';

            wait until t_si = '1';
            wait until t_si = '0';
        end loop;


        -- Execute
        wait for 10 ns;
        en(0) <= '1';
        wait on o;
        wait for 10 ns;
        en(0) <= '0';
        report "Finish";
        wait for 40 ns;
        stop;
    end process testbench;
    
end architecture sim;
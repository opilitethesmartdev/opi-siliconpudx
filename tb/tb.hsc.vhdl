----------------------------------------------------------------------------
-- Project		:	OPI-siliconPUdx
-- Authors		:	opilitethesmartdev
-- Description	:	ASIC testbench
----------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.stop;

use work.core_pkg.all;
use work.hsc_pkg.all;
use work.register_pkg.all;
use work.instruction_pkg.all;

entity tb_hsc is
end entity tb_hsc;

architecture sim of tb_hsc is
    signal clk      :  std_ulogic := '0';
    signal rst      :  std_ulogic;
    signal mosi     :  std_ulogic;
    signal t_si     :  std_ulogic;
    signal miso     :  std_ulogic;
    signal t_so     :  std_ulogic;
    signal ram_en   :  std_ulogic;
    signal ram_wren :  std_ulogic;
    signal ram_mask :  std_ulogic_vector(IBWIDTH-1 downto 0);
    signal ram_addr :  unsigned(INSTD-1 downto 0);
    signal ram_din  :  std_ulogic_vector(IBWIDTH-1 downto 0);
    signal ram_dout :  std_ulogic_vector(IBWIDTH-1 downto 0);
    signal re_cmd   :  std_ulogic_vector(1 downto 0);
    signal re_addr  :  unsigned(REGD-1 downto 0);
    signal re_i     :  std_ulogic_vector(WORDWIDTH-1 downto 0);
    signal re_o     :  std_ulogic_vector(WORDWIDTH-1 downto 0);

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
    clk <= (not clk) after 5 ns;
    rst <= '1', '0' after 10 ns;

    i_HostSerialIf : entity work.HostSerialIf
        port map(
            clk      => clk,
            rst      => rst,
            mosi     => mosi,
            t_si     => t_si,
            miso     => miso,
            t_so     => t_so,
            ram_en   => ram_en,
            ram_wren => ram_wren,
            ram_mask => ram_mask,
            ram_addr => ram_addr,
            ram_din  => ram_din,
            ram_dout => ram_dout,
            re_cmd   => re_cmd,
            re_addr  => re_addr,
            re_i     => re_i,
            re_o     => re_o
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
    i_RegisterBank : entity work.RegisterBank
        port map(
            clk    => clk,
            err    => open,
            cmd    => re_cmd,
            addr   => re_addr,
            din    => re_i,
            dout   => re_o,
            rd_a   => '0',
            rd_b   => '0',
            addr_a => (others => '0'),
            addr_b => (others => '0'),
            dout_a => open,
            dout_b => open
        );
    

    testbench : process
    begin
        wait for 10 ns;

        -- Write program to instruction sram
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

        -- Read from instruction sram
        wait for 40 ns;
        raw_lv <= "01" 
                & std_ulogic_vector(to_unsigned(0, INSTD))
                & x"00"
                & inst2v(INSTNULL);
        
        t_so <= '1';

        for bit in 0 to raw_lv'length-1 loop
            wait for 10 ns;
            miso <= raw_lv(bit);
        end loop;

        wait for 10 ns;
        miso <= '0';
        t_so <= '0';

        wait on t_si;
        wait for 5 ns;
        for i in 0 to HSCW-1 loop
            raw_lv(HSCW - 1 - i) <= mosi;
            wait for 10 ns;
        end loop;
        report "Read SRAM from address 0: 0x" & to_hex_string(raw_lv(HDATAW - INSTD - 1 downto 0));
        wait for 10 ns;
        

        -- Write to register sram
        wait for 40 ns;
        raw_lv <= "10" 
                & '0' & x"01"
                & x"67"
                & padding(INSTW - 1 downto 0);
        
        t_so <= '1';

        for bit in 0 to raw_lv'length-1 loop
            wait for 10 ns;
            miso <= raw_lv(bit);
        end loop;

        wait for 10 ns;
        miso <= '0';
        t_so <= '0';
        wait on t_si;

        -- Read from register sram
        wait for 40 ns;
        raw_lv <= "00" 
                & '0' & x"01"
                & padding(INSTW + HWW - 1 downto 0);
        
        t_so <= '1';

        for bit in 0 to raw_lv'length-1 loop
            wait for 10 ns;
            miso <= raw_lv(bit);
        end loop;

        wait for 10 ns;
        miso <= '0';
        t_so <= '0';

        wait on t_si;
        wait for 5 ns;
        for i in 0 to HSCW-1 loop
            raw_lv(HSCW - 1 - i) <= mosi;
            wait for 10 ns;
        end loop;
        report "Read Register from address 1: 0x" & to_hex_string(raw_lv(HDATAW - INSTD - 1 downto HDATAW - INSTD - HWW));
        wait for 10 ns;

        report "Finish";
        wait for 400 ns;
        stop;
    end process testbench;
    
end architecture sim;
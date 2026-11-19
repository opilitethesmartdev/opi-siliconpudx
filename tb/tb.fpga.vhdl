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
use work.register_pkg.all;
use work.instruction_pkg.all;

entity tb_fpga is
end entity tb_fpga;

architecture sim of tb_fpga is
    signal clk  :  std_ulogic := '0';
    signal en   :  std_ulogic;
    signal rst  :  std_ulogic;
    signal rst_n  :  std_ulogic;

    signal rx_av  :  std_ulogic;
    signal rx_o   :  std_ulogic_vector(7 downto 0);
    signal rx_ack :  std_ulogic;
    signal tx_en  :  std_ulogic;
    signal tx_i   :  std_ulogic_vector(7 downto 0);
    signal tx_fin :  std_ulogic;
    signal tx_ack :  std_ulogic;
    signal tx     :  std_ulogic;
    signal rx     :  std_ulogic;

    signal led   :  std_ulogic_vector(5 downto 0);

    signal pln : std_ulogic_vector(IBWIDTH - 1 downto 0) := (others => '0');
    signal db_pass : integer := 0;
    signal ab_pass : integer := 0;

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
    clk <= (not clk) after 20 ns;
    rst <= '1', '0' after 80 ns; 
    rst_n <= not rst; -- active low

    slave : entity work.UARTIf
        generic map(
            W      => 8,
            CLK_HZ => 25_000_000,
            BAUD   => 115200
        )
        port map(
            clk    => clk,
            rst    => rst,
            rx_av  => rx_av,
            rx_o   => rx_o,
            rx_ack => rx_ack,
            tx_en  => tx_en,
            tx_i   => tx_i,
            tx_fin => tx_fin,
            tx_ack => tx_ack,
            tx     => tx,
            rx     => rx
    );

    i_fpga_harness : entity work.fpga_harness
        generic map(
            CLK_HZ => 25_000_000
        )
        port map(
            clk => clk,
            rst => rst_n,
            en  => en,
            rx  => tx,
            tx  => rx,
            led => led
    );



    testbench : process
    begin
        -- Defaults
        en <= '0';

        tx_ack <= '0';
        rx_ack <= '0';

        tx_en <= '0';
        tx_i <= x"00";

        wait for 160 ns;
        for i in 0 to program'length-1 loop
            --pln <= program(i);

            -- Command byte
            db_pass <= 1;
            tx_en <= '1';
            tx_i <= x"FD";
            wait for 40 ns;
            tx_en <= '0';
            tx_i <= x"00";
            wait on tx_fin;
            wait for 20 ns;
            tx_ack <= '1';
            wait for 40 ns;
            tx_ack <= '0';
            wait for 40 ns;
        
            -- Address bytes
            for j in 0 to 1 loop
                db_pass <= j+2;
                tx_en <= '1';
                tx_i <= x"00";
                wait for 40 ns;
                tx_en <= '0';
                tx_i <= x"00";
                wait on tx_fin;
                wait for 20 ns;
                tx_ack <= '1';
                wait for 40 ns;
                tx_ack <= '0';
                wait for 40 ns;
            end loop;

            -- Data bytes
            for j in 0 to 3 loop
                db_pass <= j+3;
                tx_en <= '1';
                --tx_i <= program(i)(IBWIDTH-8*j-1 downto IBWIDTH-8*(j+1));
                tx_i <= program(0)(IBWIDTH-8*j-1 downto IBWIDTH-8*(j+1));
                wait for 40 ns;
                tx_en <= '0';
                tx_i <= x"00";
                wait on tx_fin;
                wait for 20 ns;
                tx_ack <= '1';
                wait for 40 ns;
                tx_ack <= '0';
                wait for 40 ns;
            end loop;

            for j in 0 to 3 loop
                ab_pass <= j;
                wait on rx_av;
                wait for 40 ns;
                rx_ack <= '1';
                wait for 40 ns;
                rx_ack <= '0';
                wait for 40 ns;
            end loop;
        end loop;

        -- Read instruction
            db_pass <= 0;
            ab_pass <= 0;
            -- Command byte
            db_pass <= 1;
            tx_en <= '1';
            tx_i <= x"FB";
            wait for 40 ns;
            tx_en <= '0';
            tx_i <= x"00";
            wait on tx_fin;
            wait for 20 ns;
            tx_ack <= '1';
            wait for 40 ns;
            tx_ack <= '0';
            wait for 40 ns;
        
            -- Address bytes
            for j in 0 to 1 loop
                db_pass <= j+2;
                tx_en <= '1';
                tx_i <= x"00";
                wait for 40 ns;
                tx_en <= '0';
                tx_i <= x"00";
                wait on tx_fin;
                wait for 20 ns;
                tx_ack <= '1';
                wait for 40 ns;
                tx_ack <= '0';
                wait for 40 ns;
            end loop;

            -- Data bytes
            for j in 0 to 3 loop
                db_pass <= j+4;
                tx_en <= '1';
                tx_i <= x"00";
                --tx_i <= program(0)(IBWIDTH-8*j-1 downto IBWIDTH-8*(j+1));
                wait for 40 ns;
                tx_en <= '0';
                tx_i <= x"00";
                wait on tx_fin;
                wait for 20 ns;
                tx_ack <= '1';
                wait for 40 ns;
                tx_ack <= '0';
                wait for 40 ns;
            end loop;

            for j in 0 to 3 loop
                ab_pass <= j;
                wait on rx_av;
                wait for 40 ns;
                rx_ack <= '1';
                wait for 40 ns;
                rx_ack <= '0';
                wait for 40 ns;
            end loop;
        

        -- Write register
            db_pass <= 0;
            ab_pass <= 0;
            -- Command byte
            db_pass <= 1;
            tx_en <= '1';
            tx_i <= x"FC";
            wait for 40 ns;
            tx_en <= '0';
            tx_i <= x"00";
            wait on tx_fin;
            wait for 20 ns;
            tx_ack <= '1';
            wait for 40 ns;
            tx_ack <= '0';
            wait for 40 ns;
        
            -- Address bytes
            for j in 0 to 1 loop
                db_pass <= j+2;
                tx_en <= '1';
                tx_i <= x"0A";
                wait for 40 ns;
                tx_en <= '0';
                tx_i <= x"00";
                wait on tx_fin;
                wait for 20 ns;
                tx_ack <= '1';
                wait for 40 ns;
                tx_ack <= '0';
                wait for 40 ns;
            end loop;

            -- Data bytes
            for j in 0 to 3 loop
                db_pass <= j+4;
                tx_en <= '1';
                tx_i <= x"67";
                --tx_i <= program(0)(IBWIDTH-8*j-1 downto IBWIDTH-8*(j+1));
                wait for 40 ns;
                tx_en <= '0';
                tx_i <= x"00";
                wait on tx_fin;
                wait for 20 ns;
                tx_ack <= '1';
                wait for 40 ns;
                tx_ack <= '0';
                wait for 40 ns;
            end loop;

            for j in 0 to 3 loop
                ab_pass <= j;
                wait on rx_av;
                wait for 40 ns;
                rx_ack <= '1';
                wait for 40 ns;
                rx_ack <= '0';
                wait for 40 ns;
            end loop;
        

        -- Read register
            db_pass <= 0;
            ab_pass <= 0;
            -- Command byte
            db_pass <= 1;
            tx_en <= '1';
            tx_i <= x"FA";
            wait for 40 ns;
            tx_en <= '0';
            tx_i <= x"00";
            wait on tx_fin;
            wait for 20 ns;
            tx_ack <= '1';
            wait for 40 ns;
            tx_ack <= '0';
            wait for 40 ns;
        
            -- Address bytes
            for j in 0 to 1 loop
                db_pass <= j+2;
                tx_en <= '1';
                tx_i <= x"0A";
                wait for 40 ns;
                tx_en <= '0';
                tx_i <= x"00";
                wait on tx_fin;
                wait for 20 ns;
                tx_ack <= '1';
                wait for 40 ns;
                tx_ack <= '0';
                wait for 40 ns;
            end loop;

            -- Data bytes
            for j in 0 to 3 loop
                db_pass <= j+4;
                tx_en <= '1';
                tx_i <= x"00";
                --tx_i <= program(0)(IBWIDTH-8*j-1 downto IBWIDTH-8*(j+1));
                wait for 40 ns;
                tx_en <= '0';
                tx_i <= x"00";
                wait on tx_fin;
                wait for 20 ns;
                tx_ack <= '1';
                wait for 40 ns;
                tx_ack <= '0';
                wait for 40 ns;
            end loop;

            for j in 0 to 3 loop
                ab_pass <= j;
                wait on rx_av;
                wait for 40 ns;
                rx_ack <= '1';
                wait for 40 ns;
                rx_ack <= '0';
                wait for 40 ns;
            end loop;

        report "Finish";
        wait for 400 ns;
        stop;
    end process testbench;
    
end architecture sim;
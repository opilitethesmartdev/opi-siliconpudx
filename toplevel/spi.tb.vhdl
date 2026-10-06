library ieee;
use ieee.std_logic_1164.all;

use work.core_pkg.all;
use work.register_pkg.all;
use work.instruction_pkg.all;

entity spislave_tb is
end entity spislave_tb;

architecture tb of spislave_tb is

    signal clk : std_ulogic := '0';
    signal rst : std_ulogic := '1';

    signal en : std_ulogic_vector(1 downto 0) := "00";

    signal mosi : std_ulogic := '0';
    signal miso : std_ulogic;

    signal dmiso : std_ulogic_vector(WORDWIDTH*2 - 1 downto 0)
        := (others => '0');

    signal dmosi : std_ulogic_vector(WORDWIDTH*3 - 1 downto 0);

begin

    clk <= not clk after 5 ns;

    dut : entity work.spconverter
        port map(
            clk   => clk,
            rst   => rst,
            en    => en,
            mosi  => mosi,
            miso  => miso,
            dmiso => dmiso,
            dmosi => dmosi
        );

    stim : process
    begin

        ----------------------------------------------------------------
        -- Reset
        ----------------------------------------------------------------

        rst <= '1';
        wait for 20 ns;

        rst <= '0';
        wait until rising_edge(clk);

        assert miso = '0'
            report "MISO not zero after reset"
            severity error;

        ----------------------------------------------------------------
        -- INPUT TEST
        --
        -- Send 16 bits:
        --
        --   10110010 01101101
        --
        -- MSB first.
        ----------------------------------------------------------------

        en(0) <= '1';

        for i in 15 downto 0 loop
            if (i mod 2) = 0 then
                mosi <= '0';
            else
                mosi <= '1';
            end if;

            wait until rising_edge(clk);
        end loop;

        wait for 10 ns;

        en(0) <= '0';

        wait until rising_edge(clk);

        assert dmosi(15 downto 0) = "1010101010101010"
            report "Input shift register produced unexpected data"
            severity error;

        ----------------------------------------------------------------
        -- OUTPUT TEST
        --
        -- Load:
        --
        --   11001100 10101010
        --
        -- into the output shift register.
        ----------------------------------------------------------------

        dmiso <= "1100110010101010";

        en(1) <= '1';

        -- Rising edge of en(1) causes the load.
        wait until rising_edge(clk);

        -- Keep en asserted for shifting.
        wait until rising_edge(clk);

        assert miso = '1'
            report "First output bit incorrect"
            severity error;

        wait until rising_edge(clk);
        assert miso = '1'
            report "Second output bit incorrect"
            severity error;

        wait until rising_edge(clk);
        assert miso = '0'
            report "Third output bit incorrect"
            severity error;

        wait until rising_edge(clk);
        assert miso = '0'
            report "Fourth output bit incorrect"
            severity error;

        wait until rising_edge(clk);
        assert miso = '1'
            report "Fifth output bit incorrect"
            severity error;

        wait until rising_edge(clk);
        assert miso = '0'
            report "Sixth output bit incorrect"
            severity error;

        wait until rising_edge(clk);
        assert miso = '1'
            report "Seventh output bit incorrect"
            severity error;

        wait until rising_edge(clk);
        assert miso = '0'
            report "Eighth output bit incorrect"
            severity error;

        en(1) <= '0';

        ----------------------------------------------------------------
        -- Done
        ----------------------------------------------------------------

        report "spislave testbench completed successfully"
            severity note;

        wait;

    end process stim;

end architecture tb;
-----------------------------------------------------------------
-- Project		: Generic
-- Module		: Collection of Flip Flops and other logical devices
-- Author		: opilitethesmartdev
-----------------------------------------------------------------
-- T-FlipFlop

    library ieee;
    use ieee.std_logic_1164.all;
    entity t_ff is
        port (
            clk : in std_ulogic;

            i : in std_ulogic;
            o : out std_ulogic
        );
    end entity t_ff;

    architecture rtl of t_ff is
        signal p : std_ulogic := '0'; --previous state
    begin
        seq : process(clk)
        begin
            if rising_edge(clk) then
                if i = '1' then p <= not p;
                end if;
            end if;
        end process seq;
        o <= p; 
    end architecture rtl;

-- S-R FlipFlop
    library ieee;
    use ieee.std_logic_1164.all;

    entity sr_ff is
        generic(
            PRIORITY : string := "reset"
        );
        port(
            clk : in std_ulogic;

            s : in  std_ulogic;
            r : in  std_ulogic;

            o : out std_ulogic := '0'
        );
    end entity sr_ff;

    architecture rtl of sr_ff is
    begin
        seq_rst : if PRIORITY = "reset" generate
        process(clk)
            begin
                if rising_edge(clk) then
                    if r = '1' then
                        o <= '0';
                    elsif s = '1' then
                        o <= '1';
                    end if;
                end if;
            end process;
        end generate;

        seq_set : if PRIORITY = "set" generate
        process(clk)
            begin
                if rising_edge(clk) then
                    if s = '1' then
                        o <= '1';
                    elsif r = '1' then
                        o <= '0';
                    end if;
                end if;
            end process;
        end generate;
    end architecture rtl;

-- Edge detector
    library ieee;
    use IEEE.STD_LOGIC_1164.all;

    entity edge is
        generic (
            polarity : string := "dual"
        );
        port (
            clk : in  std_ulogic;
            
            i : in  std_ulogic;
            o : out std_ulogic := '0'
        );
    end entity edge;

    architecture Behavioral of edge is
        signal prev : std_ulogic := '0';
    begin
        seq_dual : if polarity = "dual" generate
            process (clk)
            begin
                if rising_edge(clk) then
                    prev <= i;
                    o <= i xor prev;
                end if;
            end process;
        end generate;

        seq_rising : if polarity = "rising" generate
            process (clk)
            begin
                if rising_edge(clk) then
                    prev <= i;
                    o <= i and (not prev);
                end if;
            end process;
        end generate;

        seq_falling : if polarity = "falling" generate
            process (clk)
            begin
                if rising_edge(clk) then
                    prev <= i;
                    o <= (not i) and prev;
                end if;
            end process;
        end generate;
    end architecture Behavioral;

-- Edge detector delay-less
    library ieee;
    use IEEE.STD_LOGIC_1164.all;

    entity edgend is
        generic (
            polarity : string := "dual"
        );
        port (
            clk : in  std_ulogic;
            
            i : in  std_ulogic;
            o : out std_ulogic := '0'
        );
    end entity edgend;

    architecture Behavioral of edgend is
        signal prev : std_ulogic := '0';
    begin
        -- Dual edge
            seq_dual : if polarity = "dual" generate
                process (clk) begin
                    if rising_edge(clk) then
                        prev <= i;
                    end if;
                end process;
            end generate;

            o_dual : if polarity = "dual" generate
                process (i, prev) begin
                    o <= i xor prev;
                end process;
            end generate;

        -- Rising edge
            seq_rising : if polarity = "rising" generate
                process (clk) begin
                    if rising_edge(clk) then
                        prev <= i;
                    end if;
                end process;
            end generate;

            o_rising : if polarity = "rising" generate
                process (i, prev) begin
                    o <= i and (not prev);
                end process;
            end generate;

        -- Falling edge
            seq_falling : if polarity = "falling" generate
                process (clk) begin
                    if rising_edge(clk) then
                        prev <= i;
                    end if;
                end process;
            end generate;

            o_falling : if polarity = "falling" generate
                process (i, prev) begin
                    o <= (not i) and prev;
                end process;
            end generate;

    end architecture Behavioral;

-- Shift n-cycle signal delayer
    library ieee;
    use ieee.std_logic_1164.all;

    entity n_shift is
        generic(
            DELAY : positive := 2;
            WIDTH : positive := 8
        );
        port(
            clk : in std_ulogic;
            rst : in std_ulogic;
            
            i : in  std_ulogic_vector(WIDTH - 1 downto 0);
            o : out std_ulogic_vector(WIDTH - 1 downto 0)
        );
    end entity n_shift;

    architecture bhv of n_shift is
        type arr is array (0 to DELAY) of std_ulogic_vector(WIDTH - 1 downto 0);
        signal shift : arr := (others => (others => '0'));
    begin
        seq : process (clk, rst)
        begin
            if rst = '1' then
                shift <= (others => (others => '0'));
            elsif rising_edge(clk) then
                shift(0) <= i;
                if DELAY > 1 then
                    shift(1 to DELAY-1) <= shift(0 to DELAY-2);
                elsif DELAY = 1 then
                    shift(1) <= shift(0);
                end if;
            end if;
        end process seq;

        o <= shift(DELAY);
    end architecture bhv;

-- Shift n-cycle 1-bit signal delayer
    library ieee;
    use ieee.std_logic_1164.all;

    entity n_shift1b is
        generic(
            DELAY : positive := 2
        );
        port(
            clk : in std_ulogic;
            rst : in std_ulogic;
            
            i : in  std_ulogic;
            o : out std_ulogic
        );
    end entity n_shift1b;

    architecture bhv of n_shift1b is
        type arr is array (0 to DELAY) of std_ulogic;
        signal shift : arr := (others => '0');
    begin
        seq : process (clk, rst)
        begin
            if rst = '1' then
                shift <= (others => '0');
            elsif rising_edge(clk) then
                shift(0) <= i;
                if DELAY > 1 then
                    shift(1 to DELAY-1) <= shift(0 to DELAY-2);
                elsif DELAY = 1 then
                    shift(1) <= i;
                end if;
            end if;
        end process seq;

        o <= shift(DELAY);
    end architecture bhv;
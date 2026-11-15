----------------------------------------------------------------------------
-- Project		:	Generic
-- Authors		:	opilitethesmartdev
-- Description	:	Data serial / parallel converter
----------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity spconverter is
    generic(
        DW : natural := 43
    );
    port(
        clk : in std_ulogic;
        rst : in std_ulogic;
        
        mosi : out std_ulogic;
        t_si : out std_ulogic;
        miso : in std_ulogic;
        t_so : in std_ulogic;

        mo_en : in  std_ulogic;
        d_mo  : in  std_ulogic_vector(DW - 1 downto 0);
        mo_fn : out std_ulogic;

        mi_av  : out std_ulogic;
        d_mi   : out  std_ulogic_vector(DW - 1 downto 0)
    );
end entity spconverter;

architecture rtl of spconverter is
    signal mitend, miten : std_ulogic;
    signal motend, moph0 : std_ulogic;
    signal tsi_int, tsi_en : std_ulogic;

    signal sishift : std_ulogic_vector(DW - 1 downto 0);
    signal soshift : std_ulogic_vector(DW - 1 downto 0);
    signal socount : unsigned(7 downto 0);
begin
    --mi transfer enable edge
        miten_edge : entity work.edge 
            generic map(
                polarity => "falling"
            )
            port map(
                clk => clk,
                i   => t_so,
                o   => mitend
        );

    seq_mi : process(rst, clk)
    begin
        if rst = '1' then
            mi_av <= '0';
            sishift <= (others => '0');
            d_mi <= (others => '0');
        elsif rising_edge(clk) then
            if t_so = '1' then
                mi_av <= '0';
                sishift <= sishift(DW - 2 downto 0) & miso;
            elsif mitend = '1' then
                mi_av <= '1';
                d_mi <= sishift;
            end if;
        end if;
    end process seq_mi;

    -- mo enable ff
        moen_ff : entity work.sr_ff
            port map(
                clk => clk,
                s   => mo_en,
                r   => motend,
                o   => tsi_en
        ); 
    -- mo transfer end edge
        motend_edge : entity work.edge 
            generic map(
                polarity => "falling"
            )
            port map(
                clk => clk,
                i   => tsi_int,
                o   => motend
        ); t_si <= tsi_int;



    seq_mo : process(rst, clk)
    begin
        if rst = '1' then
            soshift <= (others => '0');
            socount <= (others => '0');
            moph0 <= '0';
            
            tsi_int <= '0';
            mosi <= '0';
            mo_fn <= '0';
        elsif rising_edge(clk) then
            if tsi_en = '1' then
                if socount = DW then
                    tsi_int <= '0';
                    mo_fn <= '1';

                    soshift <= (others => '0');
                    socount <= (others => '0');
                    moph0 <= '0';
                else
                    if moph0 <= '0' then
                        soshift <= d_mo;

                        moph0 <= '1';
                    else
                        socount <= socount + 1;
                        mosi <= soshift(DW - 1);
                        soshift <= soshift(DW - 2 downto 0) & '0';
                        
                        tsi_int <= '1';
                    end if;
                end if;
            end if;
        end if;
    end process seq_mo;
end architecture rtl;
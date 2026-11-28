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
        d_mi   : out  std_ulogic_vector(DW - 1 downto 0);

        ack : in std_ulogic
    );
end entity spconverter;

architecture rtl of spconverter is
    type mis_t is (reset, idle, feed,         done);
    type mos_t is (reset, idle, load, stream, done);
    signal mis, misn : mis_t;
    signal mos, mosn : mos_t;

    signal miso_dl : std_ulogic;

    signal ishift, ishift_ff : std_ulogic_vector(DW - 1 downto 0);
    signal oshift, oshift_ff : std_ulogic_vector(DW - 1 downto 0);
    signal ocount, ocount_ff : unsigned(7 downto 0);
begin
    ff : process(rst, clk)
    begin
        if rst = '1' then
            mis <= reset;
            mos <= reset;

            ishift_ff <= (others => '0');
            oshift_ff <= (others => '0');
            ocount_ff <= (others => '0');
        elsif rising_edge(clk) then
            mis <= misn;
            mos <= mosn;

            ishift_ff <= ishift;
            oshift_ff <= oshift;
            ocount_ff <= ocount;
        end if;
    end process ff;

    -- Master In
        miso_shift : entity work.n_shift1b
            generic map( DELAY => 1 )
            port map(
                clk => clk,
                rst => rst,
                i   => miso,
                o   => miso_dl
            );

        fsmi : process(all)
        begin
            case mis is
                when reset => misn <= idle;
                when idle =>  misn <= feed  when t_so = '1' else idle;
                when feed =>  misn <= done  when t_so = '0' else feed;
                when done =>  misn <= reset when ack  = '1' else done;
            end case;
        end process fsmi;
        
        maini : process(all)
        begin
            ishift <= ishift_ff;
            mi_av <= '0';
            d_mi <= (others => '0');

            case mis is
                when reset => 
                    ishift <= (others => '0');
                when idle => 
                when feed => 
                    ishift <= miso_dl & ishift_ff(DW - 1 downto 1);
                when done => 
                    mi_av <= '1';
                    d_mi <= ishift_ff;
            end case;
        end process maini;

    -- Master Out
        fsmo : process(all)
        begin
            case mos is
                when reset =>  mosn <= idle;
                when idle =>   mosn <= load when mo_en = '1' else idle;
                when load =>   mosn <= stream;
                when stream => mosn <= done when ocount_ff = DW else stream;
                when done =>   mosn <= reset when ack = '1' else done;
            end case;
        end process fsmo;

        maino : process(all)
        begin
            ocount <= ocount_ff;
            oshift <= oshift_ff;
            t_si  <= '0';
            mosi  <= '0';
            mo_fn <= '0';

            case mos is
                when reset => 
                    oshift <= (others => '0');
                    ocount <= (others => '0');
                when idle =>
                when load =>
                    oshift <= d_mo;
                when stream =>
                    t_si <= '1';
                    mosi <= oshift_ff(DW - 1);
                    oshift <= oshift_ff(DW - 2 downto 0) & '0';
                    ocount <= ocount_ff + 1;
                when done =>
                    mo_fn <= '1';
            end case;
        end process maino;

end architecture rtl;
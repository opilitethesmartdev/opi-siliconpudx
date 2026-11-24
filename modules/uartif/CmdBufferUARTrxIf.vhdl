----------------------------------------------------------------------------
-- Project		:	OPI-siliconPUdx
-- Authors		:	opilitethesmartdev
-- Description	:	Multi-byte UART Receiver Interface
----------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.uart_pkg.all;
use work.core_pkg.all;
use work.register_pkg.all;
use work.instruction_pkg.all;

entity CmdBufferUARTrxIf is
    generic(
        BUFD : natural := 16;
        CW   : natural := 5
    );
    port (
        clk : in std_ulogic;
        rst : in std_ulogic;

        -- UART RX Application Interface
        rx_av  : in  std_ulogic;
        rx_o   : in  std_ulogic_vector(UWW - 1 downto 0);
        rx_ack : out std_ulogic;

        -- Output
        msg_av  : out std_ulogic;
        msg_len : out unsigned(CW-1 downto 0);
        msg_ack : in std_ulogic;
        msg     : out uart_t(0 to BUFD-1)      
    );
end entity CmdBufferUARTrxIf;

architecture rtl of CmdBufferUARTrxIf is
    -- Constants
        constant STATES : natural := 2;

    -- Array
        signal buf : uart_t(0 to BUFD-1);
        signal bufn : uart_t(0 to BUFD-1);

    -- FSM Signals
        type s_t is (reset, rsync, idle, eva, ret, fin);
        signal s,sn : s_t;

    -- Transient state interface
        signal ss  :  std_ulogic_vector(STATES-1 downto 0);
        signal sr  :  std_ulogic_vector(STATES-1 downto 0);
        signal so  :  std_ulogic_vector(STATES-1 downto 0);

    -- Transient state mappings
        constant rec : integer := 0;
        constant esc : integer := 1;
    
    -- Internal signals
        signal c, cff : unsigned(CW-1 downto 0);
        signal rxn, rxff : std_ulogic_vector(UWW - 1 downto 0);

        signal rs, rss : std_ulogic;
begin
    -- Signal Primitives
        rs_shift : entity work.n_shift1b
            generic map(
                DELAY => 1
            )
            port map(
                clk => clk,
                rst => rst,
                i   => rs,
                o   => rss
        );

    -- Transient State Interface
        tsif : entity work.TransientStateIf
            generic map(
                STATES => STATES
            )
            port map(
                clk => clk,
                rst => rst,
                ss  => ss,
                sr  => sr,
                so  => so
        );

    -- FSM Processes
        ff: process(rst, clk)
        begin
            if rst = '1' then
                s <= reset;

                cff  <= (others => '0');
                --rxff <= (others => '0');
                buf  <= (others => (others => '0'));

                --rsff <= '0';
            elsif rising_edge(clk) then
                s <= sn;

                cff  <= c;
                --rxff <= rxn;
                buf  <= bufn;

                --rsff <= rs;
            end if;
        end process ff;
        
        fsm: process(all)
        begin
            case s is
                when reset => sn <= rsync;
                when rsync => sn <= idle;
                when idle  => sn <= eva when rx_av = '1' else idle;
                when eva   => sn <= ret;
                when ret   => sn <= rsync when so(rec) = '1' and rss = '1'
                               else idle  when so(rec) = '1' 
                               else fin;
                when fin   => sn <= reset when msg_ack = '1' else fin; 
                when others => sn <= s;
            end case;
        end process fsm;
        
        main: process(all)
            variable soo : std_ulogic_vector(STATES - 1 downto 0);
        begin
            soo := so(rec) & so(esc);

            sr <= (others => '0');
            ss <= (others => '0');

            c    <= cff;
            --rxn  <= rxff;
            bufn <= buf;
            
            rx_ack <= '0';

            rs <= '0';

            msg_av <= '0';
            msg_len <= (others => '0');
            msg <= (others => (others => '0'));

            case s is
                when reset =>
                    sr <= (others => '1');
                when rsync =>
                    bufn <= (others => (others => '0'));
                    c <= (others => '0');
                when eva =>
                    rx_ack <= '1';

                    sr(esc) <= '1';
                    
                    case (soo) is
                        when "00" =>
                            if rx_o = x"FB" then
                                rs <= '1';
                                ss(rec) <= '1';
                            end if;
                        when "10" =>
                            case rx_o is
                                when x"FB" =>
                                    rs <= '1';
                                    ss(rec) <= '1';
                                when x"EC" =>
                                    ss(esc) <= '1';
                                    sr(esc) <= '0';
                                when x"FE" =>
                                    sr(rec) <= '1';
                                when others =>
                                    c <= cff + 1 when cff < BUFD;
                                    bufn <= buf(1 to BUFD-1) & rx_o;
                            end case;
                        when "11" =>
                            c <= cff + 1 when cff < BUFD;
                            bufn <= buf(1 to BUFD-1) & rx_o;
                        when others =>
                    end case;
                when fin =>
                    msg_av <= '1';
                    msg_len <= cff;
                    msg <= buf;
                when others =>
            end case;
        end process main;
end architecture rtl;
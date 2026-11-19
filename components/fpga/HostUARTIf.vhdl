----------------------------------------------------------------------------
-- Project		:	OPI-siliconPUdx
-- Authors		:	opilitethesmartdev
-- Description	:	Host UART Interface
----------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.core_pkg.all;
use work.register_pkg.all;
use work.instruction_pkg.all;

entity HostUARTIf is
    generic(
        CLK_HZ : natural := 25_000_000
    );
    port(
        -- Fundamental signals
        clk : in std_ulogic;
        rst : in std_ulogic;

        -- UART Interface
        tx : out std_ulogic;
        rx : in  std_ulogic;

        -- SRAM Interface
        ram_en   : out std_ulogic;
        ram_wren : out std_ulogic;
        ram_mask : out std_ulogic_vector(IBWIDTH - 1 downto 0);
        ram_addr : out unsigned(INSTD - 1 downto 0);
        ram_din  : out std_ulogic_vector(IBWIDTH - 1 downto 0);
        ram_dout : in std_ulogic_vector(IBWIDTH - 1 downto 0);

        -- Register bank interface
        re_cmd  : out std_ulogic_vector(1 downto 0);
        re_addr : out unsigned(REGD-1 downto 0);
        re_i : out std_ulogic_vector(WORDWIDTH-1 downto 0);
        re_o : in  std_ulogic_vector(WORDWIDTH-1 downto 0)
    );

end entity HostUARTIf;

architecture rtl of HostUARTIf is
    -- Constants
        constant DATA_BYTES : natural := 6;
        constant ANS_BYTES : natural := 4;

    -- FSM Definition
        type s_t is (reset, idle, cmdp, w4d, ldd, opf, opr, wrb, wrr, wrs, w4r);
        signal s, sn : s_t;

    -- Type Definitions
        type d_arr is array(0 to DATA_BYTES-1) of std_ulogic_vector(WORDWIDTH - 1 downto 0);
        type a_arr is array(0 to ANS_BYTES-1) of std_ulogic_vector(WORDWIDTH - 1 downto 0);

        type cmd_t is (nop, rdr, rdi, wrr, wri);
    
    -- Arrays
        signal db, dbff : d_arr;
        signal ab, abff : a_arr;

    -- UART Signals
        signal rx_av  :  std_ulogic;
        signal rx_o   :  std_ulogic_vector(7 downto 0);
        signal rx_ack :  std_ulogic;

        signal tx_en  :  std_ulogic;
        signal tx_i   :  std_ulogic_vector(7 downto 0);
        signal tx_fin :  std_ulogic;
        signal tx_ack :  std_ulogic;
    
    -- Internal signals
        signal cmdv : std_ulogic;
        signal cmd, cmdff : cmd_t;

        signal dc, dcff : unsigned(2 downto 0);
        signal ac, acff : unsigned(2 downto 0);
        signal rc, rcff : unsigned(2 downto 0);
begin
    -- Protocol entities
        uart : entity work.UARTIf
            generic map(
                W      => 8,
                CLK_HZ => CLK_HZ,
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

    -- Main Processes
    ff : process(rst, clk)
    begin
        if rst = '1' then
            s <= reset;

            cmdff <= nop;

            dcff <= "000";
            acff <= "000";
            rcff <= "000";

            dbff <= (others => x"00");
            abff <= (others => x"00");
        elsif rising_edge(clk) then
            s <= sn;
            
            cmdff <= cmd;

            dcff <= dc;
            acff <= ac;
            rcff <= rc;

            dbff <= db;
            abff <= ab;
        end if;
    end process ff;

    fsm : process(all)
    begin
        --sn <= s;
        case s is
            when reset => sn <= idle;
            when idle  => sn <= cmdp when rx_av = '1' else idle;
            when cmdp  => sn <= w4d when cmdv = '1' else idle;
            when w4d   => sn <= ldd when rx_av = '1' else w4d;
            when ldd   => sn <= opf when dcff = DATA_BYTES-1 else w4d;
            when opf   => sn <= opr;
            when opr   => sn <= wrb;
            when wrr   => sn <= wrs;
            when wrs   => sn <= wrb;
            when wrb   => sn <= w4r;
            when w4r   => 
                if tx_fin = '1' then
                    sn <= reset when acff = ANS_BYTES else wrr;
                else
                    sn <= w4r;
                end if;
            when others => sn <= reset;
        end case;
    end process fsm;

    main: process(all)
        variable merged : std_ulogic_vector(15 downto 0);
    begin
        -- Defaults
            rx_ack <= '0';
            tx_ack <= '0';

            tx_en <= '0';
            tx_i <= (others => '0');

            merged := (others => '0');

            db <= dbff;
            ab <= abff;

            dc <= dcff;
            ac <= acff;
            rc <= rcff;
            
            cmdv <= '0';
            cmd <= cmdff;
            
            ram_en   <= '0';
            ram_wren <= '0';
            ram_addr <= (others => '0');
            ram_mask <= (others => '0');
            ram_din  <= (others => '0');
            
            re_cmd  <= "00";
            re_addr <= (others => '0');
            re_i    <= (others => '0');

        case s is
            when reset =>
                rx_ack <= '1';
                tx_ack <= '1';

                db <= (others => x"00");
                ab <= (others => x"00");

                dc <= (others => '0');
                ac <= (others => '0');
                rc <= (others => '0');
            when idle  =>
            when cmdp  =>
                case rx_o is
                    when x"FA" => cmd <= rdr;
                    when x"FB" => cmd <= rdi;
                    when x"FC" => cmd <= wrr;
                    when x"FD" => cmd <= wri;
                    when others => cmd <= nop;
                end case;

                cmdv <= '0' when cmd = nop else '1';
                rx_ack <= '1';
            when w4d   =>
            when ldd   =>
                db(to_integer(dcff)) <= rx_o;
                dc <= dcff + 1;
                rx_ack <= '1';
            when opf   =>
                merged := dbff(0) & dbff(1);

                case cmdff is
                    when rdi =>
                        ram_en <= '1';
                        ram_addr <= unsigned(merged(INSTD - 1 downto 0));
                        ram_mask <= (others => '1');
                    when wri =>
                        ram_en <= '1';
                        ram_wren <= '1';
                        ram_addr <= unsigned(merged(INSTD - 1 downto 0));
                        ram_mask <= (others => '1');
                        ram_din <= dbff(2) & dbff(3) & dbff(4) & dbff(5);
                    when rdr =>
                        re_cmd <= "10";
                        re_addr <= unsigned(dbff(1)(REGD-1 downto 0));
                    when wrr =>
                        re_cmd <= "01";
                        re_addr <= unsigned(dbff(1)(REGD-1 downto 0));
                        re_i <= dbff(3);
                    when others =>
                end case;
            when opr   =>
                case cmdff is
                    when rdi =>
                        for i in 0 to ANS_BYTES-1 loop
                            ab(i) <= ram_dout(8*(i+1)-1 downto 8*i);
                        end loop;
                    when rdr =>
                            ab(0) <= re_o;
                    when wri =>                    
                        for i in 0 to ANS_BYTES-1 loop
                            ab(i) <= (others => '1');
                        end loop;
                    when wrr =>                    
                        for i in 0 to ANS_BYTES-1 loop
                            ab(i) <= (others => '1');
                        end loop;
                    when others =>
                end case;
            when wrr   =>
                tx_ack <= '1';
            when wrb   =>
                ac <= acff + 1;
                tx_en <= '1';
                tx_i <= ab(to_integer(acff));
            when w4r   =>
            when others =>
        end case;
    end process main;

end architecture rtl;
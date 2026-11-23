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
        BUFD : natural := 16
    );
    port (
        clk : in std_ulogic;
        rst : in std_ulogic;

        -- UART RX Application Interface
        rx_av  : out std_ulogic;
        rx_o   : out std_ulogic_vector(UWW - 1 downto 0);
        rx_ack : in  std_ulogic;

        -- Output
        msg_av  : out std_ulogic;
        msg_ack : in std_ulogic;
        msg     : out uart_t(0 to BUFD-1)      
    );
end entity CmdBufferUARTrxIf;

architecture rtl of CmdBufferUARTrxIf is
    -- Constants
        constant STATES : natural := 4;

    -- Array
        signal buf : uart_t(0 to BUFD-1);

    -- FSM Signals
        type s_t is (res, idl, ld, p, ret, fin);
        signal s,sn : s_t;

    -- Transient state interface
        signal ss  :  std_ulogic_vector(STATES-1 downto 0);
        signal sr  :  std_ulogic_vector(STATES-1 downto 0);
        signal so  :  std_ulogic_vector(STATES-1 downto 0);

    -- Transient state mappings
        constant rec : integer := 0;
        constant esc : integer := 1;
        constant ovf : integer := 2;
        constant val : integer := 3;
begin
    -- Transient State Interface
        tsif : entity work.TransientStateIf
            generic map(
                STATES => 4
            )
            port map(
                clk => clk,
                rst => rst,
                ss  => ss,
                sr  => sr,
                so  => so
        );

    -- FSM Byte handler
    -- FSM Processes
        ff: process(rst, clk)
        begin
            if rst = '1' then
                s <= res;
            elsif rising_edge(clk) then
                s <= sn;
            end if;
        end process ff;
        
        fsm: process(all)
        begin
            case s is
                when res => sn <= idl;
                when idl => sn <= ld when rx_ack = '1' else idl;
                when ld  => sn <= p;
                when p   => sn <= ret;
                when ret => sn <= fin when so(val) = '1' else idl;
                when fin => sn <= res when ack = '1' else fin;
                when others => sn <= s;
            end case;
        end process fsm;
        
        main: process(all)
        begin
            case s is
                when res =>
                when others =>
            end case;
        end process main;
end architecture rtl;
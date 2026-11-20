----------------------------------------------------------------------------
-- Project		:	OPI-siliconPUdx
-- Authors		:	opilitethesmartdev
-- Description	:	FPGA harness for UART
----------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.core_pkg.all;
use work.register_pkg.all;
use work.instruction_pkg.all;

entity uart_harness is
    port(
        -- Fundamental signals
        clk : in std_ulogic;
        rst : in std_ulogic;

        -- UART
        rx : in  std_ulogic;
        tx : out std_ulogic;

        -- FPGA LED
        led : out std_ulogic_vector(5 downto 0)
    );

end entity uart_harness;

architecture rtl of uart_harness is
    signal rst_n    :  std_ulogic;

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

    signal re_err    :  std_ulogic;
begin
    i_HostUARTIf : entity work.HostUARTIf
        generic map(
            CLK_HZ => 27_000_000
        )
        port map(
            clk      => clk,
            rst      => rst_n,
            tx       => tx,
            rx       => rx,
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
            WORDWIDTH => 32,
            WORDDEPTH => 9
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
            err    => re_err,
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

    led <= rst & rx & tx & not('0' & re_err & '0');
    rst_n <= not rst;

end architecture rtl;
----------------------------------------------------------------------------
-- Project		:	OPI-siliconPUdx
-- Authors		:	opilitethesmartdev
-- Description	:	FPGA harness
----------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.core_pkg.all;
use work.register_pkg.all;
use work.instruction_pkg.all;

entity fpga_harness is
    port(
        -- Fundamental signals
        clk : in std_ulogic;
        rst : in std_ulogic;
        en : in  std_ulogic;
        o  : out std_ulogic_vector(1 downto 0);

        -- UART
        rx : in  std_ulogic;
        tx : out std_ulogic;

        -- FPGA LED
        led : out STD_ULOGIC
    );

end entity fpga_harness;

architecture rtl of fpga_harness is
    signal rst_n        :  std_ulogic;
    signal ena          :  std_ulogic;

    -- SRAM Access Arbitration
    signal ram_sel        :  std_ulogic;

    -- Source SRAM
    signal ram_en   :  std_ulogic;
    signal ram_wren :  std_ulogic;
    signal ram_mask :  std_ulogic_vector(IBWIDTH-1 downto 0);
    signal ram_addr :  unsigned(INSTD-1 downto 0);
    signal ram_din  :  std_ulogic_vector(IBWIDTH-1 downto 0);
    signal ram_dout :  std_ulogic_vector(IBWIDTH-1 downto 0);

    -- Toplevel SRAM Access
    signal ram_a_en   :  std_ulogic;
    signal ram_a_wren :  std_ulogic;
    signal ram_a_mask :  std_ulogic_vector(IBWIDTH-1 downto 0);
    signal ram_a_addr :  unsigned(INSTD-1 downto 0);
    signal ram_a_din  :  std_ulogic_vector(IBWIDTH-1 downto 0);
    signal ram_a_dout :  std_ulogic_vector(IBWIDTH-1 downto 0);

    -- Host Serial Converter SRAM Access
    signal  hsc_ram_en   :  std_ulogic;
    signal  hsc_ram_wren :  std_ulogic;
    signal  hsc_ram_mask :  std_ulogic_vector(IBWIDTH-1 downto 0);
    signal  hsc_ram_addr :  unsigned(INSTD-1 downto 0);
    signal  hsc_ram_din  :  std_ulogic_vector(IBWIDTH-1 downto 0);
    signal  hsc_ram_dout :  std_ulogic_vector(IBWIDTH-1 downto 0);

    signal re_cmd      :  std_ulogic_vector(1 downto 0);
    signal re_addr     :  unsigned(REGD-1 downto 0);
    signal re_i        :  std_ulogic_vector(WORDWIDTH-1 downto 0);
    signal re_o        :  std_ulogic_vector(WORDWIDTH-1 downto 0);

    signal mosi        :  std_ulogic;
    signal t_si        :  std_ulogic;
    signal miso        :  std_ulogic;
    signal t_so        :  std_ulogic;
      
begin
    sram_muxif : entity work.SRAMMuxIf
        port map(
            sel        => ram_sel,
            ram_en     => ram_en,
            ram_wren   => ram_wren,
            ram_mask   => ram_mask,
            ram_addr   => ram_addr,
            ram_din    => ram_din,
            ram_dout   => ram_dout,
            ram_0_en   => hsc_ram_en,
            ram_0_wren => hsc_ram_wren,
            ram_0_mask => hsc_ram_mask,
            ram_0_addr => hsc_ram_addr,
            ram_0_din  => hsc_ram_din,
            ram_0_dout => hsc_ram_dout,
            ram_1_en   => ram_a_en,
            ram_1_wren => ram_a_wren,
            ram_1_mask => ram_a_mask,
            ram_1_addr => ram_a_addr,
            ram_1_din  => ram_a_din,
            ram_1_dout => ram_a_dout
        );    

    i_toplevel : entity work.toplevel
        port map(
            clk         => clk,
            rst         => rst_n,
            en          => ena,
            o           => o,
            ram_en      => ram_a_en,
            ram_wren    => ram_a_wren,
            ram_mask    => ram_a_mask,
            ram_addr    => ram_a_addr,
            ram_dout    => ram_a_dout,
            re_cmd      => re_cmd,
            re_addr     => re_addr,
            re_i        => re_i,
            re_o        => re_o,
            instruction => open
        );

    hscif : entity work.HostSerialIf
        port map(
            clk      => clk,
            rst      => rst_n,
            mosi     => mosi,
            t_si     => t_si,
            miso     => miso,
            t_so     => t_so,
            ram_en   => hsc_ram_en,
            ram_wren => hsc_ram_wren,
            ram_mask => hsc_ram_mask,
            ram_addr => hsc_ram_addr,
            ram_din  => hsc_ram_din,
            ram_dout => hsc_ram_dout,
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

    i_UARTSerialBridge : entity work.UARTSerialBridge
        generic map(
            SERIAL_W => 8,
            CLK_HZ   => 27_000_000,
            BAUD     => 115200
        )
        port map(
            clk  => clk,
            rst  => rst,
            rx   => rx,
            tx   => tx,
            mosi => miso,
            t_si => t_so,
            miso => mosi,
            t_so => t_si
    );

    rst_n <= not rst;

    enff : entity work.t_ff
        port map(
            clk => clk,
            i   => en,
            o   => ena
    );

    led <= not ena;

end architecture rtl;
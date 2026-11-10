----------------------------------------------------------------------------
-- Project		:	OPI-siliconPUdx
-- Authors		:	opilitethesmartdev
-- Description	:	SRAM Arbiter
----------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.core_pkg.all;
use work.register_pkg.all;
use work.instruction_pkg.all;

entity SRAMArbiterIf is
    port (
        clk : in std_ulogic;
        rst : in std_ulogic;
        
        -- Control Interface
        req: in std_ulogic_vector(1 downto 0);
        rsv: out std_ulogic_vector(1 downto 0);
        
        -- Source Interface
        ram_en   : out std_ulogic;
        ram_wren : out std_ulogic;
        ram_mask : out std_ulogic_vector(IBWIDTH - 1 downto 0);
        ram_addr : out unsigned(INSTD - 1 downto 0);
        ram_din  : out std_ulogic_vector(IBWIDTH - 1 downto 0);
        ram_dout : in std_ulogic_vector(IBWIDTH - 1 downto 0);
        
        -- Interface A
        ram_a_en   : in std_ulogic;
        ram_a_wren : in std_ulogic;
        ram_a_mask : in std_ulogic_vector(IBWIDTH - 1 downto 0);
        ram_a_addr : in unsigned(INSTD - 1 downto 0);
        ram_a_din  : in std_ulogic_vector(IBWIDTH - 1 downto 0);
        ram_a_dout : out std_ulogic_vector(IBWIDTH - 1 downto 0);
        
        -- Interface B
        ram_b_en   : in std_ulogic;
        ram_b_wren : in std_ulogic;
        ram_b_mask : in std_ulogic_vector(IBWIDTH - 1 downto 0);
        ram_b_addr : in unsigned(INSTD - 1 downto 0);
        ram_b_din  : in std_ulogic_vector(IBWIDTH - 1 downto 0);
        ram_b_dout : out std_ulogic_vector(IBWIDTH - 1 downto 0)
    );
end entity SRAMArbiterIf;

architecture rtl of SRAMArbiterIf is
    signal int : std_ulogic_vector(1 downto 0);
begin
    seq: process (clk, rst)
    begin
        if rst = '1' then            
            int <= "00";
        elsif rising_edge(clk) then  
            if req(1) = '1' then
                int <= "10";
            elsif req(0) = '1' then
                int <= "01";
            else
                int <= "00";
            end if;          
        end if;
    end process seq;

    rsv <= int;

    ram_en   <= ram_a_en   when int = "10" 
           else ram_b_en   when int = "01" 
           else '0';
    ram_wren <= ram_a_wren when int = "10" 
           else ram_b_wren when int = "01" 
           else '0';
    ram_mask <= ram_a_mask when int = "10" 
           else ram_b_mask when int = "01" 
           else (others => '0');
    ram_addr <= ram_a_addr when int = "10" 
           else ram_b_addr when int = "01" 
           else (others => '0');
    ram_din  <= ram_a_din  when int = "10" 
           else ram_b_din  when int = "01" 
           else (others => '0');

    ram_a_dout <= ram_dout when int = "10" else (others => '0');
    ram_b_dout <= ram_dout when int = "01" else (others => '0');
end rtl;
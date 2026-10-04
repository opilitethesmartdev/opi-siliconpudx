architecture mock of RegisterBank is
    constant reg_default : reg_array_t  := (   
            ("00" & x"01"), --0 ptr
            ("00" & x"02"), --1 ptr
            ("00" & x"08"), --2 lit
            ("00" & x"00"), --3 u
            ("00" & x"06"), --4 ptr
            ("00" & x"00"), --5 lit
            ("00" & x"05"), --6 ptr
            ("00" & x"00"), --7 u
        others => REGNULL);

    signal regs : reg_array_t;
begin
    seq : process(rst, clk)
    begin
        if rst = '1' then
            regs <= reg_default;
        elsif rising_edge(clk) then
            if cmd = "01" then
                regs(to_integer(addr)) <= regi;
            end if;
        end if;
    end process seq;

    rego <= regs(to_integer(addr)) when cmd = "10" else REGNULL;
end architecture mock;
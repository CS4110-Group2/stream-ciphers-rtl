-- (adapted from) Listing 5.1
library ieee;
use ieee.std_logic_1164.all;
entity ctr_path is
    port(
        clk, reset: in std_logic;
        rx_done, tx_done: in std_logic;
        ascii_r, ascii_t: in std_logic_vector(7 downto 0);
        clra_ram, inca_ram, clrb_ram, incb_ram, wr, tx_start: out std_logic
    );
end ctr_path;

architecture arch of ctr_path is
    type state_type is (s0, s1, s2, s3);
    signal state_reg, state_next: state_type;
begin

    -- state register
    process(clk,reset)
    begin
        if (reset='1') then
            state_reg <= s0;
        elsif rising_edge(clk) then
            state_reg <= state_next;
        end if;
    end process;

    -- next-state and outputs logic
    process(state_reg, rx_done, tx_done, ascii_r, ascii_t)
    begin
        clra_ram <= '0';
        inca_ram <= '0';
        clrb_ram <= '0';
        incb_ram <= '0';
        wr <= '0';
        tx_start <= '0';
        state_next <= state_reg;

        case state_reg is
            when s0 =>
                clra_ram <= '1';
                clrb_ram <= '1';
                state_next <= s1;
            when s1 =>
                if (rx_done='1') then
                    if ((ascii_r >= x"41" and ascii_r <= x"5A") or
                        (ascii_r >= x"61" and ascii_r <= x"7A") or
                         ascii_r = x"20" or ascii_r = x"0D") then
                        wr <= '1';

                        if (ascii_r = x"20") then
                            incb_ram <= '1';
                            state_next <= s1;
                        else
                            if (ascii_r=x"0D") then
                                clrb_ram <= '1';
                                state_next <= s2;
                            else
                                inca_ram <= '1';
                                incb_ram <= '1';
                            end if;
                        end if;
                    end if;
                end if;
            when s2 =>
                if (ascii_t=x"0D") then
                    state_next <= s0;
                else
                    tx_start <= '1';
                    state_next <= s3;
                end if;
            when s3 =>
                if (tx_done='1') then
                    incb_ram <= '1';
                    state_next <= s2;
                end if;
        end case;
    end process;

end arch;
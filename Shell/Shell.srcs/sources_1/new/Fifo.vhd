

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
 use IEEE.NUMERIC_STD.ALL;


entity Fifo is
    Generic( B: natural := 8;
             W: natural := 4);
    Port ( clk : in STD_LOGIC;
           rst : in STD_LOGIC;
           rd : in STD_LOGIC;
           wr : in STD_LOGIC;
           w_data : in STD_LOGIC_VECTOR (B - 1 downto 0);
           empty : out STD_LOGIC;
           full : out STD_LOGIC;
           r_data : out STD_LOGIC_VECTOR (B -1 downto 0));
end Fifo;

architecture Behavioral of Fifo is

    type Reg_File_Type is array (0 to (2**W - 1)) of std_logic_vector((B - 1) downto 0);
    signal reg_file : Reg_File_Type;

    signal r_reg, r_next, r_succ : std_logic_vector(W - 1 downto 0);
    signal w_reg, w_next, w_succ : std_logic_vector(W - 1 downto 0);
    signal full_reg, full_next : std_logic;
    signal empty_reg, empty_next : std_logic;

    signal wr_en : std_logic;
    signal wr_op : std_logic_vector(1 downto 0);

begin

    process(clk, rst)
    begin
        if rst = '1' then
            reg_file <= (others => (others => '0'));
        elsif rising_edge(clk) then
            if wr_en = '1' then
                reg_file(to_integer(unsigned(w_reg))) <= w_data;
            end if;
        end if;
    end process;

    r_data <= reg_file(to_integer(unsigned(r_reg)));
    wr_en <= wr and (not full_reg);


    process(clk, rst)
    begin
        if rst = '1' then
            r_reg <= (others => '0');
            w_reg <= (others => '0');
            full_reg <= '0';
            empty_reg <= '1';
        elsif rising_edge(clk) then
            r_reg <= r_next;
            w_reg <= w_next;
            full_reg <= full_next;
            empty_reg <= empty_next;
        end if;
    end process;

    r_succ <= std_logic_vector(unsigned(r_reg) + 1);
    w_succ <= std_logic_vector(unsigned(w_reg) + 1);

    wr_op <= wr & rd;

    process(w_reg, w_succ, r_reg, r_succ, wr_op, empty_reg, full_reg)
    begin
        w_next <= w_reg;
        r_next <= r_reg;
        full_next <= full_reg;
        empty_next <= empty_reg;

        case wr_op is
            when "00" => -- NOOP
            when "01" => --read
                if empty_reg = '0' then
                    r_next <= r_succ;
                    full_next <= '0';
                    if r_succ = w_reg then
                        empty_next <= '1';
                    end if;
                end if;
            when "10" => -- write
                if full_reg = '0' then
                    w_next <= w_succ;
                    empty_next <= '0';
                    if w_succ = r_reg then
                        full_next <= '1';
                    end if;
                end if;

            when others => --r/w
                w_next <= w_succ;
                r_next <= r_succ;
        end case;
    end process;

    full <= full_reg;
    empty <= empty_reg;

end Behavioral;

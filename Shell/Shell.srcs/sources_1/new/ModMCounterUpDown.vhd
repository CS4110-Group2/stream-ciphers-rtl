


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


entity ModMCounterUpDown is
    Generic( N : integer := 4;
             M : Integer := 16);
    Port ( en : in STD_LOGIC;
           up_down : in STD_LOGIC;
           clk : in STD_LOGIC;
           clr : in STD_LOGIC;
           zero : out STD_LOGIC; 
           q : out STD_LOGIC_VECTOR (N-1 downto 0));
end ModMCounterUpDown;

architecture Behavioral of ModMCounterUpDown is


begin

    process(clk)
    variable cnt : integer RANGE 0 to M-1;
    variable direction : integer;
    begin
        if up_down = '0' then
            direction := 1;
        else
            direction := -1;
        end if;

        if(rising_edge(clk)) then
            if(clr = '1') then
                cnt := 0;
            else
                if(en = '1') then
                    cnt := cnt + direction; 
                end if;
            end if;
        end if;
        q <= (std_logic_vector(to_unsigned(cnt, q'length)));
        if cnt = 0 then
            zero <= '1'; 
        else
            zero <= '0';
        end if;

    end process;



end Behavioral;

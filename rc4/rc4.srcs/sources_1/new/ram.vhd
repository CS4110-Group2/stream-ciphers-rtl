library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity ram is
    Port ( data_in  : in  STD_LOGIC_VECTOR (7 downto 0);
           data_out : out STD_LOGIC_VECTOR (7 downto 0);
           address  : in  STD_LOGIC_VECTOR (7 downto 0);
           clk      : in  STD_LOGIC;
           write    : in  STD_LOGIC);
end ram;

architecture Behavioral of ram is

    type mem is array (0 to 255) of STD_LOGIC_VECTOR (7 downto 0);
    signal ram : mem := (others => (others => '0'));

begin
    process (clk, write)
    begin
        if (rising_edge(clk)) then
            if (write = '1') then
                ram(to_integer(UNSIGNED(address))) <= data_in;
            end if;
        end if;
    end process;

    data_out <= ram(to_integer(UNSIGNED(address)));

end Behavioral;

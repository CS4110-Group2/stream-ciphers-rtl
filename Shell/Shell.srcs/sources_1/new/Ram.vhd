library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


entity Ram is
    Generic(WORDSIZE : integer := 8;
            ADDRSIZE : integer := 8);
    Port ( clk      : in  STD_LOGIC;
           wr       : in  STD_LOGIC := '0';
           clr      : in  STD_LOGIC := '0';
           data_in  : in  STD_LOGIC_VECTOR (WORDSIZE-1 downto 0);
           addr     : in  STD_LOGIC_VECTOR (ADDRSIZE-1 downto 0);
           data_out : out STD_LOGIC_VECTOR (WORDSIZE-1 downto 0));
end Ram;

architecture Behavioral of Ram is

    type MemoryType is array(0 to 2**ADDRSIZE - 1) of std_logic_vector(WORDSIZE-1 downto 0) ;
    shared variable memory : MemoryType := (others => (others => '0'));

begin

    process(clk)
    begin
        if rising_edge(clk) then
            if clr = '1' then
                memory(to_integer(unsigned(addr))) := (others => '0');
            elsif wr = '1' then
                memory(to_integer(unsigned(addr))) := data_in;
            end if;
        end if;
    end process;

    data_out <= memory(to_integer(unsigned(addr)));

end Behavioral;

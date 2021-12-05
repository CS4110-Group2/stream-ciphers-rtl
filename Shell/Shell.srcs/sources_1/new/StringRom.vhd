
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.STD_LOGIC_TEXTIO.ALL;
use STD.TEXTIO.ALL;
     
entity StringRom is
    Generic(AddrSize : Integer := 7;
            DataSize : Integer := 50); 
    Port ( clk : in STD_LOGIC; 
           rst : in STD_LOGIC; 
           addr :           in STD_LOGIC_VECTOR (AddrSize-1 downto 0);
           -- dataOut :    out string(1 to DataSize));
           dataOut :    out STD_LOGIC_VECTOR(7 downto 0);
           inc_char_cnt : in STD_LOGIC; 
           clear_char_cnt : in STD_LOGIC;
           line_done : out STD_LOGIC); 
end StringRom; 

--Rom is filled with contents of file prog.bin
--File has to be 128 lines of binary, with a newline for each byte
architecture Behavioral of StringRom is

    type memory_type is array(0 to (2**AddrSize)-1) of string(1 to DataSize);

    impure function getFile(fileName : string) return memory_type is
        file fileHandle : TEXT open READ_MODE is FileName;
        variable currentLine : LINE;
        variable stringLine : string(1 to DataSize-2);
        variable result : memory_type := (others => (others => '0'));
        variable lineNumber : integer := 0;
    begin
        --Write enter and linefeed to first index
        while not endFile(fileHandle) loop
            readline(fileHandle, currentLine);
            assert currentLine'length < stringLine'length;
            stringLine := (others => ' ');
            -- if currentLine'length > 0 then
            read(currentLine, stringLine(1 to currentLine'length));
            -- end if;
            --Handle empty lines
            if(stringLine(1) = '\' and stringLine(2) = 'n') then
                stringLine := (others => ' '); -- read(currentLine, tempWord);
            end if;
            if stringLine(1) /= ';' then
                result(lineNumber) := (stringLine & character'val(16#0d#) & character'val(16#0A#));
                lineNumber := lineNumber + 1;
            end if;
        end loop;
        stringLine := (others => ']');
        while lineNumber < DataSize loop
            result(lineNumber) := stringLine & "  ";
            lineNumber := lineNumber + 1;
        end loop;
        return result;
    end function;
    
    signal memory : memory_type := getFile("../../../menurom.txt");

begin

    process(clk, rst)
        variable cnt : integer RANGE 1 to DataSize;
        variable I : integer RANGE 0 to (2**AddrSize);
    begin
        if rst = '1' then
            cnt := 1;
        elsif(rising_edge(clk)) then
            if(clear_char_cnt = '1') then
                cnt := 1;
            else
                if(inc_char_cnt = '1') then
                    cnt := cnt + 1; 
                end if;
            end if;
            I := to_integer(unsigned(addr));
            dataOut <= std_logic_vector(to_unsigned(character'pos(memory(I)(cnt)), dataOut'length));
            if cnt = DataSize then
                line_done <= '1'; 
            else
                line_done <= '0';
            end if;
        end if;


    end process;

    -- dataOut <= memory(to_integer(unsigned(addr)));
end Behavioral;

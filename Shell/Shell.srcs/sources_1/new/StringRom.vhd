
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.STD_LOGIC_TEXTIO.ALL;
use STD.TEXTIO.ALL;
use work.Shell_Constants.all;
     
entity StringRom is
    Generic(AddrSize : Integer := 7;
            DataSize : Integer := 50); 
    Port ( clk            : in  STD_LOGIC; 
           rst            : in  STD_LOGIC; 
           addr           : in  STD_LOGIC_VECTOR (AddrSize-1 downto 0);
           dataOut        : out STD_LOGIC_VECTOR(7 downto 0);
           inc_char_cnt   : in  STD_LOGIC; 
           clear_char_cnt : in  STD_LOGIC;
           line_done      : out STD_LOGIC); 
end StringRom; 

--Rom is filled with contents of file menurom.txt plus special char sequences.
architecture Behavioral of StringRom is

    type memory_type is array(0 to (2**AddrSize)-1) of string(1 to DataSize);

    impure function getFile(fileName : string) return memory_type is
        file fileHandle : TEXT open READ_MODE is FileName;
        variable currentLine : LINE;
        variable stringLine : string(1 to DataSize);
        variable result : memory_type := (others => (others => '0'));
        variable lineNumber : integer := 0;
    begin
        --Place newline sequence at index 0
        result(lineNumber) := (others => ' ');
        result(lineNumber)(1) := character'val(to_integer(unsigned(ENTER)));
        result(lineNumber)(2) := character'val(to_integer(unsigned(LINEFEED)));
        lineNumber := lineNumber + 1;
        --Place prompt sequence at index 1
        result(lineNumber) := (others => ' ');
        result(lineNumber)(1) := character'val(to_integer(unsigned(PROMPT)));
        lineNumber := lineNumber + 1;
        --Place backspace sequence at index 2
        result(lineNumber) := (others => ' ');
        result(lineNumber)(1) := character'val(to_integer(unsigned(BACKSPACE)));
        result(lineNumber)(2) := character'val(to_integer(unsigned(SPACE)));
        result(lineNumber)(3) := character'val(to_integer(unsigned(BACKSPACE)));
        lineNumber := lineNumber + 1;
        
        --Read from file and fill rom 
        while not endFile(fileHandle) loop
            readline(fileHandle, currentLine);
            assert currentLine'length < stringLine'length;
            stringLine := (others => ' ');
            read(currentLine, stringLine(1 to currentLine'length));

            --Treat ; as comment
            if stringline(1) /= ';' then

            --Convert \n to CRLF right after text
                for i in 1 to stringLine'length loop
                    if(i > 1 and stringLine(i-1) = '\' and stringLine(i) = 'n') then
                        result(lineNumber)(i-1) := character'val(to_integer(unsigned(ENTER)));
                        result(lineNumber)(i) := character'val(to_integer(unsigned(LINEFEED)));
                    else
                        result(lineNumber)(i) := stringLine(i);
                    end if;
                end loop;
            lineNumber := lineNumber + 1;
            end if;
        end loop;
        --Fill rest of ram with ']'
        stringLine := (others => ']');
        while lineNumber < DataSize loop
            result(lineNumber) := stringLine;
            lineNumber := lineNumber + 1;
        end loop;
        return result;
    end function;
    
    signal memory : memory_type := getFile("../../../menurom.txt");
    signal outBuf : std_logic_vector(7 downto 0);
    shared variable cnt : integer RANGE 1 to DataSize;

begin

    --Output a single character based on current line and character count.
    --Synchronous read
    process(clk, rst)
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
            outBuf <= std_logic_vector(to_unsigned(character'pos(memory(to_integer(unsigned(addr)))(cnt)), dataOut'length));
        end if;
    end process;

    --Set line done signal when end of line or special sequence is over 
    line_done <= '1' when cnt = DataSize or outBuf = LINEFEED or (outBuf = PROMPT and cnt = 1) or (outBuf = BACKSPACE and cnt = 3) else
                 '0';

    dataOut <= outBuf;

end Behavioral;

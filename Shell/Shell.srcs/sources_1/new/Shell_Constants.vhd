
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
package Shell_Constants is
    constant RC4_KEY : string := "ZAAAAAAA";
    constant ASCII_TO_HEX_LSB     : std_logic := '0';
    constant ASCII_TO_HEX_MSB     : std_logic := '1';

    constant OUTPUT_MUX_INPUT     : std_logic_vector(2 downto 0) := "000";
    constant OUTPUT_MUX_RC4_ASCII : std_logic_vector(2 downto 0) := "001";
    constant OUTPUT_MUX_RC4_HEX   : std_logic_vector(2 downto 0) := "010";
    constant OUTPUT_MUX_MENUROM   : std_logic_vector(2 downto 0) := "100";
    constant OUTPUT_MUX_AUTOCLAVE : std_logic_vector(2 downto 0) := "101";

    constant ENCRYPT             : std_logic := '1';
    constant DECRYPT             : std_logic := '0';
    constant RC4_INPUT_MUX_ASCII : std_logic := '0';
    constant RC4_INPUT_MUX_HEX   : std_logic := '1';

    constant CIPHER_RC4       : std_logic := '1';
    constant CIPHER_AUTOCLAVE : std_logic := '0';

    --Menu rom addresses
    constant NEWLINE_SEQUENCE_START_ADDRESS         : std_logic_vector(7 downto 0) := x"00";
    constant NEWLINE_SEQUENCE_STOP_ADDRESS          : std_logic_vector(7 downto 0) := x"01";
    constant PROMPT_SEQUENCE_START_ADDRESS          : std_logic_vector(7 downto 0) := x"01";
    constant PROMPT_SEQUENCE_STOP_ADDRESS           : std_logic_vector(7 downto 0) := x"02";
    constant BACKSPACE_SEQUENCE_START_ADDRESS       : std_logic_vector(7 downto 0) := x"02";
    constant BACKSPACE_SEQUENCE_STOP_ADDRESS        : std_logic_vector(7 downto 0) := x"03";
    constant HELP_START_ADDRESS                     : std_logic_vector(7 downto 0) := x"03";
    constant HELP_STOP_ADDRESS                      : std_logic_vector(7 downto 0) := x"0F";
    constant SPLASH_START_ADDRESS                   : std_logic_vector(7 downto 0) := x"03";
    constant SPLASH_STOP_ADDRESS                    : std_logic_vector(7 downto 0) := x"06";
    constant ILLEGAL_COMMAND_START_ADDRESS          : std_logic_vector(7 downto 0) := x"0F";
    constant ILLEGAL_COMMAND_STOP_ADDRESS           : std_logic_vector(7 downto 0) := x"10";
    constant ILLEGAL_CIPHER_COMMAND_START_ADDRESS   : std_logic_vector(7 downto 0) := x"10";
    constant ILLEGAL_CIPHER_COMMAND_STOP_ADDRESS    : std_logic_vector(7 downto 0) := x"11";
    constant ILLEGAL_CIPHER_START_ADDRESS           : std_logic_vector(7 downto 0) := x"11";
    constant ILLEGAL_CIPHER_STOP_ADDRESS            : std_logic_vector(7 downto 0) := x"12";
    constant SELECTED_RC4_START_ADDRESS             : std_logic_vector(7 downto 0) := x"12";
    constant SELECTED_RC4_STOP_ADDRESS              : std_logic_vector(7 downto 0) := x"13";
    constant SELECTED_AUTOCLAVE_START_ADDRESS       : std_logic_vector(7 downto 0) := x"13";
    constant SELECTED_AUTOCLAVE_STOP_ADDRESS        : std_logic_vector(7 downto 0) := x"14";

    constant SPACE       : std_logic_vector(7 downto 0) := x"20";
    constant ENTER       : std_logic_vector(7 downto 0) := x"0d";
    constant DELETE      : std_logic_vector(7 downto 0) := x"7F";
    constant PROMPT      : std_logic_vector(7 downto 0) := x"3e";
    constant LINEFEED    : std_logic_vector(7 downto 0) := x"0A";
    constant BACKSPACE   : std_logic_vector(7 downto 0) := x"08";
    constant DASH        : std_logic_vector(7 downto 0) := x"2D";

    constant HELPCOMMAND    : std_logic_vector(7 downto 0) := x"68";
    constant ENCRYPTCOMMAND : std_logic_vector(7 downto 0) := x"65";
    constant DECRYPTCOMMAND : std_logic_vector(7 downto 0) := x"64";
    constant RESETCOMMAND   : std_logic_vector(7 downto 0) := x"72";
    constant CIPHERCOMMAND  : std_logic_vector(7 downto 0) := x"63";

    constant ACCEPT_HEX           : std_logic := '1';
    constant ACCEPT_ASCII         : std_logic := '0';
    constant ASCII_START          : std_logic_vector(7 downto 0) := x"21";
    constant ASCII_STOP           : std_logic_vector(7 downto 0) := x"7E";
    constant HEX_NUM_START        : std_logic_vector(7 downto 0) := x"30";
    constant HEX_NUM_STOP         : std_logic_vector(7 downto 0) := x"39";
    constant HEX_CHAR_UPPER_START : std_logic_vector(7 downto 0) := x"41";
    constant HEX_CHAR_UPPER_STOP  : std_logic_vector(7 downto 0) := x"46";
    constant HEX_CHAR_LOWER_START : std_logic_vector(7 downto 0) := x"61";
    constant HEX_CHAR_LOWER_STOP  : std_logic_vector(7 downto 0) := x"66";
end package;

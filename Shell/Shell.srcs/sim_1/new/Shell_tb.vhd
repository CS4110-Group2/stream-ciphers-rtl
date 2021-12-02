
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use ieee.math_real.all;
use std.env.finish;
use IEEE.std_logic_textio.all;

entity Shell_tb is
--  Port ( );
	end Shell_tb;

architecture Behavioral of Shell_tb is
	constant BAUDRATE : integer := 19200;
	constant MCount : integer := integer(100000000/(BAUDRATE*16));
	constant NBits : integer := integer(ceil(log2(real(MCount))));
	signal baudrate_tick, rx, rx_done_tick : std_logic;
	signal rx_data : std_logic_vector(7 downto 0);

	signal clk_period : time := 10 ns;
	signal clk : STD_LOGIC;
	signal rst : STD_LOGIC;
	signal RsRx : STD_LOGIC;
	signal RsTx : STD_LOGIC;
	signal seg : STD_LOGIC_VECTOR (7 downto 0);
	signal an : STD_LOGIC_VECTOR (3 downto 0);
	signal cipher_select_signal : STD_LOGIC;
	signal led_signal : STD_LOGIC;

	Component Shell is
		Port ( clk : in STD_LOGIC;
			   rst : in STD_LOGIC;
			   RsRx : in STD_LOGIC;
			   RsTx : out STD_LOGIC;
			   cipher_select_signal : in STD_LOGIC;
			   led_signal : out STD_LOGIC;
			   seg : out STD_LOGIC_VECTOR (7 downto 0);
			   an : out STD_LOGIC_VECTOR (3 downto 0));
	end Component;

	procedure writeUart
	( 
	constant c: in std_logic_vector(7 downto 0); 
	signal rx : out std_logic; 
	constant bitrate : in integer := 19200 
) 
is
constant wait_time : time := integer(real(real(1)/real(bitrate))*1000000) *1 us;
	-- constant c : unsigned(7 downto 0) := to_unsigned(char, 8);
	begin
		rx <= '0';
		wait for wait_time; -- Start bit

		for i in 0 to c'length-1 loop
			rx <= c(i);
			wait for wait_time;
		end loop;
		rx <= '1';
		wait for wait_time; -- Stop bit
	--wait for wait_time*20;
	end procedure writeUart;

	procedure readUart
	(
	signal expectedVal : in STD_LOGIC_VECTOR (7 downto 0)
)
is
	begin

		wait until rising_edge(clk) and rx_done_tick = '1';
		if expectedVal /= x"00" then
			assert rx_data = expectedVal
			severity failure;
		end if;
	end procedure readUart;

	constant BITRATE : integer := 19200;
	constant encrypt_command : string := "-e ";
	constant decrypt_command : string := "-d ";
	--constant plaintext : string := "Attack at dawn";
	constant plaintext : string := "ATTACK AT DAWN";
	constant plaintext_input : string := encrypt_command & plaintext;


	--constant rc4_test_input : string := "OK";
	type ascii_array is array (0 to 27) of std_logic_vector (7 downto 0);

	-- constant rc4_cipher : ascii_array := (x"35", x"bb", x"56", x"f5", x"19", x"c9", x"17", x"67", x"7b", x"09", x"e6", x"bc", x"6f", x"4c");
	constant rc4_cipher : ascii_array := 
	(
	x"33", x"35", --35
	x"42", x"42", --bb
	x"35", x"36", --56
	x"46", x"35", --f5
	x"31", x"39", --19
	x"43", x"39", --c9
	x"31", x"37", --17
	x"36", x"37", --67
	x"37", x"42", --7b
	x"30", x"39", --09
	x"45", x"36", --e6
	x"42", x"43", --bc
	x"36", x"46", --6f a3
	x"34", x"43"); --4c

	--constant autoclave_cipher : string := "Sxvrgd am wayx";
	--constant autoclave_cipher : string := "Sxvrgd am wayx";
	constant autoclave_cipher : string := "SXVRGD AM WAYX";
	constant autoclave_decrypt_input : string := decrypt_command & autoclave_cipher;


	signal tmp : std_logic_vector (7 downto 0) := (others => '0');
	signal expectedVal : std_logic_vector (7 downto 0) := (others => '0');

	signal inside : std_logic;

	signal reading : std_Logic;

begin
	modMCounter2 : entity work.ModMCounterEn(Behavioral)
	generic map( N => NBits, M => MCount)
	port map
	(
		en => '1',
		rst => '0',
		clk => clk,
		clr => '0',
		data_in => (others => '0'),
		load_en => '0',
		q => open,
		max_tick => baudrate_tick
	);

	UartRxComp2 : entity work.UartRx(Behavioral)
	port map
	(
		rx => rx,
		clk => clk,
		rst => rst,
		s_tick => baudrate_tick,
		dout => rx_data,
		rx_done_tick => rx_done_tick
	);

	UUT : Shell
	port map
	(
		clk => clk,
		rst => rst,
		RsRx => RsRx,
		RsTx => rx,
		cipher_select_signal => cipher_select_signal,
		led_signal => led_signal
	);


	process
	begin
		clk <= '0';
		wait for clk_period/2;
		clk <= '1';
		wait for clk_period/2;
	end process;

	process
	begin
		rst <= '1';
		RsRx <= '1';
		wait for clk_period*4;
		rst <= '0';
		wait for clk_period*20;
		--wait for 375 ms;

		-- Assuming that print help is skipped. 

		-- Test for LF, CR and >
		expectedVal <= x"0a";
		readUart(expectedVal);
		report "Got LF";
		expectedVal <= x"0d";
		readUart(expectedVal);
		report "Got CR";
		expectedVal <= x"3e";
		readUart(expectedVal);
		report "Got >";


		-- Test plaintext input echo
		for i in plaintext_input'range loop 
			writeUart(std_logic_vector(to_unsigned(character'pos(plaintext_input(i)), 8)), RsRx, BITRATE);
			expectedVal <= std_logic_vector(to_unsigned(character'pos(plaintext_input(i)), 8));
			readUart(expectedVal);
			report "Plaintext input";
		end loop;

		-- Switch to Autoclave cipher and select encrypt 
		cipher_select_signal <= '0';
		-- Send CR
		writeUart(x"0d", RsRx, BITRATE);
		-- Test for LFCR after sending CR (Should have been CRLF)
		expectedVal <= x"0a";
		readUart(expectedVal);
		report "Got LF";
		expectedVal <= x"0d";
		readUart(expectedVal);
		report "Got CR";


		-- Test Autoclave Encrypt
		for i in autoclave_cipher'range loop 
			expectedVal <= std_logic_vector(to_unsigned(character'pos(autoclave_cipher(i)), 8));
			readUart(expectedVal);
			report "Autoclave Encrypt";
		end loop;

		-- Test for LF, CR and >
		expectedVal <= x"0a";
		readUart(expectedVal);
		report "Got LF";

		expectedVal <= x"0d";
		readUart(expectedVal);
		report "Got CR";

		expectedVal <= x"3e";
		readUart(expectedVal);
		report "Got >";

		 -- Test for echo
		for i in autoclave_decrypt_input'range loop 
			writeUart(std_logic_vector(to_unsigned(character'pos(autoclave_decrypt_input(i)), 8)), RsRx, BITRATE);
			expectedVal <= std_logic_vector(to_unsigned(character'pos(autoclave_decrypt_input(i)), 8));
			readUart(expectedVal);
			report "Echo autoclave decrypt";
		end loop;

		 -- Switch to decrypt and send CR
		cipher_select_signal <= '0';
		writeUart(x"0d", RsRx, BITRATE);

		-- Test for LFCR after sending CR (Should have been CRLF)
		expectedVal <= x"0a";
		readUart(expectedVal);
		report "Got LF";
		expectedVal <= x"0d";
		readUart(expectedVal);
		report "Got CR";


		 -- Test Autoclave Decrypt
		for i in autoclave_cipher'range loop 
			expectedVal <= std_logic_vector(to_unsigned(character'pos(plaintext(i)), 8));
			readUart(expectedVal);
		end loop;

		-- Test for LF, CR and >
		expectedVal <= x"0a";
		readUart(expectedVal);
		report "Got LF";

		expectedVal <= x"0d";
		readUart(expectedVal);
		report "Got CR";

		expectedVal <= x"3e";
		readUart(expectedVal);
		report "Got >";

		 -- Test for echo
		for i in plaintext_input'range loop 
			writeUart(std_logic_vector(to_unsigned(character'pos(plaintext_input(i)), 8)), RsRx, BITRATE);
			expectedVal <= std_logic_vector(to_unsigned(character'pos(plaintext_input(i)), 8));
			readUart(expectedVal);
			report "Plaintext input";
		end loop;

		 -- Switch to RC4 and send CR (We will encode)
		cipher_select_signal <= '1';
		writeUart(x"0d", RsRx, BITRATE);
		-- Test for LFCR after sending CR (Should have been CRLF)
		expectedVal <= x"0a";
		readUart(expectedVal);
		report "Got LF";
		expectedVal <= x"0d";
		readUart(expectedVal);
		report "Got CR";



		for i in 0 to rc4_cipher'length -1 loop 
			expectedVal <= rc4_cipher(i);
			-- expectedVal <= x"00";
			readUart(expectedVal);
			report "Ciphering RC4";
		end loop;

		-- Test for LF, CR and >
		expectedVal <= x"0a";
		readUart(expectedVal);
		report "Got LF";

		expectedVal <= x"0d";
		readUart(expectedVal);
		report "Got CR";

		expectedVal <= x"3e";
		readUart(expectedVal);
		report "Got >";

		-- Test for echo
		for i in decrypt_command'range loop 
			writeUart(std_logic_vector(to_unsigned(character'pos(decrypt_command(i)), 8)), RsRx, BITRATE);
			expectedVal <= std_logic_vector(to_unsigned(character'pos(decrypt_command(i)), 8));
			readUart(expectedVal);
		end loop;
		--Test 3 backspaces	
		for i in 0 to 2 loop
			writeUart( x"7F", RsRx, BITRATE);
			expectedVal <= x"08";
			readUart(expectedVal);
			expectedVal <= x"20";
			readUart(expectedVal);
			expectedVal <= x"08";
			readUart(expectedVal);
			report "Backspace0";
		end loop;
		--Test 2 more, that will do nothing
		for i in 0 to 2 loop
			writeUart( x"7F", RsRx, BITRATE);
			report "Backspace1";
		end loop;
		for i in decrypt_command'range loop 
			writeUart(std_logic_vector(to_unsigned(character'pos(decrypt_command(i)), 8)), RsRx, BITRATE);
			expectedVal <= std_logic_vector(to_unsigned(character'pos(decrypt_command(i)), 8));
			readUart(expectedVal);
			report "Load decrypt command";
		end loop;
		for i in 0 to rc4_cipher'length - 1 loop 
			writeUart(rc4_cipher(i), RsRx, BITRATE);
			expectedVal <= rc4_cipher(i);
			readUart(expectedVal);
			report "Load RC4 ciphertext";
		end loop;

		 -- Switch to decrypt and send CR
		cipher_select_signal <= '1';
		writeUart(x"0d", RsRx, BITRATE);

		-- Test for LFCR after sending CR (Should have been CRLF)
		expectedVal <= x"0a";
		readUart(expectedVal);
		report "Got LF";
		expectedVal <= x"0d";
		readUart(expectedVal);
		report "Got CR";

		 --Test RC4 Decrypt:
		for i in plaintext'range loop 
			-- expectedVal <= std_logic_vector(to_unsigned(character'pos(plaintext(i)), 8));
			expectedVal <= x"00";
			readUart(expectedVal);
			report "RC4 Decrypt";
		end loop;

		-- Test for LF, CR and >
		expectedVal <= x"0a";
		readUart(expectedVal);
		report "Got LF";

		expectedVal <= x"0d";
		readUart(expectedVal);
		report "Got CR";

		expectedVal <= x"3e";
		readUart(expectedVal);
		report "Got >";

		report "Test: OK";
		finish;

	end process;
end Behavioral;

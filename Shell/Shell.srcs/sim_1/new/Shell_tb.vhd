
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use ieee.math_real.all;
use std.env.finish;
use IEEE.std_logic_textio.all;

entity Shell_tb is end Shell_tb;

architecture Behavioral of Shell_tb is
	constant BAUDRATE : integer := 19200;
	constant MCount : integer := integer(100000000/(BAUDRATE*16));
	constant NBits : integer := integer(ceil(log2(real(MCount))));


	signal expectedVal : std_logic_vector (7 downto 0) := (others => '0');
	--Uart receiver for Test bench
	signal baudrate_tick, rx, rx_done_tick : std_logic;
	signal rx_data : std_logic_vector(7 downto 0);

	signal clk_period : time := 10 ns;
	signal clk : STD_LOGIC;
	signal rst : STD_LOGIC;
	signal RsRx : STD_LOGIC;
	signal RsTx : STD_LOGIC;
	signal seg : STD_LOGIC_VECTOR (7 downto 0);
	signal an : STD_LOGIC_VECTOR (3 downto 0);
	--signal cipher_select_signal : STD_LOGIC;
	signal led_signal : STD_LOGIC;


	procedure writeUart 
	( 
		constant c: in std_logic_vector(7 downto 0); 
		signal rx : out std_logic;
		constant bitrate : in integer := 19200 
	) is
		constant wait_time : time := integer(real(real(1)/real(bitrate))*1000000) *1 us;
	begin
		rx <= '0';
		wait for wait_time; -- Start bit
		for i in 0 to c'length-1 loop
			rx <= c(i);
			wait for wait_time;
		end loop;
		rx <= '1';
		wait for wait_time; -- Stop bit
	end procedure writeUart;

	procedure validateReceivedByte ( signal expectedVal : inout STD_LOGIC_VECTOR (7 downto 0)) is
	begin
		wait until rising_edge(clk) and rx_done_tick = '1';
		-- if expectedVal /= x"00" then
		assert rx_data = expectedVal
		severity failure;
		-- end if;
	end procedure validateReceivedByte;

	procedure validateNewline (signal expectedVal : inout STD_LOGIC_VECTOR (7 downto 0)) is
	begin
		-- Test for LFCR after sending CR (Should have been CRLF)
		expectedVal <= x"0a";
		validateReceivedByte(expectedVal);
		report "Got LF";
		expectedVal <= x"0d";
		validateReceivedByte(expectedVal);
		report "Got CR";
	end procedure;

	procedure validatePrompt (signal expectedVal : inout STD_LOGIC_VECTOR (7 downto 0)) is
	begin
		validateNewline(expectedVal);
		expectedVal <= x"3e";
		validateReceivedByte(expectedVal);
		report "Got >";
	end procedure;

	constant encrypt_command : string := "-e ";
	constant decrypt_command : string := "-d ";
	constant rc4_select_command : string := "-c r ";
	constant autoclave_select_command : string := "-c a ";
	constant plaintext : string := "ATTACK AT DAWN";
	constant plaintext_input : string := encrypt_command & plaintext;

	type ascii_array is array (0 to 27) of std_logic_vector (7 downto 0);

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
	x"36", x"46", --6f
	x"34", x"43"); --4c

	constant autoclave_cipher : string := "SXVRGD AM WAYX";
	constant autoclave_decrypt_input : string := decrypt_command & autoclave_cipher;


begin
	UUT : entity work.Shell(Behavioral)
	port map
	(
		clk => clk,
		rst => rst,
		RsRx => RsRx,
		RsTx => RsTx,
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
		------------------------------------------------------------------------------
		-- TEST INIT
		------------------------------------------------------------------------------
		--wait for 375 ms;
		-- Assuming that print help is skipped. 
		validatePrompt(expectedVal);

		------------------------------------------------------------------------------
		-- TEST AUTOCLAVE ENCRYPT
		------------------------------------------------------------------------------
		-- Send -c a
		writeUart(x"2d", RsRx, BITRATE);
		expectedVal <= x"2d";
		readUart(expectedVal);
		report "Got -";
		
		writeUart(x"63", RsRx, BITRATE);
		expectedVal <= x"63";
		readUart(expectedVal);
		report "Got c";
		
		writeUart(x"20", RsRx, BITRATE);
		expectedVal <= x"20";
		readUart(expectedVal);
		report "Got SPACE";
		
		writeUart(x"61", RsRx, BITRATE);
		expectedVal <= x"61";
		readUart(expectedVal);
		report "Got a";
		
		writeUart(x"20", RsRx, BITRATE);
		expectedVal <= x"20";
		readUart(expectedVal);
		report "Got SPACE";

		-- Test plaintext input echo
		for i in plaintext_input'range loop 
			writeUart(std_logic_vector(to_unsigned(character'pos(plaintext_input(i)), 8)), RsRx, BAUDRATE);
			expectedVal <= std_logic_vector(to_unsigned(character'pos(plaintext_input(i)), 8));
			validateReceivedByte(expectedVal);
			report "Plaintext input";
		end loop;
		writeUart(x"0d", RsRx, BAUDRATE);
		validateNewline(expectedVal);

		-- Test Autoclave Encrypt
		for i in autoclave_cipher'range loop 
			expectedVal <= std_logic_vector(to_unsigned(character'pos(autoclave_cipher(i)), 8));
			validateReceivedByte(expectedVal);
			report "Autoclave Encrypt";
		end loop;

		validatePrompt(expectedVal);

		-- Send -c a
		writeUart(x"2d", RsRx, BITRATE);
		expectedVal <= x"2d";
		readUart(expectedVal);
		report "Got -";
		
		writeUart(x"63", RsRx, BITRATE);
		expectedVal <= x"63";
		readUart(expectedVal);
		report "Got c";
		
		writeUart(x"20", RsRx, BITRATE);
		expectedVal <= x"20";
		readUart(expectedVal);
		report "Got SPACE";
		
		writeUart(x"61", RsRx, BITRATE);
		expectedVal <= x"61";
		readUart(expectedVal);
		report "Got a";
		
		writeUart(x"20", RsRx, BITRATE);
		expectedVal <= x"20";
		readUart(expectedVal);
		report "Got SPACE";

		------------------------------------------------------------------------------
		-- TEST AUTOCLAVE DECRYPT
		------------------------------------------------------------------------------
		cipher_select_signal <= '0';
		-- Test for echo
		for i in autoclave_decrypt_input'range loop 
			writeUart(std_logic_vector(to_unsigned(character'pos(autoclave_decrypt_input(i)), 8)), RsRx, BAUDRATE);
			expectedVal <= std_logic_vector(to_unsigned(character'pos(autoclave_decrypt_input(i)), 8));
			validateReceivedByte(expectedVal);
			report "Echo autoclave decrypt";
		end loop;
		writeUart(x"0d", RsRx, BAUDRATE);
		validateNewline(expectedVal);
		-- Test Autoclave Decrypt
		for i in autoclave_cipher'range loop 
			expectedVal <= std_logic_vector(to_unsigned(character'pos(plaintext(i)), 8));
			validateReceivedByte(expectedVal);
		end loop;
		validatePrompt(expectedVal);

		
		-- Send -c r
		writeUart(x"2d", RsRx, BITRATE);
		expectedVal <= x"2d";
		readUart(expectedVal);
		report "Got -";
		
		writeUart(x"63", RsRx, BITRATE);
		expectedVal <= x"63";
		readUart(expectedVal);
		report "Got c";
		
		writeUart(x"20", RsRx, BITRATE);
		expectedVal <= x"20";
		readUart(expectedVal);
		report "Got SPACE";
		
		writeUart(x"72", RsRx, BITRATE);
		expectedVal <= x"72";
		readUart(expectedVal);
		report "Got r";
		
		writeUart(x"20", RsRx, BITRATE);
		expectedVal <= x"20";
		readUart(expectedVal);
		report "Got SPACE";

		------------------------------------------------------------------------------
		-- TEST RC4 ENCRYPT
		------------------------------------------------------------------------------
		-- Test for echo
		for i in plaintext_input'range loop 
			writeUart(std_logic_vector(to_unsigned(character'pos(plaintext_input(i)), 8)), RsRx, BAUDRATE);
			expectedVal <= std_logic_vector(to_unsigned(character'pos(plaintext_input(i)), 8));
			validateReceivedByte(expectedVal);
			report "Plaintext input";
		end loop;
		writeUart(x"0d", RsRx, BAUDRATE);
		validateNewline(expectedVal);
		for i in 0 to rc4_cipher'length -1 loop 
			expectedVal <= rc4_cipher(i);
			-- expectedVal <= x"00";
			validateReceivedByte(expectedVal);
			report "Ciphering RC4";
		end loop;
		validatePrompt(expectedVal);


		------------------------------------------------------------------------------
		-- TEST RC4 DECRYPT and BACKSPACE
		------------------------------------------------------------------------------
		-- Test for echo
		for i in decrypt_command'range loop 
			writeUart(std_logic_vector(to_unsigned(character'pos(decrypt_command(i)), 8)), RsRx, BAUDRATE);
			expectedVal <= std_logic_vector(to_unsigned(character'pos(decrypt_command(i)), 8));
			validateReceivedByte(expectedVal);
		end loop;
		--Test 3 backspaces	
		for i in 0 to 2 loop
			writeUart( x"7F", RsRx, BAUDRATE);
			expectedVal <= x"08";
			validateReceivedByte(expectedVal);
			expectedVal <= x"20";
			validateReceivedByte(expectedVal);
			expectedVal <= x"08";
			validateReceivedByte(expectedVal);
			report "Backspace0";
		end loop;
		--Test 2 more, that will do nothing
		for i in 0 to 2 loop
			writeUart( x"7F", RsRx, BAUDRATE);
			report "Backspace1";
		end loop;
		for i in decrypt_command'range loop 
			writeUart(std_logic_vector(to_unsigned(character'pos(decrypt_command(i)), 8)), RsRx, BAUDRATE);
			expectedVal <= std_logic_vector(to_unsigned(character'pos(decrypt_command(i)), 8));
			validateReceivedByte(expectedVal);
			report "Load decrypt command";
		end loop;
		for i in 0 to rc4_cipher'length - 1 loop 
			writeUart(rc4_cipher(i), RsRx, BAUDRATE);
			expectedVal <= rc4_cipher(i);
			validateReceivedByte(expectedVal);
			report "Load RC4 ciphertext";
		end loop;

		writeUart(x"0d", RsRx, BAUDRATE);
		validateNewline(expectedVal);

		--Test RC4 Decrypt:
		for i in plaintext'range loop 
			expectedVal <= std_logic_vector(to_unsigned(character'pos(plaintext(i)), 8));
			-- expectedVal <= x"00";
			validateReceivedByte(expectedVal);
			report "RC4 Decrypt";
		end loop;

		validatePrompt(expectedVal);

		------------------------------------------------------------------------------
		-- TEST FINISHED
		------------------------------------------------------------------------------
		report "Test: OK";
		finish;

	end process;

	modMCounter2 : entity work.ModMCounterEn(Behavioral)
	generic map
	( 
		N => integer(100000000/(BAUDRATE*16)),
		M => MCount
	)
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
		rx => RsTx,
		clk => clk,
		rst => rst,
		s_tick => baudrate_tick,
		dout => rx_data,
		rx_done_tick => rx_done_tick
	);

end Behavioral;

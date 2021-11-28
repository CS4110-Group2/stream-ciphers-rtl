
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use ieee.math_real.all;
use std.env.finish;

entity Shell_tb is
--  Port ( );
end Shell_tb;

architecture Behavioral of Shell_tb is

	signal clk_period : time := 10 ns;
	signal clk : STD_LOGIC;
	signal rst : STD_LOGIC;
	signal RsRx : STD_LOGIC;
	signal RsTx : STD_LOGIC;
	signal seg : STD_LOGIC_VECTOR (7 downto 0);
	signal an : STD_LOGIC_VECTOR (3 downto 0);
	signal cipher_select_signal : STD_LOGIC;
	signal encrypt_decrypt_signal : STD_LOGIC;
	signal led_signal : STD_LOGIC;

	Component Shell is
		Port ( clk : in STD_LOGIC;
			   rst : in STD_LOGIC;
			   RsRx : in STD_LOGIC;
			   RsTx : out STD_LOGIC;
			   cipher_select_signal : in STD_LOGIC;
			   encrypt_decrypt_signal : in STD_LOGIC;
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
	   signal result : out STD_LOGIC_VECTOR (7 downto 0);
	   --signal tx : in STD_LOGIC;
	   constant bitrate : in integer := 19200
	)
	is
		constant wait_time : time := integer(real(real(1)/real(bitrate))*1000000) *1 us;
	begin
		wait until RsTx = '0' for 10*clk_period;
		
		wait for wait_time; -- Start bit

		for i in 0 to result'length-1 loop
			result(i) <= RsTx;
			wait for wait_time;
		end loop;
		wait for wait_time; -- Stop bit
	end procedure readUart;

	constant BITRATE : integer := 19200;
    
    --constant input : string := "Attack at dawn";
    constant input : string := "ATTACK AT DAWN";
    
    --constant rc4_test_input : string := "OK";
    type ascii_array is array (0 to 1) of std_logic_vector (7 downto 0);
    
    constant rc4_cipher : ascii_array := (x"1b", x"84");
    --constant autoclave_cipher : string := "Sxvrgd am wayx";
    constant autoclave_cipher : string := "SXVRGD AM WAYX";

	signal tmp : std_logic_vector (7 downto 0) := (others => '0');
	
	signal reading : std_Logic;

begin

	UUT : Shell
	port map
	(
		clk => clk,
		rst => rst,
		RsRx => RsRx,
		RsTx => RsTx,
		cipher_select_signal => cipher_select_signal,
		encrypt_decrypt_signal => encrypt_decrypt_signal,
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
		wait for clk_period*4;
		--wait for 375 ms;
		
		-- Assuming that print help is skipped. 

        -- Test for LF, CR and >
        readUart(tmp, BITRATE);
        assert tmp = x"0a"
            severity failure;
        
        readUart(tmp, BITRATE);
        assert tmp = x"0d"
            severity failure;
            
        readUart(tmp, BITRATE);
        assert tmp = x"3e"
            severity failure;
            
        -- Test for echo
        for i in input'range loop 
            writeUart(std_logic_vector(to_unsigned(character'pos(input(i)), 8)), RsRx, BITRATE);
            readUart(tmp, BITRATE);
            assert tmp = std_logic_vector(to_unsigned(character'pos(input(i)), 8))
                severity failure;
		end loop;
		
        -- Switch to Autoclave cipher and select encrypt 
        -- Send CR
		cipher_select_signal <= '0';
		encrypt_decrypt_signal <= '1';
		writeUart(x"0d", RsRx, BITRATE);

		-- Test for LFCR after sending CR (Should have been CRLF)
		readUart(tmp, BITRATE);
		assert tmp = x"0a"
		    severity failure;
		    
		readUart(tmp, BITRATE);
		assert tmp = x"0d"
		    severity failure;

		-- Test Autoclave Encrypt
		for i in input'range loop 
            readUart(tmp, BITRATE);
            assert tmp = std_logic_vector(to_unsigned(character'pos(autoclave_cipher(i)), 8))
                severity failure;
		end loop;
		
		-- Test for LF, CR and >
        readUart(tmp, BITRATE);
        assert tmp = x"0a"
            severity failure;
        
        readUart(tmp, BITRATE);
        assert tmp = x"0d"
            severity failure;
            
        readUart(tmp, BITRATE);
        assert tmp = x"3e"
            severity failure;
		
        -- Test for echo
        for i in input'range loop 
            writeUart(std_logic_vector(to_unsigned(character'pos(autoclave_cipher(i)), 8)), RsRx, BITRATE);
            readUart(tmp, BITRATE);
            assert tmp = std_logic_vector(to_unsigned(character'pos(autoclave_cipher(i)), 8))
                severity failure;
		end loop;
		
        -- Switch to decrypt and send CR
		cipher_select_signal <= '0';
		encrypt_decrypt_signal <= '0';
		writeUart(x"0d", RsRx, BITRATE);

		-- Test for LFCR after sending CR (Should have been CRLF)
		readUart(tmp, BITRATE);
		assert tmp = x"0a"
		    severity failure;
		    
		readUart(tmp, BITRATE);
		assert tmp = x"0d"
		    severity failure;
		
		-- Test Autoclave Decrypt
		for i in input'range loop 
            readUart(tmp, BITRATE);
            assert tmp = std_logic_vector(to_unsigned(character'pos(input(i)), 8))
                severity failure;
		end loop;
		
		-- Test for LF, CR and >
        readUart(tmp, BITRATE);
        assert tmp = x"0a"
            severity failure;
        
        readUart(tmp, BITRATE);
        assert tmp = x"0d"
            severity failure;
            
        readUart(tmp, BITRATE);
        assert tmp = x"3e"
            severity failure;
		
		-- Test for echo
        for i in input'range loop 
            writeUart(std_logic_vector(to_unsigned(character'pos(input(i)), 8)), RsRx, BITRATE);
            readUart(tmp, BITRATE);
            assert tmp = std_logic_vector(to_unsigned(character'pos(input(i)), 8))
                severity failure;
		end loop;
		
        -- Switch to RC4 and send CR
		cipher_select_signal <= '1';
		--encrypt_decrypt_signal <= '0';
		writeUart(x"0d", RsRx, BITRATE);

		-- Test for LFCR after sending CR (Should have been CRLF)
		readUart(tmp, BITRATE);
		assert tmp = x"0a"
		    severity failure;
		    
		readUart(tmp, BITRATE);
		assert tmp = x"0d"
		    severity failure;
		
		report "Test: OK";
	    finish;

--		writeUart( x"7F", RsRx, BITRATE);
--		writeUart( x"7F", RsRx, BITRATE);
--		writeUart( x"7F", RsRx, BITRATE);

--		writeUart( x"2d", RsRx, BITRATE);
--		writeUart( x"68", RsRx, BITRATE);
--		writeUart( x"0d", RsRx, BITRATE);


--        for i in input'range loop 
--            writeUart(std_logic_vector(to_unsigned(character'pos(input(i)), 8)), RsRx, BITRATE);
--		end loop;
--		writeUart( x"7F", RsRx, BITRATE);
--		writeUart( x"7F", RsRx, BITRATE);
--		writeUart( x"7F", RsRx, BITRATE);
--		writeUart( x"62", RsRx, BITRATE);
--		writeUart( x"0d", RsRx, BITRATE);
--		wait;
	end process;



end Behavioral;

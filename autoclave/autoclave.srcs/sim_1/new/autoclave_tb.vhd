----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity autoclave_tb is
    -- Port ();
end autoclave_tb;

architecture arch of autoclave_tb is
    constant clk_period : time := 10 ns;
    constant bit_period : time := 52083ns; -- time for 1 bit.. 1bit/19200bps = 52.08 us

    constant rx_data_ascii_space: std_logic_vector(7 downto 0) := x"20"; -- receive "space"
    constant rx_data_ascii_enter: std_logic_vector(7 downto 0) := x"0D"; -- receive "enter"
    constant rx_data_ascii_C: std_logic_vector(7 downto 0) := x"43"; -- receive C
    constant rx_data_ascii_D: std_logic_vector(7 downto 0) := x"44"; -- receive D
    constant rx_data_ascii_E: std_logic_vector(7 downto 0) := x"45"; -- receive E
    constant rx_data_ascii_H: std_logic_vector(7 downto 0) := x"48"; -- receive H
    constant rx_data_ascii_I: std_logic_vector(7 downto 0) := x"49"; -- receive I
    constant rx_data_ascii_L: std_logic_vector(7 downto 0) := x"4C"; -- receive L
    constant rx_data_ascii_N: std_logic_vector(7 downto 0) := x"4E"; -- receive N
    constant rx_data_ascii_O: std_logic_vector(7 downto 0) := x"4F"; -- receive O
    constant rx_data_ascii_P: std_logic_vector(7 downto 0) := x"50"; -- receive P
    constant rx_data_ascii_R: std_logic_vector(7 downto 0) := x"52"; -- receive R
    constant rx_data_ascii_S: std_logic_vector(7 downto 0) := x"53"; -- receive S
    constant rx_data_ascii_V: std_logic_vector(7 downto 0) := x"56"; -- receive V
    constant rx_data_ascii_W: std_logic_vector(7 downto 0) := x"57"; -- receive W
    constant rx_data_ascii_Z: std_logic_vector(7 downto 0) := x"5A"; -- receive Z
    
    Component autoclave
        Port ( reset, clk: in std_logic;
             rx:         in std_logic;
             tx:         out std_logic;
             switchEncrypt: in std_logic;
             ledEncrypt: out std_logic );
    end Component;

    signal clk, reset: std_logic;
    signal srx, stx, switchEncrypt: std_logic;

begin
    uut: autoclave
        Port Map(clk => clk, reset => reset,
                 rx => srx, tx => stx,
                 switchEncrypt=>switchEncrypt );

    clk_process: process
    begin
        clk <= '0';
        wait for clk_period/2;
        clk <= '1';
        wait for clk_period/2;
    end process;

    stim: process
    procedure SendMessage( msg : std_logic_vector( 7 downto 0 ) ) is
    begin
        srx <= '0'; -- start bit = 0
        wait for bit_period;
        for i in 0 to 7 loop
            srx <= msg(i);   -- 8 data bits
            wait for bit_period;
        end loop;
        srx <= '1'; -- stop bit = 1
        wait for 1ms;
    end procedure;
    
    begin
        -- Test encryption
        switchEncrypt <='1';
        reset <= '1';
        wait for clk_period*2;
        reset <= '0';
        wait for clk_period*2;
        
        SendMessage( rx_data_ascii_H );
        SendMessage( rx_data_ascii_E );
        SendMessage( rx_data_ascii_L );
        SendMessage( rx_data_ascii_L );
        SendMessage( rx_data_ascii_O );
        SendMessage( rx_data_ascii_space );
        SendMessage( rx_data_ascii_W );
        SendMessage( rx_data_ascii_O );
        SendMessage( rx_data_ascii_R );
        SendMessage( rx_data_ascii_L );
        SendMessage( rx_data_ascii_D );
        SendMessage( rx_data_ascii_enter );
        
        -- Test decryption
        switchEncrypt <='0';
        reset <= '1';
        wait for clk_period*2;
        reset <= '0';
        wait for clk_period*2;
        
        SendMessage( rx_data_ascii_Z );
        SendMessage( rx_data_ascii_I );
        SendMessage( rx_data_ascii_N );
        SendMessage( rx_data_ascii_C );
        SendMessage( rx_data_ascii_S );
        SendMessage( rx_data_ascii_space );
        SendMessage( rx_data_ascii_P );
        SendMessage( rx_data_ascii_V );
        SendMessage( rx_data_ascii_V );
        SendMessage( rx_data_ascii_W );
        SendMessage( rx_data_ascii_O );
        SendMessage( rx_data_ascii_enter );
        wait;

    end process;

end arch;

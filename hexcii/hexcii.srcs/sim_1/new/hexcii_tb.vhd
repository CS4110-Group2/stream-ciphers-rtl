
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


entity hexcii_tb is
--  Port ( );
end hexcii_tb;

architecture Behavioral of hexcii_tb is
    constant clk_period : time := 10 ns;

    Component hexcii
        Port (
             byte_in: in unsigned(7 downto 0);
             byte_out: out unsigned(7 downto 0);
             MSBits: in std_logic;
             encode: in std_logic;
             rc4: in std_logic);
    end Component;
    
             signal byte_in: unsigned(7 downto 0);
             signal byte_out: unsigned(7 downto 0);
             signal MSBits: std_logic;
             signal encode: std_logic;
             signal rc4: std_logic;

begin
    uut: hexcii
        Port Map(byte_in => byte_in, byte_out => byte_out,
                 MSBits => MSBits, encode => encode,
                 rc4 => rc4);
    stim: process
                 
    begin
        rc4 <= '1';
        
        -- Test encode
        MSBits <= '1';
        encode <= '1';
        wait for clk_period;
        byte_in <= x"41"; -- A
        wait for clk_period;
        assert byte_out = x"34" -- 4
            report "Failed enc 1"
            severity failure;
            
        wait for clk_period;
        MSBits <= '0';
        wait for clk_period;
        assert byte_out = x"31" -- 1
            report "Failed enc 2"
            severity failure;
        wait for clk_period;
        
        -- Test decode
        MSBits <= '1';
        encode <= '0';       
        wait for clk_period;
        byte_in <= x"34"; -- 4
        wait for clk_period;
        MSBits <= '0';
        wait for clk_period;
        byte_in <= x"31"; -- 1
        wait for clk_period;
        assert byte_out = x"41" -- A
            report "Failed dec 1"
            severity failure;
        
        wait;
    end process;

end Behavioral;

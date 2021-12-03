library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use ieee.math_real.all;
use std.env.finish;
use IEEE.std_logic_textio.all;

entity autoclave_tb is
end autoclave_tb;

architecture Behavioral of autoclave_tb is

    constant clk_period : time := 10 ns;
    constant bitrate    : integer := 19200;
    constant plaintext  : string := "Attack at Dawn";
    constant ciphertext : string := "Sxvrgd am Wayx";

    signal clk_tb, rst_tb            : std_logic;
    signal start_tb, clear_tb        : std_logic;
    signal encrypt_decrypt_signal_tb : std_logic;
    signal data_in_tb, data_out_tb   : std_logic_vector(7 downto 0);

    procedure write_byte
    (
        constant byte      : in  std_logic_vector (7 downto 0);
        signal ascii_in_tb : out std_logic_vector (7 downto 0);
        signal start_tb    : out std_logic
    )
    is
    begin
        ascii_in_tb <= byte;
        wait for clk_period;
        start_tb <= '1';
        wait for clk_period;
        start_tb <= '0';
    end procedure write_byte;

begin

    UUT: entity work.autoclave_top_level(Behavioral)
    Port Map(
        clk                    => clk_tb,
        rst                    => rst_tb,
        start                  => start_tb,
        clear                  => clear_tb,
        data_in                => data_in_tb,
        data_out               => data_out_tb,
        encrypt_decrypt_signal => encrypt_decrypt_signal_tb
     );

    process
    begin
        clk_tb <= '0';
        wait for clk_period/2;
        clk_tb <= '1';
        wait for clk_period/2;
    end process;

    process
    begin
        -- Test encryption
        rst_tb <= '1';
        wait for clk_period*2;
        rst_tb <= '0';
        wait for clk_period*2;
        encrypt_decrypt_signal_tb <='1';

        for i in plaintext'range loop
            write_byte(std_logic_vector(to_unsigned(character'pos(plaintext(i)), 8)), data_in_tb, start_tb);
            assert data_out_tb = std_logic_vector(to_unsigned(character'pos(ciphertext(i)), 8))
                severity failure;
        end loop;

        -- Test decryption
        encrypt_decrypt_signal_tb <='0';
        wait for clk_period*2;
        clear_tb <= '1';
        wait for clk_period*2;
        clear_tb <= '0';

        for i in ciphertext'range loop
            write_byte(std_logic_vector(to_unsigned(character'pos(ciphertext(i)), 8)), data_in_tb, start_tb);
            assert data_out_tb = std_logic_vector(to_unsigned(character'pos(plaintext(i)), 8))
                severity failure;
        end loop;

        report "Test: OK";
        finish;
    end process;

end Behavioral;


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


entity Shell is
    Port ( clk                    : in  STD_LOGIC;
           rst                    : in  STD_LOGIC;
           RsRx                   : in  STD_LOGIC;
           RsTx                   : out STD_LOGIC;
           cipher_select_signal   : in  STD_LOGIC;
           encrypt_decrypt_signal : in  STD_LOGIC;
           led_signal             : out STD_LOGIC;
           seg                    : out STD_LOGIC_VECTOR (7 downto 0);
           an                     : out STD_LOGIC_VECTOR (3 downto 0));
end Shell;

architecture Behavioral of Shell is

    --Uart stuff
    signal rx_done_tick, wr_uart, tx_full, tx_empty : std_logic;
    signal ascii_in, ascii_out : std_logic_vector(7 downto 0);
    --RAM stuff
    signal ram_write : std_logic;
    signal ram_clr : std_logic;
    signal ram_addr : std_logic_vector(7 downto 0);
    signal ram_data_in : std_logic_vector(7 downto 0);
    signal ram_data_out : std_logic_vector(7 downto 0);
    --addr counter for ram
    signal addr_cnt_clear, addr_cnt_en, addr_cnt_up_down, addr_cnt_zero : std_logic;
    signal addr_cnt_out : std_logic_vector(7 downto 0);

    signal opcode_reg_in, opcode_reg_out : std_logic_vector(7 downto 0);
    signal opcode_reg_load, opcode_reg_clear : std_logic;

    signal output_reg_mux : std_logic_vector(2 downto 0);

    signal custom_out : std_logic_vector(7 downto 0);

    signal menu_rom_data_out : std_logic_vector(7 downto 0);
    signal menu_rom_addr : std_logic_vector(7 downto 0);
    signal menu_rom_addr_load_val : STD_LOGIC_VECTOR(7 downto 0);  
    signal menu_rom_addr_load_en : STD_LOGIC;
    signal menu_rom_addr_inc : STD_LOGIC;
    signal menu_rom_inc_char_cnt : STD_LOGIC; 
    signal menu_rom_clear_char_cnt : STD_LOGIC;
    signal menu_rom_line_done : STD_LOGIC; 

    -- RC4 Cipher
    signal rc4_data_in, rc4_data_out                 : std_logic_vector (7 downto 0);
    signal rc4_clear, rc4_ready, rc4_done, rc4_start : std_logic;
    signal rc4_input_mux : std_logic;

    -- AutoClave Cipher
    signal autoclave_data_in, autoclave_data_out : std_logic_vector (7 downto 0);
    signal autoclave_start, autoclave_clear      : std_logic;
    signal autoclave_encryption_led              : std_logic;

    --hex to ascii/ascii to hex
    signal hex_to_ascii_in : std_logic_vector(7 downto 0);
    signal hex_to_ascii_out : std_logic_vector(7 downto 0);
    signal hex_to_ascii_load : std_logic;
    signal ascii_to_hex_in : std_logic_vector(7 downto 0);
    signal ascii_to_hex_out : std_logic_vector(7 downto 0);
    signal ascii_to_hex_lsb_msb : std_logic;

    
begin
    hex_to_ascii_in <= ram_data_out;
    ascii_to_hex_in <= rc4_data_out;

    ram_data_in <= ascii_in;

    ram_addr <= addr_cnt_out;

    opcode_reg_in <= ram_data_out;

    rc4_data_in       <= ram_data_out when rc4_input_mux = '0' else
                         hex_to_ascii_out;

    autoclave_data_in <= ram_data_out;

    ascii_out <= ascii_in          when output_reg_mux = "000" else
                 rc4_data_out      when output_reg_mux = "001" else
                 ascii_to_hex_out      when output_reg_mux = "010" else
                 custom_out        when output_reg_mux = "011" else
                 menu_rom_data_out when output_reg_mux = "100" else
                 autoclave_data_out;



    control : entity work.ControlPath(Behavioral)
    port map
    (
        clk => clk,
        rst => rst,
        rx_done_tick => rx_done_tick,
        wr_uart => wr_uart,
        tx_full => tx_full,
        tx_empty => tx_empty,
        ram_write => ram_write,
        ram_clr => ram_clr,
        ram_data_out => ram_data_out,
        addr_cnt_clear => addr_cnt_clear,
        addr_cnt_en => addr_cnt_en,
        addr_cnt_up_down => addr_cnt_up_down,
        addr_cnt_zero => addr_cnt_zero,
        opcode_reg_load => opcode_reg_load,
        opcode_reg_clear => opcode_reg_clear,
        hex_to_ascii_load => hex_to_ascii_load,
        ascii_to_hex_lsb_msb => ascii_to_hex_lsb_msb,
        output_reg_mux => output_reg_mux,
        ascii_in => ascii_in,
        custom_out => custom_out,
        menu_rom_addr_load_val => menu_rom_addr_load_val,
        menu_rom_addr_load_en => menu_rom_addr_load_en,
        menu_rom_addr => menu_rom_addr,
        menu_rom_addr_inc       => menu_rom_addr_inc,
        menu_rom_inc_char_cnt   => menu_rom_inc_char_cnt,
        menu_rom_clear_char_cnt => menu_rom_clear_char_cnt,
        menu_rom_line_done      => menu_rom_line_done,
        rc4_start               => rc4_start,
        rc4_done                => rc4_done,
        rc4_clear               => rc4_clear,
        rc4_ready               => rc4_ready,
        rc4_input_mux           => rc4_input_mux,
        autoclave_start         => autoclave_start,
        autoclave_clear         => autoclave_clear,
        cipher_select_signal    => cipher_select_signal,
        encrypt_decrypt => encrypt_decrypt_signal
    );


    menuRom : entity work.StringRom(Behavioral)
    Generic Map
    (
        AddrSize => 8,
        DataSize => 50
    )
    Port Map
    (
        clk => clk,
        addr => menu_rom_addr,
        dataOut => menu_rom_data_out,
        inc_char_cnt => menu_rom_inc_char_cnt,
        clear_char_cnt => menu_rom_clear_char_cnt,
        line_done => menu_rom_line_done
    );


    menu_rom_addr_counter : entity work.ModMCounterEn(Behavioral)
    generic map
    ( 
        N => 8, 
        M => (2**8-1)
    )
    port map
    (
        en => menu_rom_addr_inc,
        rst => rst,
        clk => clk,
        clr => '0',
        data_in => menu_rom_addr_load_val,
        load_en => menu_rom_addr_load_en,
        q => menu_rom_addr,
        max_tick => open
    );
    

    uartComp : entity work.Uart(Behavioral)
    Port Map
    ( 
        clk => clk,
        rst => rst,
        rx => RsRx,
        rx_data => ascii_in,
        rx_done_tick => rx_done_tick,
        tx => RsTx,
        tx_data => ascii_out,
        tx_full => tx_full,
        tx_empty => tx_empty,
        wr_uart => wr_uart
    );


    writeMemory : entity work.Ram(Behavioral)
    Generic map
    (
        WORDSIZE => 8,
        ADDRSIZE => 8
    )
    Port map
    ( 
        clk => clk,
        wr => ram_write,
        clr => ram_clr,
        data_in => ram_data_in,
        addr => ram_addr,
        data_out => ram_data_out
    );


    addr_counter : entity work.ModMCounterUpDown(Behavioral)
    Generic map
    ( 
        N => 8,
        M => 2**8
    )
    Port Map
    ( 
        clk => clk,
        en => addr_cnt_en,
        up_down => addr_cnt_up_down,
        clr => addr_cnt_clear,
        zero => addr_cnt_zero,
        q => addr_cnt_out
    );

    opcode_reg : entity work.Reg(Behavioral)
    generic map
    (
        SIZE => 8
    )
    port map
    (
        clk => clk,
        rst => rst,
        load => opcode_reg_load,
        clear => opcode_reg_clear,
        data_in => opcode_reg_in,
        data_out => opcode_reg_out
    );


    hex_to_ascii : entity work.HexToAscii(Behavioral)
    Port map
    (
        clk => clk,
        rst => rst,
        load => hex_to_ascii_load,
        data_in => hex_to_ascii_in,
        ascii => hex_to_ascii_out
    );

    ascii_to_hex : entity work.AsciiToHex(Behavioral)
    Port map
    (
        ascii => ascii_to_hex_in,
        hex => ascii_to_hex_out,
        lsb_msb => ascii_to_hex_lsb_msb
    );

    display: entity work.SixteenBitDisplay(Behavioral)
    Port map
    ( 
        sw(15 downto 8) => ascii_in,
        sw(7 downto 0) => ascii_out,
        clk => clk,
        rst => rst,
        seg => seg,
        an => an
    );

    rc4: entity work.rc4_top_level(Behavioral)
    port map
    (
        clk      => clk,
        rst      => rst,
        data_in  => rc4_data_in,
        data_out => rc4_data_out,
        start    => rc4_start,
        ready    => rc4_ready,
        done     => rc4_done,
        clear    => rc4_clear
    );

    autoclave: entity work.autoclave_top_level(str_arch)
    port map
    (
        clk => clk,
        reset => rst,
        start => autoclave_start,
        clr   => autoclave_clear,
        ascii_in => autoclave_data_in,
        ascii_out => autoclave_data_out,
        switchEncrypt => encrypt_decrypt_signal,
        ledEncrypt    => led_signal
    );

end Behavioral;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.Shell_Constants.all;

entity ControlPath is
    Port ( clk                     : in  STD_LOGIC;
           rst                     : in  STD_LOGIC;
           rx_done_tick            : in  STD_LOGIC;
           wr_uart                 : out STD_LOGIC;
           tx_full                 : in  STD_LOGIC;
           ram_write               : out STD_LOGIC;
           ram_clr                 : out STD_LOGIC;
           ram_data_out            : in  STD_LOGIC_VECTOR (7 downto 0);
           addr_cnt_clear          : out STD_LOGIC;
           addr_cnt_en             : out STD_LOGIC;
           addr_cnt_up_down        : out STD_LOGIC;
           addr_cnt_zero           : in  STD_LOGIC; 
           rc4_ready               : in  STD_LOGIC;
           rc4_done                : in  STD_LOGIC;
           rc4_start               : out STD_LOGIC;
           rc4_clear               : out STD_LOGIC;
           rc4_input_mux           : out STD_LOGIC;
           autoclave_clear         : out STD_LOGIC;
           autoclave_start         : out STD_LOGIC;
           opcode_reg_load         : out STD_LOGIC;
           opcode_reg_clear        : out STD_LOGIC;
           hex_to_ascii_load       : out STD_LOGIC;
           ascii_to_hex_lsb_msb    : out STD_LOGIC;  
           output_reg_mux          : out STD_LOGIC_VECTOR (2 downto 0);
           ascii_in                : in  STD_LOGIC_VECTOR (7 downto 0);
           menu_rom_addr_load_val  : out STD_LOGIC_VECTOR (7 downto 0);  
           menu_rom_addr_load_en   : out STD_LOGIC;
           menu_rom_addr           : in  STD_LOGIC_VECTOR (7 downto 0);
           menu_rom_addr_inc       : out STD_LOGIC;
           menu_rom_inc_char_cnt   : out STD_LOGIC; 
           menu_rom_clear_char_cnt : out STD_LOGIC;
           menu_rom_line_done      : in  STD_LOGIC; 
           encrypt_decrypt         : out STD_LOGIC; 
           software_reset          : out STD_LOGIC); 
end ControlPath;

architecture Behavioral of ControlPath is

    type FSM is 
        (
            Init, 
            WaitRx, 
            PrintFromMenuRomState, 
            HandleEnter, 
            ParseCommand, 
            ParseCipher, 
            LoopState, 
            StartRc4, 
            WaitForRc4, 
            ReadRc4, 
            RamAddrIncrementState, 
            WaitState,
            STOP
        );
    signal state_reg, state_next : FSM := Init;
    signal goto_state_reg, goto_state_next           : FSM;
    signal i_cnt, i_cnt_next                                             : INTEGER := 0;
    signal current_menu_stop_address_reg, current_menu_stop_address_next : STD_LOGIC_VECTOR (7 downto 0) := (others => '0');
    signal encrypt_decrypt_reg, encrypt_decrypt_next : STD_LOGIC := '0';
    signal cipher_select_reg, cipher_select_next     : STD_LOGIC := '0';

    function ValidAscii( val : std_logic_vector(7 downto 0); only_hex : std_logic) return boolean is
    begin
        if(val = ENTER) or 
        (val = SPACE) or 
        (val = DELETE) or
        (val = DASH) or
        (val >= ASCII_START and val <= ASCII_STOP and only_hex = '0') or
        (val >= HEX_NUM_START and val <= HEX_NUM_STOP) or
        (val >= HEX_CHAR_UPPER_START and val <= HEX_CHAR_UPPER_STOP) or
        (val >= HEX_CHAR_LOWER_START and val <= HEX_CHAR_LOWER_STOP)
        then
            return true;
        else
            return false;
        end if;
    end function;

begin
    process(clk, rst)
    begin
        if rst = '1' then
            current_menu_stop_address_reg <= (others => '0');
            state_reg                     <= Init;
            i_cnt                         <= 0;
            cipher_select_reg             <= '0';
            encrypt_decrypt_reg           <= '0';
        elsif rising_edge(clk) then
            state_reg                     <= state_next;
            encrypt_decrypt_reg           <= encrypt_decrypt_next;
            current_menu_stop_address_reg <= current_menu_stop_address_next;
            goto_state_reg                <= goto_state_next;
            cipher_select_reg             <= cipher_select_next;
            i_cnt                         <= i_cnt_next;
        end if;
    end process;

    encrypt_decrypt <= encrypt_decrypt_reg;

    process(state_reg, rx_done_tick, tx_full, ascii_in, menu_rom_addr, menu_rom_line_done, ram_data_out, i_cnt, rc4_done, rc4_ready, encrypt_decrypt_reg, addr_cnt_zero, cipher_select_reg, goto_state_reg, current_menu_stop_address_reg)

        procedure PrintFromMenuRom 
        ( 
            constant startAddress : in std_logic_vector(7 downto 0); 
            constant stopAddress : in std_logic_vector(7 downto 0)
        ) is
        begin
            menu_rom_addr_load_val         <= startAddress;
            current_menu_stop_address_next <= stopAddress;
            menu_rom_addr_load_en          <= '1';
            menu_rom_clear_char_cnt        <= '1';
            state_next                     <= WaitState;
            goto_state_next                <= PrintFromMenuRomState;
        end procedure PrintFromMenuRom;

    begin
        state_next                     <= state_reg;
        wr_uart                        <= '0';
        ram_write                      <= '0';
        ram_clr                        <= '0';
        addr_cnt_clear                 <= '0';
        addr_cnt_en                    <= '0';
        addr_cnt_up_down               <= '0';
        rc4_start                      <= '0';
        rc4_clear                      <= '0';
        rc4_input_mux                  <= RC4_INPUT_MUX_ASCII;
        autoclave_clear                <= '0';
        autoclave_start                <= '0';
        opcode_reg_load                <= '0';
        opcode_reg_clear               <= '0';
        hex_to_ascii_load              <= '0';
        ascii_to_hex_lsb_msb           <= ASCII_TO_HEX_MSB;
        output_reg_mux                 <= OUTPUT_MUX_INPUT;
        i_cnt_next                     <= i_cnt;
        menu_rom_addr_load_val         <= (others => '0');
        menu_rom_addr_load_en          <= '0';
        menu_rom_addr_inc              <= '0';
        menu_rom_inc_char_cnt          <= '0';
        menu_rom_clear_char_cnt        <= '0';
        encrypt_decrypt_next           <= encrypt_decrypt_reg;
        cipher_select_next             <= cipher_select_reg;
        goto_state_next                <= goto_state_reg;
        current_menu_stop_address_next <= current_menu_stop_address_reg;
        software_reset <= '0';

        case state_reg is
            when Init =>
                addr_cnt_clear                 <= '1';
                PrintFromMenuRom( SPLASH_START_ADDRESS, SPLASH_STOP_ADDRESS);

            when WaitRx =>
                if rx_done_tick = '1' and tx_full = '0' then
                    if ValidAscii(ascii_in, ACCEPT_ASCII) then
                        if ascii_in = ENTER then
                            ram_write      <= '1';
                            addr_cnt_clear <= '1';
                            PrintFromMenuRom( NEWLINE_SEQUENCE_START_ADDRESS, NEWLINE_SEQUENCE_STOP_ADDRESS);
                        elsif ascii_in = DELETE then
                            if addr_cnt_zero = '0' then
                                ram_write        <= '1';
                                addr_cnt_en      <= '1';
                                ram_clr          <= '1';
                                addr_cnt_up_down <= '1';
                                PrintFromMenuRom( BACKSPACE_SEQUENCE_START_ADDRESS, BACKSPACE_SEQUENCE_STOP_ADDRESS);
                            end if;
                        else -- Echo output
                            output_reg_mux <= OUTPUT_MUX_INPUT;
                            wr_uart        <= '1';
                            ram_write      <= '1';
                            addr_cnt_en    <= '1';
                        end if;
                    end if;
                end if;

            when HandleEnter =>
                if tx_full = '0' then
                    if(ram_data_out = DASH) then
                        state_next  <= ParseCommand;
                        addr_cnt_en <= '1';
                    else
                        addr_cnt_clear                 <= '1';
                        PrintFromMenuRom( ILLEGAL_COMMAND_START_ADDRESS, ILLEGAL_COMMAND_STOP_ADDRESS);
                    end if;
                end if;

            when ParseCommand =>
                case ram_data_out is
                    when HELPCOMMAND =>
                        addr_cnt_clear                 <= '1';
                        PrintFromMenuRom( HELP_START_ADDRESS, HELP_STOP_ADDRESS);
                    when ENCRYPTCOMMAND =>
                        encrypt_decrypt_next <= ENCRYPT;
                        addr_cnt_en          <= '1';
                        state_next           <= RamAddrIncrementState;
                        goto_state_next      <= LoopState;
                    when DECRYPTCOMMAND =>
                        encrypt_decrypt_next <= DECRYPT;
                        addr_cnt_en          <= '1';
                        state_next           <= RamAddrIncrementState;
                        goto_state_next      <= LoopState;
                    when RESETCOMMAND =>
                        software_reset <= '1';
                        -- state_next <= Init;
                    when CIPHERCOMMAND =>
                        addr_cnt_en     <= '1';
                        state_next      <= RamAddrIncrementState;
                        goto_state_next <= ParseCipher;
                    when DASH =>
                        addr_cnt_en <= '1';
                        state_next  <= ParseCommand;
                    when others =>
                        addr_cnt_clear                 <= '1';
                        PrintFromMenuRom( ILLEGAL_COMMAND_START_ADDRESS, ILLEGAL_COMMAND_STOP_ADDRESS);
                end case;

            when ParseCipher =>
                addr_cnt_clear          <= '1';
                if ram_data_out = x"61" then
                    cipher_select_next             <= CIPHER_AUTOCLAVE;
                    PrintFromMenuRom( SELECTED_AUTOCLAVE_START_ADDRESS, SELECTED_AUTOCLAVE_STOP_ADDRESS);
                elsif ram_data_out = x"72" then
                    cipher_select_next             <= CIPHER_RC4;
                    PrintFromMenuRom( SELECTED_RC4_START_ADDRESS, SELECTED_RC4_STOP_ADDRESS);
                else
                    PrintFromMenuRom( ILLEGAL_CIPHER_COMMAND_START_ADDRESS, ILLEGAL_CIPHER_COMMAND_STOP_ADDRESS);
                end if;
            when LoopState =>
                if tx_full = '0' then
                    if ram_data_out = ENTER then
                        addr_cnt_clear   <= '1';
                        rc4_clear        <= '1';
                        autoclave_clear  <= '1';

                        PrintFromMenuRom( NEWLINE_SEQUENCE_START_ADDRESS, PROMPT_SEQUENCE_STOP_ADDRESS);
                    else
                        if cipher_select_reg = CIPHER_RC4 then
                            state_next <= StartRc4;
                            if encrypt_decrypt_reg = DECRYPT then
                                if ValidAscii(ram_data_out, ACCEPT_HEX) then
                                    hex_to_ascii_load <= '1';
                                    addr_cnt_en       <= '1';
                                else -- Non Hex character received
                                    rc4_clear                      <= '1';
                                    addr_cnt_clear                 <= '1';
                                    PrintFromMenuRom( ILLEGAL_CIPHER_START_ADDRESS, ILLEGAL_CIPHER_STOP_ADDRESS);
                                end if;
                            else -- ENCRYPT
                                output_reg_mux <= OUTPUT_MUX_RC4_HEX;
                                rc4_input_mux  <= RC4_INPUT_MUX_ASCII;
                            end if;
                        else -- CIPHER_AUTOCLAVE
                            autoclave_start <= '1';
                            output_reg_mux  <= OUTPUT_MUX_AUTOCLAVE;
                            wr_uart         <= '1';
                            addr_cnt_en     <= '1';
                            state_next      <= LoopState;
                        end if;
                    end if;
                end if;

            when PrintFromMenuRomState =>
                if tx_full = '0' then
                    --When reaching stop address, we proceed based on what we were printing
                    if menu_rom_addr = current_menu_stop_address_reg then
                        if current_menu_stop_address_reg = PROMPT_SEQUENCE_STOP_ADDRESS or current_menu_stop_address_reg = BACKSPACE_SEQUENCE_STOP_ADDRESS then
                            menu_rom_clear_char_cnt <= '1';
                            state_next <= WaitRx;
                        elsif current_menu_stop_address_reg = NEWLINE_SEQUENCE_STOP_ADDRESS then
                            menu_rom_clear_char_cnt <= '1';
                            state_next <= HandleEnter;
                        else
                            PrintFromMenuRom( NEWLINE_SEQUENCE_START_ADDRESS, PROMPT_SEQUENCE_STOP_ADDRESS);
                        end if;
                    else
                        output_reg_mux        <= OUTPUT_MUX_MENUROM;
                        wr_uart               <= '1';
                        menu_rom_inc_char_cnt <= '1';
                        if(menu_rom_line_done = '1') then
                            menu_rom_addr_inc       <= '1';
                            menu_rom_clear_char_cnt <= '1';
                            state_next              <= WaitState;
                            goto_state_next         <= PrintFromMenuRomState;
                        end if;
                    end if;
                end if;

            when StartRc4 =>
                if rc4_ready = '1' then
                    if encrypt_decrypt_reg = DECRYPT then
                        if ValidAscii(ram_data_out, ACCEPT_HEX) then
                            rc4_start     <= '1';
                            rc4_input_mux <= RC4_INPUT_MUX_HEX;
                            state_next    <= WaitForRc4;
                        else -- Non Hex character received
                            addr_cnt_clear                 <= '1';
                            rc4_clear                      <= '1';
                            PrintFromMenuRom( ILLEGAL_CIPHER_START_ADDRESS, ILLEGAL_CIPHER_STOP_ADDRESS);
                        end if;
                    else --if ENCRYPT
                        output_reg_mux <= OUTPUT_MUX_RC4_HEX;
                        rc4_input_mux  <= RC4_INPUT_MUX_ASCII;
                        rc4_start      <= '1';
                        state_next     <= WaitForRc4;
                    end if;
                end if;

            when WaitForRc4 =>
                if encrypt_decrypt_reg = DECRYPT then
                    rc4_input_mux <= RC4_INPUT_MUX_HEX;
                else
                    output_reg_mux <= OUTPUT_MUX_RC4_HEX;
                    rc4_input_mux  <= RC4_INPUT_MUX_ASCII;
                end if;
                if rc4_done = '1' then
                    state_next <= ReadRc4;
                    i_cnt_next <= 0;
                end if;

            when ReadRc4 =>
                if tx_full = '0' then
                    if encrypt_decrypt_reg = DECRYPT then
                        rc4_input_mux  <= RC4_INPUT_MUX_HEX;
                        output_reg_mux <= OUTPUT_MUX_RC4_ASCII;
                        wr_uart        <= '1';
                        addr_cnt_en    <= '1';
                        state_next     <= LoopState;
                    else
                        rc4_input_mux  <= RC4_INPUT_MUX_ASCII;
                        output_reg_mux <= OUTPUT_MUX_RC4_HEX;
                        if i_cnt = 0 then
                            ascii_to_hex_lsb_msb <= ASCII_TO_HEX_MSB;
                            wr_uart              <= '1';
                            i_cnt_next           <= i_cnt + 1;
                        else
                            ascii_to_hex_lsb_msb <= ASCII_TO_HEX_LSB;
                            wr_uart              <= '1';
                            addr_cnt_en          <= '1';
                            state_next           <= LoopState;
                        end if;
                    end if;
                end if;

            when RamAddrIncrementState =>
                addr_cnt_en <= '1';
                state_next  <= goto_state_reg;

            when WaitState =>
                state_next <= goto_state_reg;

            when STOP =>

        end case;
    end process;
end Behavioral;

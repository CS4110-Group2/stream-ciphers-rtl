

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
           ram_data_out            : in  STD_LOGIC_VECTOR(7 downto 0);
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
           output_reg_mux          : out STD_LOGIC_VECTOR(2 downto 0);
           ascii_in                : in  STD_LOGIC_VECTOR(7 downto 0);
           custom_out              : out STD_LOGIC_VECTOR(7 downto 0); 
           menu_rom_addr_load_val  : out STD_LOGIC_VECTOR(7 downto 0);  
           menu_rom_addr_load_en   : out STD_LOGIC;
           menu_rom_addr           : in  STD_LOGIC_VECTOR(7 downto 0);
           menu_rom_addr_inc       : out STD_LOGIC;
           menu_rom_inc_char_cnt   : out STD_LOGIC; 
           menu_rom_clear_char_cnt : out STD_LOGIC;
           menu_rom_line_done      : in  STD_LOGIC; 
           encrypt_decrypt         : out STD_LOGIC); 
end ControlPath;

architecture Behavioral of ControlPath is

    type FSM is (Init, HandlePrompt, WaitRx, LoopState, HandleEnter, HandleBackspace, PrintHelp, ParseCommand, STOP, StartRc4, HandleAutoclave, ReadRc4, WaitForRc4, RamAddrIncrementState, ParseCipher, WaitState);
    signal state_reg, state_next : FSM := Init;

    signal i_cnt, i_cnt_next : integer := 0;
    signal current_menu_stop_address_reg, current_menu_stop_address_next : std_logic_vector(7 downto 0) := (others => '0');


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


    signal goto_state_reg, goto_state_next           : FSM;
    signal encrypt_decrypt_reg, encrypt_decrypt_next : std_logic := '0';
    signal cipher_select_reg, cipher_select_next     : std_logic := '0';

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
        custom_out                     <= (others => '0');
        menu_rom_addr_load_val         <= (others => '0');
        menu_rom_addr_load_en          <= '0';
        menu_rom_addr_inc              <= '0';
        menu_rom_inc_char_cnt          <= '0';
        menu_rom_clear_char_cnt        <= '0';
        encrypt_decrypt_next           <= encrypt_decrypt_reg;
        cipher_select_next             <= cipher_select_reg;
        goto_state_next                <= goto_state_reg;
        current_menu_stop_address_next <= current_menu_stop_address_reg;

        case state_reg is
            when Init =>
--                 Reset menu rom address counter and char cnt
                 -- menu_rom_addr_load_val <= HELP_START_ADDRESS;
                 -- menu_rom_addr_load_en <= '1';
                 -- menu_rom_clear_char_cnt <= '1';
                 -- state_next <= PrintHelp;

                --Skip print help on start
                output_reg_mux <= OUTPUT_MUX_CUSTOM;
                wr_uart <= '1';
                custom_out <= ENTER;
                i_cnt_next <= 0;
                state_next <= HandlePrompt;
            when HandlePrompt =>
                if tx_full = '0' then
                    output_reg_mux <= OUTPUT_MUX_CUSTOM;
                    wr_uart <= '1';
                    i_cnt_next <= i_cnt + 1;
                    if i_cnt = 0 then
                        custom_out <= LINEFEED; 
                    --TODO Change this to else, to fit with drawing
                    elsif i_cnt = 1 then
                        custom_out <= PROMPT; 
                        state_next <= WaitRx;
                    end if;
                end if;
            when WaitRx =>
                if rx_done_tick = '1' and tx_full = '0' then
                    if ValidAscii(ascii_in, ACCEPT_ASCII) then
                        if ascii_in = ENTER then
                            wr_uart <= '1';
                            ram_write <= '1';
                            addr_cnt_clear <= '1';
                            -- addr_cnt_en <= '1';
                            i_cnt_next <= 0;
                            output_reg_mux <= OUTPUT_MUX_CUSTOM;
                            custom_out <= ENTER;
                            wr_uart <= '1';
                            state_next <= HandleEnter;
                        elsif ascii_in = DELETE then
                            if addr_cnt_zero = '0' then
                                wr_uart <= '1';
                                ram_write <= '1';
                                addr_cnt_en <= '1';
                                i_cnt_next <= 0;
                                output_reg_mux <= OUTPUT_MUX_CUSTOM;
                                custom_out <= BACKSPACE;
                                ram_clr <= '1';
                                addr_cnt_up_down <= '1';
                                wr_uart <= '1';
                                state_next <= HandleBackspace;
                            end if;
                        else
                            output_reg_mux <= OUTPUT_MUX_INPUT;
                            wr_uart        <= '1';
                            ram_write      <= '1';
                            addr_cnt_en    <= '1';
                        end if;
                    end if;
                end if;
            

            when HandleBackspace =>
                if tx_full = '0' then
                    output_reg_mux <= OUTPUT_MUX_CUSTOM;
                    wr_uart <= '1';
                    i_cnt_next <= i_cnt + 1;
                    if i_cnt = 0 then
                        custom_out <= SPACE; 
                    elsif i_cnt = 1 then
                        custom_out <= BACKSPACE; 
                        state_next <= WaitRx;
                    end if;
                end if;
            when HandleEnter =>
                if tx_full = '0' then
                    output_reg_mux <= OUTPUT_MUX_CUSTOM;
                    custom_out <= LINEFEED; 
                    wr_uart <= '1';
                    if(ram_data_out = DASH) then
                        state_next <= ParseCommand;
                        i_cnt_next <= 0;
                        addr_cnt_en <= '1';
                    else
                        menu_rom_addr_load_val <= ILLEGAL_COMMAND_START_ADDRESS;
                        current_menu_stop_address_next <= ILLEGAL_COMMAND_STOP_ADDRESS;
                        menu_rom_addr_load_en <= '1';
                        menu_rom_clear_char_cnt <= '1';
                        addr_cnt_clear <= '1';
                        state_next <= WaitState;
                        goto_state_next <= PrintHelp;
                    end if;
                end if;
            when ParseCommand =>
                case ram_data_out is
                    when HELPCOMMAND =>
                        addr_cnt_clear <= '1';
                        menu_rom_addr_load_val <= HELP_START_ADDRESS;
                        current_menu_stop_address_next <= HELP_STOP_ADDRESS;
                        menu_rom_addr_load_en <= '1';
                        menu_rom_clear_char_cnt <= '1';
                        state_next <= WaitState;
                        goto_state_next <= PrintHelp;
                    when ENCRYPTCOMMAND =>
                        encrypt_decrypt_next <= ENCRYPT;
                        addr_cnt_en <= '1';
                        state_next <= RamAddrIncrementState;
                        goto_state_next <= LoopState;
                    when DECRYPTCOMMAND =>
                        encrypt_decrypt_next <= DECRYPT;
                        addr_cnt_en <= '1';
                        state_next <= RamAddrIncrementState;
                        goto_state_next <= LoopState;
                    when RESETCOMMAND =>
                        -- rst <= '1';
                        -- state_next <= Init;
                    when CIPHERCOMMAND =>
                        addr_cnt_en <= '1';
                        state_next <= RamAddrIncrementState;
                        goto_state_next <= ParseCipher;
                    when DASH =>
                        addr_cnt_en <= '1';
                        state_next <= ParseCommand;
                    when others =>
                        menu_rom_addr_load_val <= ILLEGAL_COMMAND_START_ADDRESS;
                        current_menu_stop_address_next <= ILLEGAL_COMMAND_STOP_ADDRESS;
                        menu_rom_addr_load_en <= '1';
                        menu_rom_clear_char_cnt <= '1';
                        addr_cnt_clear <= '1';
                        state_next <= WaitState;
                        goto_state_next <= PrintHelp;
                end case;
            when ParseCipher =>
                if ram_data_out = x"61" then
                    cipher_select_next <= CIPHER_AUTOCLAVE;
                    menu_rom_addr_load_val <= SELECTED_AUTOCLAVE_START_ADDRESS;
                    current_menu_stop_address_next <= SELECTED_AUTOCLAVE_STOP_ADDRESS;
                elsif ram_data_out = x"72" then
                    cipher_select_next <= CIPHER_RC4;
                    menu_rom_addr_load_val <= SELECTED_RC4_START_ADDRESS;
                    current_menu_stop_address_next <= SELECTED_RC4_STOP_ADDRESS;
                else
                    menu_rom_addr_load_val <= ILLEGAL_CIPHER_COMMAND_START_ADDRESS;
                    current_menu_stop_address_next <= ILLEGAL_CIPHER_COMMAND_STOP_ADDRESS;
                end if;
                    menu_rom_addr_load_en <= '1';
                    menu_rom_clear_char_cnt <= '1';
                    addr_cnt_clear <= '1';
                    state_next <= WaitState;
                    goto_state_next <= PrintHelp;
            when LoopState =>
                if tx_full = '0' then
                    if ram_data_out = ENTER then
                        wr_uart          <= '1';
                        output_reg_mux   <= OUTPUT_MUX_CUSTOM;
                        custom_out       <= ENTER; 
                        addr_cnt_clear   <= '1';
                        i_cnt_next       <= 0;
                        rc4_clear        <= '1';
                        autoclave_clear  <= '1';
                        state_next       <= HandlePrompt;
                    else
                        if cipher_select_reg = CIPHER_RC4 then
                            state_next <= StartRc4;
                            if encrypt_decrypt_reg = DECRYPT then
                                if ValidAscii(ram_data_out, ACCEPT_HEX) then
                                    hex_to_ascii_load <= '1';
                                    addr_cnt_en <= '1';
                                else
                                    menu_rom_addr_load_val <= ILLEGAL_CIPHER_START_ADDRESS;
                                    current_menu_stop_address_next <= ILLEGAL_CIPHER_STOP_ADDRESS;
                                    menu_rom_addr_load_en <= '1';
                                    menu_rom_clear_char_cnt <= '1';
                                    addr_cnt_clear <= '1';
                                    state_next <= WaitState;
                                    goto_state_next <= PrintHelp;
                                end if;
                            else
                                output_reg_mux       <= OUTPUT_MUX_RC4_HEX;
                                rc4_input_mux  <= RC4_INPUT_MUX_ASCII;
                            end if;
                        else -- CIPHER_AUTOCLAVE
                            -- autoclave_start <= '1';
                            -- state_next <= HandleAutoclave;

                            autoclave_start <= '1';
                            output_reg_mux  <= OUTPUT_MUX_AUTOCLAVE;
                            wr_uart         <= '1';
                            addr_cnt_en     <= '1';
                            state_next      <= LoopState;
                        end if;
                        --wr_uart <= '1';
                        --output_reg_mux <= OUTPUT_MUX_RAM;
                        --addr_cnt_en <= '1';
                    end if;
                end if;
            when PrintHelp =>
                if tx_full = '0' then
                    -- if menu_rom_addr = HELP_STOP_ADDRESS then
                    if menu_rom_addr = current_menu_stop_address_reg then
                        output_reg_mux <= OUTPUT_MUX_CUSTOM;
                        wr_uart        <= '1';
                        custom_out     <= ENTER;
                        i_cnt_next     <= 0;
                        state_next     <= HandlePrompt;
                    else
                        output_reg_mux        <= OUTPUT_MUX_MENUROM;
                        wr_uart               <= '1';
                        menu_rom_inc_char_cnt <= '1';
                        if(menu_rom_line_done = '1') then
                            menu_rom_addr_inc       <= '1';
                            menu_rom_clear_char_cnt <= '1';
                            state_next              <= WaitState;
                            goto_state_next         <= PrintHelp;
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
                        else
                            menu_rom_addr_load_val <= ILLEGAL_CIPHER_START_ADDRESS;
                            current_menu_stop_address_next <= ILLEGAL_CIPHER_STOP_ADDRESS;
                            menu_rom_addr_load_en <= '1';
                            menu_rom_clear_char_cnt <= '1';
                            addr_cnt_clear <= '1';
                            state_next <= WaitState;
                            goto_state_next <= PrintHelp;
                        end if;
                    else --if ENCRYPT
                        output_reg_mux       <= OUTPUT_MUX_RC4_HEX;
                        rc4_input_mux <= RC4_INPUT_MUX_ASCII;
                        rc4_start  <= '1';
                        state_next <= WaitForRc4;
                    end if;
                end if;
            when WaitForRc4 =>
                if encrypt_decrypt_reg = DECRYPT then
                    rc4_input_mux <= RC4_INPUT_MUX_HEX;
                else
                    output_reg_mux       <= OUTPUT_MUX_RC4_HEX;
                    rc4_input_mux <= RC4_INPUT_MUX_ASCII;
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
                        output_reg_mux       <= OUTPUT_MUX_RC4_HEX;
                        if i_cnt = 0 then
                            ascii_to_hex_lsb_msb <= ASCII_TO_HEX_MSB;
                            wr_uart              <= '1';
                            i_cnt_next           <= i_cnt + 1;
                        else
                            ascii_to_hex_lsb_msb <= ASCII_TO_HEX_LSB;
                            wr_uart        <= '1';
                            addr_cnt_en    <= '1';
                            state_next     <= LoopState;
                        end if;
                    end if;
                end if;
            when HandleAutoclave =>
                if tx_full = '0' then
                    autoclave_start <= '0';
                    output_reg_mux  <= OUTPUT_MUX_AUTOCLAVE;
                    wr_uart         <= '1';
                    addr_cnt_en     <= '1';
                    state_next      <= LoopState;
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

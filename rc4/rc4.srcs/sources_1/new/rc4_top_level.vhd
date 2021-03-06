library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity rc4_top_level is
    Generic( RC4_KEY : string := "ZAAAAAAA");
    Port ( clk      : in  STD_LOGIC;
           rst      : in  STD_LOGIC;
           start    : in  STD_LOGIC;
           clear    : in  STD_LOGIC;
           data_in  : in  STD_LOGIC_VECTOR (7 downto 0);
           data_out : out STD_LOGIC_VECTOR (7 downto 0);
           ready    : out STD_LOGIC;
           done     : out STD_LOGIC);
end rc4_top_level;

architecture Behavioral of rc4_top_level is

    -- Memory signals
    signal ram_address                                          : STD_LOGIC_VECTOR (7 downto 0);
    signal ram_data_out, ram_data_in, rom_data_out, reg_tmp_out : STD_LOGIC_VECTOR (7 downto 0);
    signal reg_j_in, reg_j_out, reg_tmp_in, reg_out_in          : STD_LOGIC_VECTOR (7 downto 0);
    signal load_reg_j, clear_reg_j, load_reg_tmp, ram_write     : STD_LOGIC;
    signal load_reg_out                                         : STD_LOGIC;

    -- ALU signals
    signal reg_j_and_ram_adder_out         : STD_LOGIC_VECTOR (7 downto 0);
    signal keystream_value_index_adder_out : STD_LOGIC_VECTOR (7 downto 0);

    -- MUX signals
    signal ram_address_select           : STD_LOGIC_VECTOR (1 downto 0);
    signal reg_j_select, reg_tmp_select : STD_LOGIC;
    signal ram_data_in_select           : STD_LOGIC;

    -- Counter signals
    signal counter_i_inc, counter_i_clear, counter_i_max_tick, counter_i_load : STD_LOGIC;
    signal counter_i_out                                                      : STD_LOGIC_VECTOR (7 downto 0);

begin

    ram: entity work.rc4_ram(Behavioral)
    port map
    (
        clk      => clk,
        write    => ram_write,
        address  => ram_address,
        data_in  => ram_data_in,
        data_out => ram_data_out
    );

    rom: entity work.rc4_rom(Behavioral)
    generic map(ADDR_WIDTH => 8, DATA_WIDTH => 8, RC4_KEY => RC4_KEY)
    port map
    (
        address  => counter_i_out,
        data_out => rom_data_out
    );

    reg_j: entity work.rc4_reg(Behavioral)
    port map
    (
        clk      => clk,
        rst      => rst,
        load     => load_reg_j,
        data_in  => reg_j_in,
        data_out => reg_j_out,
        clear    => clear_reg_j
    );

    reg_tmp: entity work.rc4_reg(Behavioral)
    port map
    (
        clk      => clk,
        rst      => rst,
        load     => load_reg_tmp,
        data_in  => reg_tmp_in,
        data_out => reg_tmp_out,
        clear    => '0'
    );

    reg_out: entity work.rc4_reg(Behavioral)
    port map
    (
        clk      => clk,
        rst      => rst,
        load     => load_reg_out,
        data_in  => reg_out_in,
        data_out => data_out,
        clear    => '0'
    );

    counter_i: entity work.rc4_counter(Behavioral)
    port map
    (
        clk      => clk,
        rst      => rst,
        clear    => counter_i_clear,
        inc      => counter_i_inc,
        q        => counter_i_out,
        max_tick => counter_i_max_tick,
        load     => counter_i_load,
        data_in  => "00000001"
    );

    control_path: entity work.rc4_control_path(Behavioral)
    port map
    (
        clk                => clk,
        rst                => rst,
        ready              => ready,
        start              => start,
        done               => done,
        clear              => clear,
        counter_i_inc      => counter_i_inc,
        counter_i_clear    => counter_i_clear,
        load_reg_j         => load_reg_j,
        load_reg_tmp       => load_reg_tmp,
        ram_write          => ram_write,
        ram_address_select => ram_address_select,
        reg_j_select       => reg_j_select,
        counter_i_max_tick => counter_i_max_tick,
        clear_reg_j        => clear_reg_j,
        reg_tmp_select     => reg_tmp_select,
        counter_i_load     => counter_i_load,
        ram_data_in_select => ram_data_in_select,
        load_reg_out       => load_reg_out
    );

    -- Glue logic
    reg_j_and_ram_adder_out <= STD_LOGIC_VECTOR(unsigned(reg_j_out) + unsigned(ram_data_out));

    keystream_value_index_adder_out <= STD_LOGIC_VECTOR(unsigned(ram_data_out) + unsigned(reg_tmp_out));

    reg_out_in <= STD_LOGIC_VECTOR(unsigned(data_in) xor unsigned(ram_data_out));

    -- J Register Multiplexer
    reg_j_in <= reg_j_and_ram_adder_out when reg_j_select = '0' else
                STD_LOGIC_VECTOR(unsigned(reg_j_and_ram_adder_out) + unsigned(rom_data_out));

    -- RAM Address Multiplexer
    ram_address <= counter_i_out when ram_address_select = "00" else
                   reg_j_out     when ram_address_select = "01" else
                   reg_tmp_out;

    -- TMP Register Multiplexer
    reg_tmp_in <= ram_data_out when reg_tmp_select = '0' else
                  keystream_value_index_adder_out;

    -- RAM Data In Multiplexer
    ram_data_in <= reg_tmp_out when ram_data_in_select <= '0' else
                   counter_i_out;

end Behavioral;

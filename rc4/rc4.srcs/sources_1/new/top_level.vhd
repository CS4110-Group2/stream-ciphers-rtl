library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity top_level is
    Port ( clk : in STD_LOGIC;
           rst : in STD_LOGIC;
           rx : in STD_LOGIC;
           tx : out STD_LOGIC);
end top_level;

architecture Behavioral of top_level is

	-- UART signals
	signal uart_rx_data_out, uart_tx_data_in : STD_LOGIC_VECTOR (7 downto 0);
	signal s_tick, rx_done, tx_done, tx_start : STD_LOGIC;

	-- Memory signals
	signal ram_address, rom_address : STD_LOGIC_VECTOR (7 downto 0); --Maybe remove rom address
	signal ram_data_out, rom_data_out, reg_tmp_out : STD_LOGIC_VECTOR (7 downto 0);
	signal reg_j_in, reg_j_out, reg_tmp_in : STD_LOGIC_VECTOR (7 downto 0);
	signal load_reg_j, clear_reg_j, load_reg_tmp, ram_write : STD_LOGIC;
	signal load_reg_k_index : STD_LOGIC;

	-- ALU signals
	signal something_adder_out : STD_LOGIC_VECTOR (7 downto 0);
	signal keystream_value_index_adder_out : STD_LOGIC_VECTOR (7 downto 0);

	-- MUX signals
	signal ram_address_select : STD_LOGIC_VECTOR (1 downto 0);
	signal reg_j_select, reg_tmp_select : STD_LOGIC;

	-- Counter signals
	signal counter_i_inc, counter_i_clear, counter_i_max_tick, counter_i_load : STD_LOGIC;
	signal counter_i_out : STD_LOGIC_VECTOR (7 downto 0);

begin

	mod_m_counter: entity work.mod_m_counter(arch)
	port map(clk => clk, rst => rst, s_tick => s_tick);

	uart_tx: entity work.uart_tx(arch)
	port map(clk => clk, rst => rst, tx => tx, s_tick => s_tick,
		tx_done_tick => tx_done, din => uart_tx_data_in, tx_start => tx_start);

	uart_rx: entity work.uart_rx(arch)
	port map(clk => clk, rst => rst, rx => rx, s_tick => s_tick,
		rx_done_tick => rx_done, dout => uart_rx_data_out);

	ram: entity work.ram(Behavioral)
	port map(clk => clk, rst => rst, write => ram_write, address => ram_address,
		data_in => reg_tmp_out, data_out => ram_data_out);

	rom: entity work.rom(Behavioral)
	port map(address => counter_i_out, data_out => rom_data_out);

	reg_j: entity work.reg(Behavioral)
	port map(clk => clk, rst => rst, load => load_reg_j, data_in => reg_j_in,
		data_out => reg_j_out, clear => clear_reg_j);

	reg_tmp: entity work.reg(Behavioral)
	port map(clk => clk, rst => rst, load => load_reg_tmp, data_in => reg_tmp_in,
		data_out => reg_tmp_out, clear => '0');

--	reg_k_index: entity work.reg(Behavioral)
--	port map(clk => clk, rst => rst, load => load_reg_k_index,
--			 data_in => keystream_value_index_adder_out, data_out => reg_k_index_out,
--			 clear => '0');

	counter_i: entity work.counter(Behavioral)
	port map(clk => clk, rst => rst, clear => counter_i_clear, inc => counter_i_inc,
		q => counter_i_out, max_tick => counter_i_max_tick, load => counter_i_load,
		data_in => "00000001");

	control_path: entity work.control_path(Behavioral)
	port map(clk => clk, rst => rst, rx_done => rx_done, tx_done => tx_done,
			 tx_start => tx_start, counter_i_inc => counter_i_inc,
			 counter_i_clear => counter_i_clear, load_reg_j => load_reg_j,
			 load_reg_tmp => load_reg_tmp, ram_write => ram_write,
			 ram_address_select => ram_address_select, reg_j_select => reg_j_select,
			 counter_i_max_tick => counter_i_max_tick, clear_reg_j => clear_reg_j,
			 reg_tmp_select => reg_tmp_select, counter_i_load => counter_i_load);

	-- Glue logic
	something_adder_out <= STD_LOGIC_VECTOR(unsigned(reg_j_out) + unsigned(ram_data_out));

	keystream_value_index_adder_out <= STD_LOGIC_VECTOR(unsigned(ram_data_out) + unsigned(reg_tmp_out));

	uart_tx_data_in <= STD_LOGIC_VECTOR(unsigned(uart_rx_data_out) xor unsigned(ram_data_out));

	-- J Register Multiplexer
	reg_j_in <= something_adder_out when reg_j_select = '0' else
				STD_LOGIC_VECTOR(unsigned(something_adder_out) + unsigned(rom_data_out));

	-- RAM Address Multiplexer
	ram_address <= counter_i_out when ram_address_select = "00" else -- Maybe fix this one
				   reg_j_out when ram_address_select = "01" else
				   reg_tmp_out;

	-- TMP Register Multiplexer
	reg_tmp_in <= ram_data_out when reg_tmp_select = '0' else
				  keystream_value_index_adder_out;

end Behavioral;

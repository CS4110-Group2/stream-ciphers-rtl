
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


entity Shell is
    Port ( clk : in STD_LOGIC;
           rst : in STD_LOGIC;
           RsRx : in STD_LOGIC;
           RsTx : out STD_LOGIC;
           seg : out STD_LOGIC_VECTOR (7 downto 0);
           an : out STD_LOGIC_VECTOR (3 downto 0));
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

    signal output_reg_in, output_reg_out : std_logic_vector(7 downto 0);
    signal output_reg_load, output_reg_clear : std_logic;
    signal output_reg_mux : std_logic_vector(1 downto 0);

    signal custom_out : std_logic_vector(7 downto 0);
    
begin

    ram_data_in <= ascii_in;

    ram_addr <= addr_cnt_out;

    opcode_reg_in <= ram_data_out;

    ascii_out <= ascii_in when output_reg_mux = "00" else
                 ram_data_out when output_reg_mux = "01" else
                 custom_out;

                 -- x"20" when output_reg_mux = "001" else
                 -- x"08" when output_reg_mux = "010" else
                 -- x"7F" when output_reg_mux = ";

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
        output_reg_load => output_reg_load,
        output_reg_clear => output_reg_clear,
        output_reg_mux => output_reg_mux,
        ascii_in => ascii_in,
        custom_out => custom_out
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
    out_reg : entity work.Reg(Behavioral)
    generic map
    (
        SIZE => 8
    )
    port map
    (
        clk => clk,
        rst => rst,
        load => output_reg_load,
        clear => output_reg_clear,
        data_in => output_reg_in,
        data_out => output_reg_out
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

end Behavioral;

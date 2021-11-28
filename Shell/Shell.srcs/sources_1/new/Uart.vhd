

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.math_real.all;

entity Uart is
    Generic( BAUDRATE : integer := 19200);
    Port ( clk : in STD_LOGIC;
           rst: in STD_LOGIC;
           rx : in STD_LOGIC;
           rx_data : out STD_LOGIC_VECTOR (7 downto 0);
           rx_done_tick : out STD_LOGIC;
           tx : out STD_LOGIC;
           tx_data : in STD_LOGIC_VECTOR (7 downto 0);
           tx_empty : out STD_LOGIC;
           tx_full : out STD_LOGIC;
           wr_uart : in STD_LOGIC);
end Uart;

architecture Behavioral of Uart is

    signal baudrate_tick : std_logic;
    signal tx_done_tick : std_logic;
    signal transmit_buffer : std_logic_vector(7 downto 0);
    signal tx_fifo_empty : std_logic;
    signal tx_start : std_logic;

    constant MCount : integer := integer(100000000/(BAUDRATE*16));
    constant NBits : integer := integer(ceil(log2(real(MCount))));

begin

    tx_empty <= tx_fifo_empty;
    tx_start <= not tx_fifo_empty;

    tx_interface : entity work.Fifo(Behavioral)
    port map
    (
        clk => clk,
        rst => rst,
        rd => tx_done_tick,
        wr => wr_uart,
        w_data => tx_data,
        empty => tx_fifo_empty,
        full => tx_full,
        r_data => transmit_buffer
    );

    UartTxComp : entity work.UartTx(Behavioral)
    port map
    (
        clk => clk,
        rst => rst,
        din => transmit_buffer,
        tx_start => tx_start,
        s_tick => baudrate_tick,
        tx_done_tick => tx_done_tick,
        tx => tx
    );

    modMCounter : entity work.ModMCounterEn(Behavioral)
    generic map( N => NBits, M => MCount)
    port map
    (
        en => '1',
        rst => '0',
        clk => clk,
        clr => '0',
        data_in => (others => '0'),
        load_en => '0',
        q => open,
        max_tick => baudrate_tick
    );

    UartRxComp : entity work.UartRx(Behavioral)
    port map
    (
        rx => rx,
        clk => clk,
        rst => rst,
        s_tick => baudrate_tick,
        dout => rx_data,
        rx_done_tick => rx_done_tick
    );
end Behavioral;

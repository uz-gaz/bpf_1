--------------------------------------------------------------------------------
-- Project Name: A basic processor core for running BPF programs
-- Author:       Fernando Lahoz Bernad
--
-- Description:  Top module for simulation of a Microblaze connected to
--               BPF_AXI_Peripheral and AXI_UART_Lite. Emulates UART outputs
--               using textio library.
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

entity top_mb is
end top_mb;

architecture Behavioral of top_mb is

    component design_mb_wrapper is
    port (
        reset : in std_logic;
        rs232_uart_rxd : in std_logic;
        rs232_uart_txd : out std_logic;
        sys_diff_clock_clk_n : in std_logic;
        sys_diff_clock_clk_p : in std_logic
    );
    end component;
    
    signal reset, sys_diff_clock_clk_n : std_logic := '0';
    signal rs232_uart_rxd, rs232_uart_txd : std_logic := '0';
    signal sys_diff_clock_clk_p : std_logic := '1';
    
    signal clk : std_logic := '0';
    
    
    signal character_state : std_logic_vector (2 downto 0) := "000";
    signal counter : std_logic_vector (31 downto 0) := x"00000000";
    signal number_of_bits_received : std_logic_vector (31 downto 0) := x"00000000";
    signal data_received : std_logic_vector (9 downto 0) := "0000000000";
    file output_file_stdout : text; 
    signal charbuffer : String (1 to 80);
    signal charbuffer_index : integer := 1;
    
begin

    design: design_mb_wrapper
        port map (
            reset => reset,
            rs232_uart_rxd => rs232_uart_rxd,
            rs232_uart_txd => rs232_uart_txd,
            sys_diff_clock_clk_n => sys_diff_clock_clk_n,
            sys_diff_clock_clk_p => sys_diff_clock_clk_p
        );
        
    process
    begin
        file_open(output_file_stdout, "STD_OUTPUT", write_mode);
        reset <= '1';
        wait for 10 us;
        reset <= '0';
        wait;
    end process;
    
    -- 100 MHz clock for UART
    clk <= not clk after 2.5 ns ;
    
    -- 200 MHz clock
    CLK_PROC: process
    begin
        sys_diff_clock_clk_n <= '1';
        sys_diff_clock_clk_p <= '0';
        wait for 2.5 ns;
        sys_diff_clock_clk_n <= '0';
        sys_diff_clock_clk_p <= '1';
        wait for 2.5 ns;
    end process;

    process (clk)
    variable line1 : line;
    begin
        if rising_edge (clk) then
            if reset = '0' then
                counter <= std_logic_vector (unsigned (counter) + x"00000001");
                case character_state is
                    when "000" => 
                        if '0' = rs232_uart_txd then
                            character_state <= "001"; -- start bit '0' received.
                            counter <= x"00000000";
                        end if;
                    when "001" => -- start bit clock cycles
                        if counter = x"00000364" then -- (200M/2400)/2 = 83333/2 = 41666 = 0xa2c2
                            character_state <= "010"; -- reached middle of start bit.
                            counter <= x"00000000";
                        end if;
                    when "010" => -- receiving characters
                        if counter = x"000006c8" then -- goto next character
                            data_received(9) <= rs232_uart_txd;
                            data_received(8 downto 0) <= data_received(9 downto 1);
                            counter <= x"00000000";
                            if number_of_bits_received = x"00000007" then
                                number_of_bits_received <= x"00000000";
                                character_state <= "011";
                            else
                                number_of_bits_received <= std_logic_vector (unsigned (number_of_bits_received) + x"00000001");
                            end if;
                        end if;
                    when "011" =>
                        if counter = x"000006c8" then -- middle of stop character
                            -- report "received " & integer'image (to_integer (unsigned (data_received(9 downto 2))));
                            -- write (line1, character'val(to_integer(unsigned(data_received(9 downto 2)))));
                            -- writeline (output_file_stdout, line1);
                            if (charbuffer_index = 81) then
                                charbuffer (1) <= character'val(to_integer(unsigned(data_received(9 downto 2))));
                                charbuffer_index <= 2;
                                write (line1, charbuffer, left);
                                writeline (output_file_stdout, line1);
                                for i in 1 to 80 loop 
                                    charbuffer (i) <= character'val(0);
                                end loop;
                            elsif (10 = to_integer(unsigned(data_received(9 downto 2)))) then
                                charbuffer_index <= 1;
                                write (line1, charbuffer, left);
                                writeline (output_file_stdout, line1);
                                for i in 1 to 80 loop 
                                    charbuffer (i) <= character'val(0);
                                end loop;
                            else
                                charbuffer(charbuffer_index) <= character'val(to_integer(unsigned(data_received(9 downto 2))));
                                charbuffer_index <= charbuffer_index + 1;
                            end if;
                            character_state <= "000";
                            counter <= x"00000000";
                        end if;
                    when others =>
                        counter <= x"00000000";
                        data_received <= "0000000000";
                        number_of_bits_received <= x"00000000";
                        character_state <= "000";
                end case;
            end if;
        end if;
    end process;


end Behavioral;

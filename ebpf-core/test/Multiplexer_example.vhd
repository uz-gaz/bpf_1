--------------------------------------------------------------------------------
-- Project Name: A basic processor core for running BPF programs
-- Author:       Fernando Lahoz Bernad
--
-- Description:  Example of use of generic Multiplexer.
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

-- In order to use Multiplexer
use work.bus_array_pkg.all;

entity Multiplexer_Testbench is
end Multiplexer_Testbench;

architecture Behavioral of Multiplexer_Testbench is

    component Multiplexer is
        generic ( BUS_WIDTH: positive; SEL_WIDTH: positive );
    
        port (
            input : in Bus_Array (2**SEL_WIDTH - 1 downto 0) (BUS_WIDTH - 1 downto 0);
            sel : in std_logic_vector(SEL_WIDTH - 1 downto 0);
            output : out std_logic_vector(BUS_WIDTH - 1 downto 0)
        );
    end component;

    constant CLK_PERIOD : time := 10 ns;

    signal clk : std_logic;
    signal opt_0, opt_1, opt_2, opt_3, output : std_logic_vector (7 downto 0);
    signal selector : std_logic_vector (1 downto 0);

    signal test_done : std_logic;

begin

    opt_0 <= "00000011";
    opt_1 <= "00001100";
    opt_2 <= "00110000";
    opt_3 <= "11000000";

    mux8_2: Multiplexer
        generic map( BUS_WIDTH => 8, SEL_WIDTH => 2)
        port map(
            input => (0 => opt_0, 1 => opt_1, 2 => opt_2, 3 => opt_3),
            sel => selector,
            output => output
        );

    CLK_PROC: process
    begin
        if (test_done /= '1') then
            CLK <= '0';
            wait for CLK_PERIOD / 2;
            CLK <= '1';
            wait for CLK_PERIOD / 2;
        else
            wait;
        end if;
    end process;

    TEST_PROC: process
    begin
        test_done <= '0';
        ------------------------------------------------------------------------
        selector <= "00";
        wait for CLK_period;
        ------------------------------------------------------------------------
        selector <= "01";
        wait for CLK_period;
        ------------------------------------------------------------------------
        selector <= "10";
        wait for CLK_period;
        ------------------------------------------------------------------------
        selector <= "11";
        wait for CLK_period;
        ------------------------------------------------------------------------
        test_done <= '1';
        wait;
    end process;

end Behavioral;
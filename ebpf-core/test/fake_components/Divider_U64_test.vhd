--------------------------------------------------------------------------------
-- Project Name: A basic processor core for running BPF programs
-- Author:       Fernando Lahoz Bernad
--
-- Description:  Test for fake division unit.
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Divider_U64_Testbench is
end Divider_U64_Testbench;

architecture Behavioral of Divider_U64_Testbench is

    component Divider_U64 is
        port (
            aclk : in std_logic;
            s_axis_divisor_tvalid : in std_logic;
            s_axis_divisor_tready : out std_logic;
            s_axis_divisor_tdata : in std_logic_vector(63 downto 0);
            s_axis_dividend_tvalid : in std_logic;
            s_axis_dividend_tready : out std_logic;
            s_axis_dividend_tdata : in std_logic_vector(63 downto 0);
            m_axis_dout_tvalid : out std_logic;
            m_axis_dout_tdata : out std_logic_vector(127 downto 0)
      );
    end component;

    constant CLK_PERIOD : time := 10 ns;

    signal clk, ok_A, ok_B, ok_result : std_logic;
    signal op_A, op_B, cocient, remainder : std_logic_vector (63 downto 0);
    signal result : std_logic_vector (127 downto 0);

    signal test_done : std_logic;

begin

    cocient <= result(127 downto 64);
    remainder <= result(63 downto 0);

    divider: Divider_U64
        port map (
            aclk => clk,
            s_axis_divisor_tvalid => ok_B,
            s_axis_divisor_tdata => op_B,
            s_axis_dividend_tvalid => ok_A,
            s_axis_dividend_tdata => op_A,
            m_axis_dout_tvalid => ok_result,
            m_axis_dout_tdata => result
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

        ok_A <= '0';
        ok_B <= '0';
        wait until clk = '1';
        wait for 2*CLK_PERIOD;
        ------------------------------------------------------------------------
        ok_A <= '1';
        ok_B <= '1';
        op_A <= std_logic_vector(to_signed(100, op_A'length));
        op_B <= std_logic_vector(to_signed(7, op_B'length));

        wait until ok_result = '1';
        wait for CLK_PERIOD;
        ------------------------------------------------------------------------
        test_done <= '1';
        wait;
    end process;

end Behavioral;
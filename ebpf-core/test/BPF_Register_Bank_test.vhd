--------------------------------------------------------------------------------
-- Project Name: A basic processor core for running BPF programs
-- Author:       Fernando Lahoz Bernad
--
-- Description:  Unit test for BPF_Register_Bank.
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity BPF_Register_Bank_Testbench is
end BPF_Register_Bank_Testbench;

architecture Behavioral of BPF_Register_Bank_Testbench is

    component BPF_Register_Bank is
        port (
            clk : in std_logic;
            reset : in std_logic;
    
            reg_A : in std_logic_vector (3 downto 0);
            reg_B : in std_logic_vector (3 downto 0);
            reg_W : in std_logic_vector (3 downto 0);
            input : in std_logic_vector (63 downto 0);
            write_en : in std_logic;
            r0_write_en : in std_logic;
    
            output_A : out std_logic_vector (63 downto 0);
            output_B : out std_logic_vector (63 downto 0);
            output_R0 : out std_logic_vector (63 downto 0)
        );
    end component;

    constant CLK_PERIOD : time := 10 ns;

    signal clk, reset, write_en, r0_write_en : std_logic;
    signal input, A, B, R0 : std_logic_vector (63 downto 0);
    signal reg_A, reg_B, reg_W : std_logic_vector (3 downto 0);

    signal test_done : std_logic;

begin

    tested_unit: BPF_Register_Bank
        port map (
            clk => clk, reset => reset,
            reg_A => reg_A, reg_B => reg_B, reg_W => reg_W,
            input => input, write_en => write_en, r0_write_en => r0_write_en,
            output_A => A, output_B => B, output_R0 => R0
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
        -- Ensure stable initial state -----------------------------------------
        reset <= '1';
        wait for CLK_period * 2;
        reset <= '0';
        wait until clk = '1';

        r0_write_en <= '0';

        -- Test R0 and R1 ------------------------------------------------------
        reg_A <= "0000";
        reg_B <= "0001";

        input <= (63 downto 0 => '1'); -- R0 <= "111..111"
        reg_W <= "0000";
        write_en <= '1';

        wait for CLK_period; -- should write HERE!

        input <= (63 => '0', 62 downto 1 => '1', 0 => '0'); -- R1 <= "011..110"
        write_en <= '0';

        wait for CLK_period; -- shouldn't write after this tick

        reg_W <= "0001";
        write_en <= '1';

        wait for CLK_period; -- should write HERE!

        -- Check reading/writing out of bounds ---------------------------------
        reg_A <= "1011";
        reg_B <= "1010";

        input <= (63 downto 4 => '0', 3 downto 0 => '1'); -- R10 <= "00..001111"
        reg_W <= "1010";
        write_en <= '1';

        wait for CLK_period; -- should write HERE!

        reg_W <= "1011";
        write_en <= '1';

        wait for CLK_period; -- should not write and show 0s instead

        ------------------------------------------------------------------------
        test_done <= '1';
        wait;
    end process;

end Behavioral;

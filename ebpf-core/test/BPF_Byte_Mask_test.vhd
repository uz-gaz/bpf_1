--------------------------------------------------------------------------------
-- Project Name: A basic processor core for running BPF programs
-- Author:       Fernando Lahoz Bernad
--
-- Description:  Unit test for BPF_Byte_Mask.
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

use work.bpf.all;

entity BPF_Byte_Mask_Testbench is
end BPF_Byte_Mask_Testbench;

architecture Behavioral of BPF_Byte_Mask_Testbench is

    component BPF_Byte_Mask is
        port (
            input : in std_logic_vector (63 downto 0);
            size : in std_logic_vector (1 downto 0);
            sign_extend : in std_logic;
            
            output : out std_logic_vector (63 downto 0)
        );
    end component;

    constant CLK_PERIOD : time := 10 ns;

    signal clk : std_logic;
    signal input, output : std_logic_vector (63 downto 0);
    signal sign_extend : std_logic;
    signal size : std_logic_vector (1 downto 0);

    signal test_done : std_logic;

begin

    tested_unit: BPF_Byte_Mask
        port map (
            input => input,
            size => size,
            sign_extend => sign_extend,
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
        -- Tests 8 bit mask ----------------------------------------------------
        input <= (63 downto 0 => '1');
        size <= BPF_SIZE8;
        sign_extend <= '0';

        wait for CLK_period;

        input <= (63 downto 0 => '1');
        size <= BPF_SIZE8;
        sign_extend <= '1';

        wait for CLK_period;

        input <= (63 downto 8 => '1', 7 => '0', 6 downto 0 => '1');
        size <= BPF_SIZE8;
        sign_extend <= '0';

        wait for CLK_period;

        input <= (63 downto 8 => '1', 7 => '0', 6 downto 0 => '1');
        size <= BPF_SIZE8;
        sign_extend <= '1';

        wait for CLK_period;

        -- Tests 16 bit mask ---------------------------------------------------
        input <= (63 downto 0 => '1');
        size <= BPF_SIZE16;
        sign_extend <= '0';

        wait for CLK_period;

        input <= (63 downto 0 => '1');
        size <= BPF_SIZE16;
        sign_extend <= '1';

        wait for CLK_period;

        input <= (63 downto 16 => '1', 15 => '0', 14 downto 0 => '1');
        size <= BPF_SIZE16;
        sign_extend <= '0';

        wait for CLK_period;

        input <= (63 downto 16 => '1', 15 => '0', 14 downto 0 => '1');
        size <= BPF_SIZE16;
        sign_extend <= '1';

        wait for CLK_period;

        -- Tests 32 bit mask ---------------------------------------------------
        input <= (63 downto 0 => '1');
        size <= BPF_SIZE32;
        sign_extend <= '0';

        wait for CLK_period;

        input <= (63 downto 0 => '1');
        size <= BPF_SIZE32;
        sign_extend <= '1';

        wait for CLK_period;

        input <= (63 downto 32 => '1', 31 => '0', 30 downto 0 => '1');
        size <= BPF_SIZE32;
        sign_extend <= '0';

        wait for CLK_period;

        input <= (63 downto 32 => '1', 31 => '0', 30 downto 0 => '1');
        size <= BPF_SIZE32;
        sign_extend <= '1';

        wait for CLK_period;

        -- Tests 64 bit mask ---------------------------------------------------
        input <= (63 downto 0 => '1');
        size <= BPF_SIZE64;
        sign_extend <= '0';

        wait for CLK_period;

        input <= (63 downto 0 => '1');
        size <= BPF_SIZE64;
        sign_extend <= '1';

        wait for CLK_period;

        input <= (63 => '0', 62 downto 0 => '1');
        size <= BPF_SIZE64;
        sign_extend <= '0';

        wait for CLK_period;

        input <= (63 => '0', 62 downto 0 => '1');
        size <= BPF_SIZE64;
        sign_extend <= '1';

        wait for CLK_period;

        ------------------------------------------------------------------------

        test_done <= '1';
        wait;
    end process;

end Behavioral;

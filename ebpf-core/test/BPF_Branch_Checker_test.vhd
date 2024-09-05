--------------------------------------------------------------------------------
-- Project Name: A basic processor core for running BPF programs
-- Author:       Fernando Lahoz Bernad
--
-- Description:  Unit test for BPF_Branch_Checker.
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.bpf.all;

entity BPF_Branch_Checker_Testbench is
end BPF_Branch_Checker_Testbench;

architecture Behavioral of BPF_Branch_Checker_Testbench is

    component BPF_Branch_Checker is
        port (
            operand_A : in std_logic_vector (63 downto 0);
            operand_B : in std_logic_vector (63 downto 0);
            op_cmp : in std_logic_vector (3 downto 0);
            op_64b : in std_logic;
            taken : out std_logic
        );
    end component;

    constant CLK_PERIOD : time := 10 ns;

    signal clk : std_logic;
    signal operand_A, operand_B : std_logic_vector (63 downto 0);
    signal op_64b, taken : std_logic;
    signal op_cmp : std_logic_vector (3 downto 0);

    signal test_done : std_logic;

begin

    tested_unit: BPF_Branch_Checker
        port map (
            operand_A => operand_A,
            operand_B => operand_B,
            op_cmp => op_cmp,
            op_64b => op_64b,
            taken => taken
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
        variable test_ok : std_logic;
    begin
        test_ok := '1';
        test_done <= '0';

        op_64b <= '1';
        -- Test EQ -------------------------------------------------------------
        op_cmp <= BPF_JEQ;

        operand_A <= std_logic_vector(to_signed(23, operand_A'length));
        operand_B <= std_logic_vector(to_signed(23, operand_B'length));
        wait for CLK_period;

        if taken = '1' then report "Test EQ.1: OK" severity note;
        else test_ok := '0'; report "Test EQ.1: failed" severity note; end if;

        operand_A <= std_logic_vector(to_signed(14, operand_A'length));
        operand_B <= std_logic_vector(to_signed(15, operand_B'length));
        wait for CLK_period;

        if taken = '0' then report "Test EQ.2: OK" severity note;
        else test_ok := '0'; report "Test EQ.2: failed" severity note; end if;

        operand_A <= std_logic_vector(to_signed(16, operand_A'length));
        operand_B <= std_logic_vector(to_signed(7, operand_B'length));
        wait for CLK_period;

        if taken = '0' then report "Test EQ.3: OK" severity note;
        else test_ok := '0'; report "Test EQ.3: failed" severity note; end if;

        -- Test GT -------------------------------------------------------------
        op_cmp <= BPF_JGT;

        operand_A <= std_logic_vector(to_signed(23, operand_A'length));
        operand_B <= std_logic_vector(to_signed(23, operand_B'length));
        wait for CLK_period;

        if taken = '0' then report "Test GT.1: OK" severity note;
        else test_ok := '0'; report "Test GT.1: failed" severity note; end if;

        operand_A <= std_logic_vector(to_signed(14, operand_A'length));
        operand_B <= std_logic_vector(to_signed(15, operand_B'length));
        wait for CLK_period;

        if taken = '0' then report "Test GT.2: OK" severity note;
        else test_ok := '0'; report "Test GT.2: failed" severity note; end if;

        operand_A <= std_logic_vector(to_signed(16, operand_A'length));
        operand_B <= std_logic_vector(to_signed(7, operand_B'length));
        wait for CLK_period;

        if taken = '1' then report "Test GT.3: OK" severity note;
        else test_ok := '0'; report "Test GT.3: failed" severity note; end if;

        -- Test GE -------------------------------------------------------------
        op_cmp <= BPF_JGE;

        operand_A <= std_logic_vector(to_signed(23, operand_A'length));
        operand_B <= std_logic_vector(to_signed(23, operand_B'length));
        wait for CLK_period;

        if taken = '1' then report "Test GE.1: OK" severity note;
        else test_ok := '0'; report "Test GE.1: failed" severity note; end if;

        operand_A <= std_logic_vector(to_signed(14, operand_A'length));
        operand_B <= std_logic_vector(to_signed(15, operand_B'length));
        wait for CLK_period;

        if taken = '0' then report "Test GE.2: OK" severity note;
        else test_ok := '0'; report "Test GE.2: failed" severity note; end if;

        operand_A <= std_logic_vector(to_signed(16, operand_A'length));
        operand_B <= std_logic_vector(to_signed(7, operand_B'length));
        wait for CLK_period;

        if taken = '1' then report "Test GE.3: OK" severity note;
        else test_ok := '0'; report "Test GE.3: failed" severity note; end if;

        -- Test SET -------------------------------------------------------------
        op_cmp <= BPF_JSET;

        operand_A <= std_logic_vector(to_signed(23, operand_A'length));
        operand_B <= std_logic_vector(to_signed(1, operand_B'length));
        wait for CLK_period;

        if taken = '1' then report "Test SET.1: OK" severity note;
        else test_ok := '0'; report "Test SET.1: failed" severity note; end if;

        operand_A <= std_logic_vector(to_signed(8, operand_A'length));
        operand_B <= std_logic_vector(to_signed(4, operand_B'length));
        wait for CLK_period;

        if taken = '0' then report "Test SET.2: OK" severity note;
        else test_ok := '0'; report "Test SET.2: failed" severity note; end if;

        operand_A <= std_logic_vector(to_signed(-1, operand_A'length));
        operand_B <= std_logic_vector(to_signed(75, operand_B'length));
        wait for CLK_period;

        if taken = '1' then report "Test SET.3: OK" severity note;
        else test_ok := '0'; report "Test SET.3: failed" severity note; end if;

        -- Test NE -------------------------------------------------------------
        op_cmp <= BPF_JNE;

        operand_A <= std_logic_vector(to_signed(23, operand_A'length));
        operand_B <= std_logic_vector(to_signed(23, operand_B'length));
        wait for CLK_period;

        if taken = '0' then report "Test NE.1: OK" severity note;
        else test_ok := '0'; report "Test NE.1: failed" severity note; end if;

        operand_A <= std_logic_vector(to_signed(14, operand_A'length));
        operand_B <= std_logic_vector(to_signed(15, operand_B'length));
        wait for CLK_period;

        if taken = '1' then report "Test NE.2: OK" severity note;
        else test_ok := '0'; report "Test NE.2: failed" severity note; end if;

        operand_A <= std_logic_vector(to_signed(16, operand_A'length));
        operand_B <= std_logic_vector(to_signed(7, operand_B'length));
        wait for CLK_period;

        if taken = '1' then report "Test NE.3: OK" severity note;
        else test_ok := '0'; report "Test NE.3: failed" severity note; end if;

        -- Test SGT -------------------------------------------------------------
        op_cmp <= BPF_JSGT;

        operand_A <= std_logic_vector(to_signed(23, operand_A'length));
        operand_B <= std_logic_vector(to_signed(23, operand_B'length));
        wait for CLK_period;

        if taken = '0' then report "Test SGT.1: OK" severity note;
        else test_ok := '0'; report "Test SGT.1: failed" severity note; end if;

        operand_A <= std_logic_vector(to_signed(14, operand_A'length));
        operand_B <= std_logic_vector(to_signed(15, operand_B'length));
        wait for CLK_period;

        if taken = '0' then report "Test SGT.2: OK" severity note;
        else test_ok := '0'; report "Test SGT.2: failed" severity note; end if;

        operand_A <= std_logic_vector(to_signed(16, operand_A'length));
        operand_B <= std_logic_vector(to_signed(7, operand_B'length));
        wait for CLK_period;

        if taken = '1' then report "Test SGT.3: OK" severity note;
        else test_ok := '0'; report "Test SGT.3: failed" severity note; end if;

        operand_A <= std_logic_vector(to_signed(-42, operand_A'length));
        operand_B <= std_logic_vector(to_signed(-52, operand_B'length));
        wait for CLK_period;

        if taken = '1' then report "Test SGT.4: OK" severity note;
        else test_ok := '0'; report "Test SGT.4: failed" severity note; end if;

        operand_A <= std_logic_vector(to_signed(-23, operand_A'length));
        operand_B <= std_logic_vector(to_signed(-17, operand_B'length));
        wait for CLK_period;

        if taken = '0' then report "Test SGT.5: OK" severity note;
        else test_ok := '0'; report "Test SGT.5: failed" severity note; end if;

        operand_A <= std_logic_vector(to_signed(42, operand_A'length));
        operand_B <= std_logic_vector(to_signed(-52, operand_B'length));
        wait for CLK_period;

        if taken = '1' then report "Test SGT.6: OK" severity note;
        else test_ok := '0'; report "Test SGT.6: failed" severity note; end if;

        operand_A <= std_logic_vector(to_signed(-23, operand_A'length));
        operand_B <= std_logic_vector(to_signed(17, operand_B'length));
        wait for CLK_period;

        if taken = '0' then report "Test SGT.7: OK" severity note;
        else test_ok := '0'; report "Test SGT.7: failed" severity note; end if;

        -- Test SGE -------------------------------------------------------------
        op_cmp <= BPF_JSGE;

        operand_A <= std_logic_vector(to_signed(23, operand_A'length));
        operand_B <= std_logic_vector(to_signed(23, operand_B'length));
        wait for CLK_period;

        if taken = '1' then report "Test SGE.1: OK" severity note;
        else test_ok := '0'; report "Test SGE.1: failed" severity note; end if;

        operand_A <= std_logic_vector(to_signed(14, operand_A'length));
        operand_B <= std_logic_vector(to_signed(15, operand_B'length));
        wait for CLK_period;

        if taken = '0' then report "Test SGE.2: OK" severity note;
        else test_ok := '0'; report "Test SGE.2: failed" severity note; end if;

        operand_A <= std_logic_vector(to_signed(16, operand_A'length));
        operand_B <= std_logic_vector(to_signed(7, operand_B'length));
        wait for CLK_period;

        if taken = '1' then report "Test SGE.3: OK" severity note;
        else test_ok := '0'; report "Test SGE.3: failed" severity note; end if;

        operand_A <= std_logic_vector(to_signed(-42, operand_A'length));
        operand_B <= std_logic_vector(to_signed(-52, operand_B'length));
        wait for CLK_period;

        if taken = '1' then report "Test SGE.4: OK" severity note;
        else test_ok := '0'; report "Test SGE.4: failed" severity note; end if;

        operand_A <= std_logic_vector(to_signed(-23, operand_A'length));
        operand_B <= std_logic_vector(to_signed(-17, operand_B'length));
        wait for CLK_period;

        if taken = '0' then report "Test SGE.5: OK" severity note;
        else test_ok := '0'; report "Test SGE.5: failed" severity note; end if;

        operand_A <= std_logic_vector(to_signed(42, operand_A'length));
        operand_B <= std_logic_vector(to_signed(-52, operand_B'length));
        wait for CLK_period;

        if taken = '1' then report "Test SGE.6: OK" severity note;
        else test_ok := '0'; report "Test SGE.6: failed" severity note; end if;

        operand_A <= std_logic_vector(to_signed(-23, operand_A'length));
        operand_B <= std_logic_vector(to_signed(17, operand_B'length));
        wait for CLK_period;

        if taken = '0' then report "Test SGE.7: OK" severity note;
        else test_ok := '0'; report "Test SGE.7: failed" severity note; end if;

        -- Test LT -------------------------------------------------------------
        op_cmp <= BPF_JLT;

        operand_A <= std_logic_vector(to_signed(23, operand_A'length));
        operand_B <= std_logic_vector(to_signed(23, operand_B'length));
        wait for CLK_period;

        if taken = '0' then report "Test LT.1: OK" severity note;
        else test_ok := '0'; report "Test LT.1: failed" severity note; end if;

        operand_A <= std_logic_vector(to_signed(14, operand_A'length));
        operand_B <= std_logic_vector(to_signed(15, operand_B'length));
        wait for CLK_period;

        if taken = '1' then report "Test LT.2: OK" severity note;
        else test_ok := '0'; report "Test LT.2: failed" severity note; end if;

        operand_A <= std_logic_vector(to_signed(16, operand_A'length));
        operand_B <= std_logic_vector(to_signed(7, operand_B'length));
        wait for CLK_period;

        if taken = '0' then report "Test LT.3: OK" severity note;
        else test_ok := '0'; report "Test LT.3: failed" severity note; end if;
            
        -- Test LE -------------------------------------------------------------
        op_cmp <= BPF_JLE;

        operand_A <= std_logic_vector(to_signed(23, operand_A'length));
        operand_B <= std_logic_vector(to_signed(23, operand_B'length));
        wait for CLK_period;

        if taken = '1' then report "Test LE.1: OK" severity note;
        else test_ok := '0'; report "Test LE.1: failed" severity note; end if;

        operand_A <= std_logic_vector(to_signed(14, operand_A'length));
        operand_B <= std_logic_vector(to_signed(15, operand_B'length));
        wait for CLK_period;

        if taken = '1' then report "Test LE.2: OK" severity note;
        else test_ok := '0'; report "Test LE.2: failed" severity note; end if;

        operand_A <= std_logic_vector(to_signed(16, operand_A'length));
        operand_B <= std_logic_vector(to_signed(7, operand_B'length));
        wait for CLK_period;

        if taken = '0' then report "Test LE.3: OK" severity note;
        else test_ok := '0'; report "Test LE.3: failed" severity note; end if;
            
        -- Test SLT -------------------------------------------------------------
        op_cmp <= BPF_JSLT;

        operand_A <= std_logic_vector(to_signed(23, operand_A'length));
        operand_B <= std_logic_vector(to_signed(23, operand_B'length));
        wait for CLK_period;

        if taken = '0' then report "Test SLT.1: OK" severity note;
        else test_ok := '0'; report "Test SLT.1: failed" severity note; end if;

        operand_A <= std_logic_vector(to_signed(14, operand_A'length));
        operand_B <= std_logic_vector(to_signed(15, operand_B'length));
        wait for CLK_period;

        if taken = '1' then report "Test SLT.2: OK" severity note;
        else test_ok := '0'; report "Test SLT.2: failed" severity note; end if;

        operand_A <= std_logic_vector(to_signed(16, operand_A'length));
        operand_B <= std_logic_vector(to_signed(7, operand_B'length));
        wait for CLK_period;

        if taken = '0' then report "Test SLT.3: OK" severity note;
        else test_ok := '0'; report "Test SLT.3: failed" severity note; end if;

        operand_A <= std_logic_vector(to_signed(-42, operand_A'length));
        operand_B <= std_logic_vector(to_signed(-52, operand_B'length));
        wait for CLK_period;

        if taken = '0' then report "Test SLT.4: OK" severity note;
        else test_ok := '0'; report "Test SLT.4: failed" severity note; end if;

        operand_A <= std_logic_vector(to_signed(-23, operand_A'length));
        operand_B <= std_logic_vector(to_signed(-17, operand_B'length));
        wait for CLK_period;

        if taken = '1' then report "Test SLT.5: OK" severity note;
        else test_ok := '0'; report "Test SLT.5: failed" severity note; end if;

        operand_A <= std_logic_vector(to_signed(42, operand_A'length));
        operand_B <= std_logic_vector(to_signed(-52, operand_B'length));
        wait for CLK_period;

        if taken = '0' then report "Test SLT.6: OK" severity note;
        else test_ok := '0'; report "Test SLT.6: failed" severity note; end if;

        operand_A <= std_logic_vector(to_signed(-23, operand_A'length));
        operand_B <= std_logic_vector(to_signed(17, operand_B'length));
        wait for CLK_period;

        if taken = '1' then report "Test SLT.7: OK" severity note;
        else test_ok := '0'; report "Test SLT.7: failed" severity note; end if;

        -- Test SLE -------------------------------------------------------------
        op_cmp <= BPF_JSLE;

        operand_A <= std_logic_vector(to_signed(23, operand_A'length));
        operand_B <= std_logic_vector(to_signed(23, operand_B'length));
        wait for CLK_period;

        if taken = '1' then report "Test SLE.1: OK" severity note;
        else test_ok := '0'; report "Test SLE.1: failed" severity note; end if;

        operand_A <= std_logic_vector(to_signed(14, operand_A'length));
        operand_B <= std_logic_vector(to_signed(15, operand_B'length));
        wait for CLK_period;

        if taken = '1' then report "Test SLE.2: OK" severity note;
        else test_ok := '0'; report "Test SLE.2: failed" severity note; end if;

        operand_A <= std_logic_vector(to_signed(16, operand_A'length));
        operand_B <= std_logic_vector(to_signed(7, operand_B'length));
        wait for CLK_period;

        if taken = '0' then report "Test SLE.3: OK" severity note;
        else test_ok := '0'; report "Test SLE.3: failed" severity note; end if;

        operand_A <= std_logic_vector(to_signed(-42, operand_A'length));
        operand_B <= std_logic_vector(to_signed(-52, operand_B'length));
        wait for CLK_period;

        if taken = '0' then report "Test SLE.4: OK" severity note;
        else test_ok := '0'; report "Test SLE.4: failed" severity note; end if;

        operand_A <= std_logic_vector(to_signed(-23, operand_A'length));
        operand_B <= std_logic_vector(to_signed(-17, operand_B'length));
        wait for CLK_period;

        if taken = '1' then report "Test SLE.5: OK" severity note;
        else test_ok := '0'; report "Test SLE.5: failed" severity note; end if;

        operand_A <= std_logic_vector(to_signed(42, operand_A'length));
        operand_B <= std_logic_vector(to_signed(-52, operand_B'length));
        wait for CLK_period;

        if taken = '0' then report "Test SLE.6: OK" severity note;
        else test_ok := '0'; report "Test SLE.6: failed" severity note; end if;

        operand_A <= std_logic_vector(to_signed(-23, operand_A'length));
        operand_B <= std_logic_vector(to_signed(17, operand_B'length));
        wait for CLK_period;

        if taken = '1' then report "Test SLE.7: OK" severity note;
        else test_ok := '0'; report "Test SLE.7: failed" severity note; end if;

        ------------------------------------------------------------------------
        if test_ok = '1' then report "== All tests OK!! ==" severity note;
		else report "== Some tests failed ==" severity note; end if;

        test_done <= '1';
        wait;
    end process;

end Behavioral;

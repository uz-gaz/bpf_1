--------------------------------------------------------------------------------
-- Project Name: A basic processor core for running BPF programs
-- Author:       Fernando Lahoz Bernad
--
-- Description:  Module to check if branch is taken based on the BPF comparison
--               operation code.
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

use work.bpf.all;

entity BPF_Branch_Checker is
    port (
        operand_A : in std_logic_vector (63 downto 0);
        operand_B : in std_logic_vector (63 downto 0);
        op_cmp : in std_logic_vector (3 downto 0);
        op_64b : in std_logic; -- '1' => 64 bit operand / '0' => 32 bit operand
        taken : out std_logic
    );
end BPF_Branch_Checker;

architecture Behavioral of BPF_Branch_Checker is

    signal eq, gt, ge, set, ne, sgt, sge, lt, le, slt, sle : std_logic;
    signal raw_lower_than : std_logic;
    signal same_sign : std_logic;

begin

    same_sign <= '1' when (op_64b = '1' and operand_A(63) = operand_B(63))
                       or (op_64b = '0' and operand_A(31) = operand_B(31))
                 else '0';
        

    raw_lower_than <= '1' when operand_A < operand_B else '0';
    
    eq <= '1' when operand_A = operand_B else '0';
    gt <= '1' when raw_lower_than = '0' and eq = '0' else '0';
    ge <= '1' when raw_lower_than = '0' else '0';
    set <= '1' when (operand_A and operand_B) /= (63 downto 0 => '0') else '0'; -- (A & B) != 0
    ne <= not eq;
    sgt <= '1' when (same_sign = '1' and gt = '1') or (same_sign = '0' and lt = '1') else '0';
    sge <= '1' when (same_sign = '1' and ge = '1') or (same_sign = '0' and le = '1') else '0';
    lt <= '1' when raw_lower_than = '1' else '0';
    le <= '1' when raw_lower_than = '1' or eq = '1' else '0';
    slt <= '1' when (same_sign = '1' and lt = '1') or (same_sign = '0' and gt = '1') else '0';
    sle <= '1' when (same_sign = '1' and le = '1') or (same_sign = '0' and ge = '1') else '0';

    taken <= eq  when op_cmp = BPF_JEQ  else
             gt  when op_cmp = BPF_JGT  else
             ge  when op_cmp = BPF_JGE  else
             set when op_cmp = BPF_JSET else
             ne  when op_cmp = BPF_JNE  else
             sgt when op_cmp = BPF_JSGT else
             sge when op_cmp = BPF_JSGE else
             lt  when op_cmp = BPF_JLT  else
             le  when op_cmp = BPF_JLE  else
             slt when op_cmp = BPF_JSLT else
             sle when op_cmp = BPF_JSLE else '0';

end Behavioral;

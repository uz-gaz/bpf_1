--------------------------------------------------------------------------------
-- Project Name: A basic processor core for running BPF programs
-- Author:       Fernando Lahoz Bernad
--
-- Description:  Exception unit for a BPF processor.
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

use work.bpf.all;

entity BPF_Exception_Unit is
    port (
        -- In order to force exception from external components
        IF_gen_exception : in std_logic;
        ID_gen_exception : in std_logic;
        EX_gen_exception : in std_logic;
        MEM_gen_exception : in std_logic;

        -- Instruction checking
        opcode : in std_logic_vector (7 downto 0);
        dst : in std_logic_vector (3 downto 0);
        src : in std_logic_vector (3 downto 0);
        offset : in std_logic_vector (15 downto 0);
        immediate : in std_logic_vector (31 downto 0);
        discard_ID : in std_logic;

        exception : out std_logic;
        exception_stage : out std_logic_vector (1 downto 0)
    );
end BPF_Exception_Unit;

architecture Behavioral of BPF_Exception_Unit is

    signal inst_class, mem_mode : std_logic_vector (2 downto 0);
    signal source : std_logic;
    signal inst_code : std_logic_vector (3 downto 0);
    signal mem_size : std_logic_vector (1 downto 0);
    signal fetch : std_logic;
    signal atomic_op : std_logic_vector (3 downto 0);

    signal src_writable, src_readable, src_is_zero : std_logic;
    signal dst_writable, dst_readable, dst_is_zero : std_logic;
    signal offset_is_zero, offset_is_one, mov_size_ok : std_logic;
    signal imm_is_zero, soft_is_atomic_op, is_atomic_op, is_atomic_fetch, is_atomic_cmpxchg, end_size_ok : std_logic;
    signal is_regular_op, is_signed_op, is_branch_op, atomic_mem_size_ok : std_logic;

    signal valid_instruction, forced_exception : std_logic;

begin

    ----------------------------------------------------------------------------
    -- Illegal instruction / Not implemented instruction -----------------------
    ----------------------------------------------------------------------------
    
    inst_class <= opcode(2 downto 0);
    source <= opcode(3);
    inst_code <= opcode(7 downto 4);
    mem_size <= opcode(4 downto 3);
    mem_mode <= opcode(7 downto 5);
    fetch <= immediate(0);
    atomic_op <= immediate(7 downto 4);

    -- Aux signals to simplify table of valid combinations

    src_writable <= '1' when src < "1010" else '0'; -- src < 10
    src_readable <= '1' when src <= "1010" else '0'; -- src <= 10
    src_is_zero <= '1' when src = "0000" else '0';
    
    dst_writable <= '1' when dst < "1010" else '0'; -- dst < 10
    dst_readable <= '1' when dst <= "1010" else '0'; -- dst <= 10
    dst_is_zero <= '1' when dst = "0000" else '0';

    offset_is_zero <= '1' when offset = x"0000" else '0';
    offset_is_one <= '1' when offset = x"0001" else '0';
    mov_size_ok <= '1' when ((offset(3) xor offset(4)) xor offset(5)) = '1'
                            and offset(15 downto 6) = "0000000000"
                            and offset(2 downto 0) = "000"
                       else '1' when offset_is_zero = '1'
                       else '0'; -- Only one value between 8, 16 and 32

    imm_is_zero <= '1' when immediate = (31 downto 0 => '0') else '0';
    soft_is_atomic_op <= '1' when (atomic_op = BPF_ADD or atomic_op = BPF_OR or
                                   atomic_op = BPF_AND or atomic_op = BPF_XOR)
                                  and immediate(31 downto 8) = 0
                             else '0';
    is_atomic_op <= '1' when soft_is_atomic_op = '1' and immediate(3 downto 0) = "0000" else '0';
    is_atomic_fetch <= '1' when (soft_is_atomic_op = '1' or atomic_op = BPF_XCHG) and immediate(3 downto 0) = "0001" else '0';
    is_atomic_cmpxchg <= '1' when immediate(3 downto 0) = "0001" and
                                  immediate(7 downto 4) = BPF_CMPXCHG and
                                  immediate(31 downto 8) = (23 downto 0 => '0')
                             else '0';
    end_size_ok <= '1' when ((immediate(4) xor immediate(5)) xor immediate(6)) = '1'
                             and immediate(31 downto 7) = (24 downto 0 => '0')
                             and immediate(3 downto 0) = "0000"
                       else '0'; -- Only one value between 16, 32 and 64
    
    is_regular_op <= '1' when inst_code = BPF_ADD or inst_code = BPF_SUB or
                              inst_code = BPF_MUL or inst_code = BPF_DIV or
                              inst_code = BPF_MOD or inst_code = BPF_OR or
                              inst_code = BPF_AND or inst_code = BPF_LSH or
                              inst_code = BPF_RSH or inst_code = BPF_NEG or
                              inst_code = BPF_XOR or inst_code = BPF_ARSH
                       else '0';

    is_signed_op <= '1' when inst_code = BPF_DIV or inst_code = BPF_MOD else '0';

    is_branch_op <= '1' when inst_code = BPF_JEQ or inst_code = BPF_JNE or
                             inst_code = BPF_JGT or inst_code = BPF_JGE or
                             inst_code = BPF_JSGT or inst_code = BPF_JSGE or
                             inst_code = BPF_JLT or inst_code = BPF_JLE or
                             inst_code = BPF_JSLT or inst_code = BPF_JSLE or
                             inst_code = BPF_JSET
                        else '0';
    
    atomic_mem_size_ok <= '1' when mem_size = BPF_SIZE64 or mem_size = BPF_SIZE32 else '0';


    valid_instruction <=  -- Table of valid combinations
        '1' when inst_class = BPF_LD    and mem_size = BPF_SIZE64 and mem_mode = BPF_IMM and dst_writable = '1' and src_is_zero = '1' and offset_is_zero = '1' else
        '1' when inst_class = BPF_LDX   and mem_mode = BPF_MEM and dst_writable = '1' and src_readable = '1' and imm_is_zero = '1' else
        '1' when inst_class = BPF_LDX   and mem_mode = BPF_MEMSX and dst_writable = '1' and src_readable = '1' and imm_is_zero = '1' else
        '1' when inst_class = BPF_ST    and mem_mode = BPF_MEM and dst_readable = '1' and src_readable = '1' else
        '1' when inst_class = BPF_STX   and mem_mode = BPF_MEM and dst_readable = '1' and src_readable = '1' and imm_is_zero = '1' else
        '1' when inst_class = BPF_STX   and atomic_mem_size_ok = '1' and mem_mode = BPF_ATOMIC and dst_readable = '1' and src_readable = '1' and is_atomic_op = '1' else
        '1' when inst_class = BPF_STX   and atomic_mem_size_ok = '1' and mem_mode = BPF_ATOMIC and dst_readable = '1' and src_writable = '1' and is_atomic_fetch = '1' else
        '1' when inst_class = BPF_STX   and atomic_mem_size_ok = '1' and mem_mode = BPF_ATOMIC and dst_readable = '1' and src_readable = '1' and is_atomic_cmpxchg = '1' else
        '1' when inst_class = BPF_ALU   and is_regular_op = '1' and dst_writable = '1' and src_readable = '1' and offset_is_zero = '1' else
        '1' when inst_class = BPF_ALU   and is_signed_op = '1' and dst_writable = '1' and src_readable = '1' and offset_is_one = '1' else
        '1' when inst_class = BPF_ALU   and inst_code = BPF_MOV and dst_writable = '1' and src_readable = '1' and mov_size_ok = '1' else
        '1' when inst_class = BPF_ALU   and inst_code = BPF_END and dst_writable = '1' and src_readable = '1' and offset_is_zero = '1' and end_size_ok = '1' else
        '1' when inst_class = BPF_ALU64 and is_regular_op = '1' and dst_writable = '1' and src_readable = '1' and offset_is_zero = '1' else
        '1' when inst_class = BPF_ALU64 and is_signed_op = '1' and dst_writable = '1' and src_readable = '1' and offset_is_one = '1' else
        '1' when inst_class = BPF_ALU64 and inst_code = BPF_MOV and dst_writable = '1' and src_readable = '1' and mov_size_ok = '1' else
        '1' when inst_class = BPF_ALU64 and source = '0' and inst_code = BPF_END and dst_writable = '1' and src_readable = '1' and offset_is_zero = '1' and end_size_ok = '1' else
        '1' when inst_class = BPF_JMP   and source = '0' and inst_code = BPF_JA and dst_is_zero = '1' and src_is_zero = '1' and imm_is_zero = '1' else
        '1' when inst_class = BPF_JMP   and is_branch_op = '1' and dst_readable = '1' and src_readable = '1' else
        '1' when inst_class = BPF_JMP   and source = '0' and inst_code = BPF_JEXIT and dst_is_zero = '1' and src_is_zero = '1' and offset_is_zero = '1' and imm_is_zero = '1' else
        '1' when inst_class = BPF_JMP   and source = '0' and inst_code = BPF_JCALL and dst_is_zero = '1' and src_is_zero = '1' and offset_is_zero = '1' else
        '1' when inst_class = BPF_JMP32 and source = '0' and inst_code = BPF_JA and dst_is_zero = '1' and src_is_zero = '1' and offset_is_zero = '1' else
        '1' when inst_class = BPF_JMP32 and is_branch_op = '1' and dst_readable = '1' and src_readable = '1' else
        discard_ID; -- Do not throw exception if ID instruction is being discarded

    ----------------------------------------------------------------------------
    -- Forced exception --------------------------------------------------------
    ----------------------------------------------------------------------------

    forced_exception <= IF_gen_exception or ID_gen_exception or EX_gen_exception or MEM_gen_exception;

    
    ----------------------------------------------------------------------------
    ----------------------------------------------------------------------------

    exception_stage <= BPF_STAGE_MEM when MEM_gen_exception = '1' else
                       BPF_STAGE_EX when EX_gen_exception = '1' else
                       BPF_STAGE_ID when valid_instruction = '0' or ID_gen_exception = '1' else
                       BPF_STAGE_IF when IF_gen_exception = '1' else
                       BPF_STAGE_IF;
    
    exception <= '1' when valid_instruction = '0' else
                 '1' when forced_exception = '1' else
                 '0';

end Behavioral;
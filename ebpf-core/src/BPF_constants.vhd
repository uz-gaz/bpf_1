library ieee;
use ieee.std_logic_1164.all;

package bpf is
    -- BPF sizes as coded inside opcode field of MEM instructions
    constant BPF_SIZE8 : std_logic_vector := "10";
    constant BPF_SIZE16 : std_logic_vector := "01";
    constant BPF_SIZE32 : std_logic_vector := "00";
    constant BPF_SIZE64 : std_logic_vector := "11";

    -- BPF jump operations
    constant BPF_JA : std_logic_vector := "0000";
    constant BPF_JEQ : std_logic_vector := "0001";
    constant BPF_JGT : std_logic_vector := "0010";
    constant BPF_JGE : std_logic_vector := "0011";
    constant BPF_JSET : std_logic_vector := "0100";
    constant BPF_JNE : std_logic_vector := "0101";
    constant BPF_JSGT : std_logic_vector := "0110";
    constant BPF_JSGE : std_logic_vector := "0111";
    constant BPF_JCALL : std_logic_vector := "1000";
    constant BPF_JEXIT : std_logic_vector := "1001";
    constant BPF_JLT : std_logic_vector := "1010";
    constant BPF_JLE : std_logic_vector := "1011";
    constant BPF_JSLT : std_logic_vector := "1100";
    constant BPF_JSLE : std_logic_vector := "1101";

    -- BPF alu operations
    constant BPF_ADD : std_logic_vector := "0000";
    constant BPF_SUB : std_logic_vector := "0001";
    constant BPF_MUL : std_logic_vector := "0010";
    constant BPF_DIV : std_logic_vector := "0011";
    constant BPF_OR : std_logic_vector := "0100";
    constant BPF_AND : std_logic_vector := "0101";
    constant BPF_LSH : std_logic_vector := "0110";
    constant BPF_RSH : std_logic_vector := "0111";
    constant BPF_NEG : std_logic_vector := "1000";
    constant BPF_MOD : std_logic_vector := "1001";
    constant BPF_XOR : std_logic_vector := "1010";
    constant BPF_MOV : std_logic_vector := "1011";
    constant BPF_ARSH : std_logic_vector := "1100";
    constant BPF_END : std_logic_vector := "1101";

    -- BPF atomic operations
    constant BPF_XCHG : std_logic_vector := "1110";
    constant BPF_CMPXCHG : std_logic_vector := "1111";


    -- BPF instruction class
    constant BPF_LD : std_logic_vector := "000";
    constant BPF_LDX : std_logic_vector := "001";
    constant BPF_ST : std_logic_vector := "010";
    constant BPF_STX : std_logic_vector := "011";
    constant BPF_ALU : std_logic_vector := "100";
    constant BPF_JMP : std_logic_vector := "101";
    constant BPF_JMP32 : std_logic_vector := "110";
    constant BPF_ALU64 : std_logic_vector := "111";

    -- BPF instruction mem mode
    constant BPF_IMM : std_logic_vector := "000";
    constant BPF_MEM : std_logic_vector := "011";
    constant BPF_MEMSX : std_logic_vector := "100";
    constant BPF_ATOMIC : std_logic_vector := "110";


    constant BPF_TO_LE : std_logic := '0';
    constant BPF_TO_BE : std_logic := '1';

    constant BPF_FROM_IMM : std_logic := '0';
    constant BPF_FROM_REG : std_logic := '1';

    -- Forwarding origin
    constant BPF_NO_FW : std_logic_vector := "00";
    constant BPF_FW_FROM_MEM : std_logic_vector := "01";
    constant BPF_FW_FROM_WB_M : std_logic_vector := "10";
    constant BPF_FW_FROM_WB_E : std_logic_vector := "11";


    -- Stages that can produce exception
    constant BPF_STAGE_IF : std_logic_vector := "00";
    constant BPF_STAGE_ID : std_logic_vector := "01";
    constant BPF_STAGE_EX : std_logic_vector := "10";
    constant BPF_STAGE_MEM : std_logic_vector := "11";


    -- Base address for AXI peripheral
    constant BPF_MEM_INST_BASE_U16 : std_logic_vector :=     x"0000";
    constant BPF_MEM_INST_BASE_U32 : std_logic_vector := x"00000000";

    constant BPF_MEM_PACKET_BASE_U16 : std_logic_vector :=     x"8000";
    constant BPF_MEM_PACKET_BASE_U32 : std_logic_vector := x"00008000";

    constant BPF_MEM_STACK_BASE_U16 : std_logic_vector :=     x"8800";
    constant BPF_MEM_STACK_BASE_U32 : std_logic_vector := x"00008800";

    constant BPF_MEM_EOT_U16 : std_logic_vector :=     x"8FFF";
    constant BPF_MEM_EOT_U32 : std_logic_vector := x"00008FFF";

    constant BPF_MEM_SHARED_BASE_U16 : std_logic_vector :=     x"9000";
    constant BPF_MEM_SHARED_BASE_U32 : std_logic_vector := x"00009000";

    constant BPF_CORE_CTRL_U16 : std_logic_vector :=     x"8A00";
    constant BPF_CORE_CTRL_U32 : std_logic_vector := x"00008A00";

    constant BPF_CORE_INPUT_U16 : std_logic_vector :=     x"8A08";
    constant BPF_CORE_INPUT_U32 : std_logic_vector := x"00008A08";

    constant BPF_CORE_OUTPUT_U16 : std_logic_vector :=     x"8A10";
    constant BPF_CORE_OUTPUT_U32 : std_logic_vector := x"00008A10";

    constant BPF_MAP_BASE_U16 : std_logic_vector :=     x"8A18";
    constant BPF_MAP_BASE_U32 : std_logic_vector := x"00008A18";

    constant BPF_FRAME_POINTER : std_logic_vector := x"89F8";

end package;
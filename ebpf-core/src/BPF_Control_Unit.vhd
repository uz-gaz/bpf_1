--------------------------------------------------------------------------------
-- Project Name: A basic processor core for running BPF programs
-- Author:       Fernando Lahoz Bernad
--
-- Description:  Control unit for a BPF processor.
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

use work.bpf.all;

entity BPF_Control_Unit is
    port (
        opcode : in std_logic_vector (7 downto 0);
        dst : in std_logic_vector (3 downto 0);
        src : in std_logic_vector (3 downto 0);
        offset : in std_logic_vector (15 downto 0);
        immediate : in std_logic_vector (31 downto 0);
        discard : in std_logic;

        ID_num_params : in std_logic_vector (2 downto 0);

        -- Producer on EX info
        EX_reg_write : in std_logic;
        EX_write_r0 : in std_logic;
        EX_mem_to_reg : in std_logic;
        EX_call : in std_logic;
        EX_dst : in std_logic_vector (3 downto 0);
    
        ID_jump : out std_logic;
        ID_branch : out std_logic;
        ID_32b_jump : out std_logic;
        ID_64b_imm : out std_logic;
        ID_alu64 : out std_logic;
        ID_addr_calc : out std_logic;
        ID_write_en : out std_logic;
        ID_read_en : out std_logic;
        ID_force_imm : out std_logic;
        ID_sign_ext : out std_logic;
        ID_value_size : out std_logic_vector (1 downto 0);
        ID_mem_to_reg : out std_logic;
        ID_reg_write : out std_logic;
        ID_discard_IF : out std_logic;
        ID_finish : out std_logic;
        ID_atomic : out std_logic;
        ID_write_r0 : out std_logic;
        ID_alu_en : out std_logic;
        ID_call : out std_logic;

        block_ID : out std_logic
    );
end BPF_Control_Unit;

architecture Behavioral of BPF_Control_Unit is

    component BPF_Hazard_Unit is
        port (
            -- Consumer info
            ID_use_r0 : in std_logic;
            ID_use_dst : in std_logic;
            ID_use_src : in std_logic;
            ID_dst : in std_logic_vector (3 downto 0);
            ID_src : in std_logic_vector (3 downto 0);
            ID_num_params : in std_logic_vector (2 downto 0);
            ID_call : in std_logic;

            -- Producer on EX info
            EX_reg_write : in std_logic;
            EX_write_r0 : in std_logic;
            EX_mem_producer : in std_logic;
            EX_dst : in std_logic_vector (3 downto 0);

            -- Output
            block_ID : out std_logic -- and so all previous stages, then discard ID_EX buffer
        );
    end component;

    signal inst_class, mem_mode : std_logic_vector (2 downto 0);
    signal source : std_logic;
    signal inst_code : std_logic_vector (3 downto 0);
    signal mem_size : std_logic_vector (1 downto 0);
    signal fetch : std_logic;
    signal atomic_op : std_logic_vector (3 downto 0);

    signal is_jump : std_logic;
    signal movsx_size : std_logic_vector (1 downto 0);


    signal sig_jump : std_logic;
    signal sig_branch : std_logic;
    signal sig_32b_jump : std_logic;
    signal sig_64b_imm : std_logic;
    signal sig_alu64 : std_logic;
    signal sig_addr_calc : std_logic;
    signal sig_write_en : std_logic;
    signal sig_read_en : std_logic;
    signal sig_force_imm : std_logic;
    signal sig_sign_ext : std_logic;
    signal sig_value_size : std_logic_vector (1 downto 0);
    signal sig_mem_to_reg : std_logic;
    signal sig_reg_write : std_logic;
    signal sig_discard_IF : std_logic;
    signal sig_finish : std_logic;
    signal sig_atomic : std_logic;
    signal sig_write_r0 : std_logic;
    signal sig_alu_en : std_logic;
    signal sig_call : std_logic;

    signal sig_use_r0 : std_logic;
    signal sig_use_dst : std_logic;
    signal sig_use_src : std_logic;


    signal sig_block_ID, enable_ID : std_logic;


    signal EX_mem_producer : std_logic;

begin

    inst_class <= opcode(2 downto 0);
    source <= opcode(3);
    inst_code <= opcode(7 downto 4);
    mem_size <= opcode(4 downto 3);
    mem_mode <= opcode(7 downto 5);
    fetch <= immediate(0);
    atomic_op <= immediate(7 downto 4);


    movsx_size <= BPF_SIZE8 when offset(3) = '1' else
                  BPF_SIZE16 when offset(4) = '1' else
                  BPF_SIZE32 when offset(5) = '1' else BPF_SIZE64;

    is_jump <= '1' when inst_class = BPF_JMP or inst_class = BPF_JMP32 else '0';


    sig_jump <= '1' when is_jump = '1' and inst_code = BPF_JA else '0';

    sig_branch <= '1' when is_jump = '1' and inst_code /= BPF_JA and inst_code /= BPF_JCALL and inst_code /= BPF_JEXIT else '0';

    sig_32b_jump <= '1' when inst_class = BPF_JMP32 and inst_code = BPF_JA else '0';

    sig_64b_imm <= '1' when inst_class = BPF_LD else '0';

    sig_alu64 <= '0' when inst_class = BPF_ALU and inst_code /= BPF_END else
                '0' when inst_class = BPF_JMP32 else '1';
    
    sig_addr_calc <= '1' when inst_class = BPF_LDX or inst_class = BPF_ST or inst_class = BPF_STX else '0';

    sig_write_en <= '1' when inst_class = BPF_ST or inst_class = BPF_STX else '0';

    sig_read_en <= '1' when inst_class = BPF_LDX or (inst_class = BPF_STX and fetch = '1') else '0';

    sig_force_imm <= '1' when inst_class = BPF_LD or inst_class = BPF_ST else
                    '1' when ((inst_class = BPF_ALU and source = BPF_TO_BE) or inst_class = BPF_ALU64) and inst_code = BPF_END else '0';

    sig_sign_ext <= '1' when inst_class = BPF_LDX and mem_mode = BPF_MEMSX else
                   '1' when (inst_class = BPF_ALU or inst_class = BPF_ALU64) and inst_code = BPF_MOV else '0';


    sig_value_size <= BPF_SIZE64 when inst_class = BPF_LD else
                     mem_size when inst_class = BPF_LDX or inst_class = BPF_ST or inst_class = BPF_STX else
                     movsx_size when (inst_class = BPF_ALU or inst_class = BPF_ALU64) and inst_code = BPF_MOV else BPF_SIZE64;

    sig_mem_to_reg <= '1' when inst_class = BPF_LDX or inst_class = BPF_ST or inst_class = BPF_STX else '0';

    sig_reg_write <= '0' when is_jump = '1' or inst_class = BPF_ST else
                     '0' when inst_class = BPF_ALU and inst_code = BPF_END and source = '0' else -- LE is a NOOP 
                     '0' when inst_class = BPF_STX and (mem_mode = BPF_MEM or fetch = '0') else
                     '0' when inst_class = BPF_STX and mem_mode = BPF_ATOMIC and atomic_op = BPF_CMPXCHG else '1';

    sig_discard_IF <= '1' when inst_class = BPF_LD else
                      '1' when inst_class = BPF_JMP and inst_code = BPF_JCALL else '0';

    sig_finish <= '1' when inst_class = BPF_JMP and inst_code = BPF_JEXIT else '0';

    sig_atomic <= '1' when inst_class = BPF_STX and mem_mode = BPF_ATOMIC else '0';

    sig_write_r0 <= '1' when inst_class = BPF_STX and mem_mode = BPF_ATOMIC and atomic_op = BPF_CMPXCHG else
                    '1' when inst_class = BPF_JMP and inst_code = BPF_JCALL else '0';

    sig_alu_en <= '1' when (inst_class = BPF_ALU and inst_code /= BPF_END) or inst_class = BPF_ALU64 else '0';

    sig_call <= '1' when inst_class = BPF_JMP and inst_code = BPF_JCALL else '0';


    sig_use_r0  <= '1' when sig_write_r0 = '1' and sig_atomic = '1' else '0';

    sig_use_dst <= '1' when sig_branch = '1' else
                   '0' when sig_64b_imm = '1' else
                   '0' when sig_alu_en = '1' and inst_code = BPF_MOV else
                   '1' when sig_alu_en = '1' else
                   '1' when sig_addr_calc = '1' else '0';

    sig_use_src <= '1' when sig_branch = '1' and source = BPF_FROM_REG else
                   '0' when sig_64b_imm = '1' else
                   '0' when sig_alu_en = '1' and inst_code = BPF_END else
                   '0' when sig_alu_en = '1' and inst_code = BPF_NEG else
                   '1' when sig_alu_en = '1' and source = BPF_FROM_REG else
                   '1' when sig_addr_calc = '1' and sig_force_imm = '0' else '0';

    data_hazard_unit_block: BPF_Hazard_Unit
        port map (
            -- Consumer info
            ID_use_r0 => sig_use_r0,
            ID_use_dst => sig_use_dst,
            ID_use_src => sig_use_src,
            ID_dst => dst,
            ID_src => src,
            ID_num_params => ID_num_params,
            ID_call => sig_call,
    
            -- Producer on EX info
            EX_reg_write => EX_reg_write,
            EX_write_r0 => EX_write_r0,
            EX_mem_producer => EX_mem_producer,
            EX_dst => EX_dst,

            block_ID => sig_block_ID
        );
        
    EX_mem_producer <= EX_mem_to_reg or EX_call;

    enable_ID <= '1' when discard = '0' else '0';

    -- Discard if necessary
    ID_jump <=       sig_jump       when enable_ID = '1' else '0';
    ID_branch <=     sig_branch     when enable_ID = '1' else '0';
    ID_32b_jump <=   sig_32b_jump   when enable_ID = '1' else '0';
    ID_64b_imm <=    sig_64b_imm    when enable_ID = '1' else '0';
    ID_alu64 <=      sig_alu64      when enable_ID = '1' else '0';
    ID_addr_calc <=  sig_addr_calc  when enable_ID = '1' else '0';
    ID_write_en <=   sig_write_en   when enable_ID = '1' else '0';
    ID_read_en <=    sig_read_en    when enable_ID = '1' else '0';
    ID_force_imm <=  sig_force_imm  when enable_ID = '1' else '0';
    ID_sign_ext <=   sig_sign_ext   when enable_ID = '1' else '0';
    ID_value_size <= sig_value_size when enable_ID = '1' else BPF_SIZE64;
    ID_mem_to_reg <= sig_mem_to_reg when enable_ID = '1' else '0';
    ID_reg_write <=  sig_reg_write  when enable_ID = '1' else '0';
    ID_discard_IF <= sig_discard_IF when enable_ID = '1' else '0';
    ID_finish <=     sig_finish     when enable_ID = '1' else '0';
    ID_atomic <=     sig_atomic     when enable_ID = '1' else '0';
    ID_write_r0 <=   sig_write_r0   when enable_ID = '1' else '0';
    ID_alu_en <=     sig_alu_en     when enable_ID = '1' else '0'; 
    ID_call <=       sig_call       when enable_ID = '1' else '0';

    block_ID <= sig_block_ID when discard = '0' else '0';

end Behavioral;
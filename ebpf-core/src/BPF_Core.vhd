--------------------------------------------------------------------------------
-- Project Name: A basic processor core for running BPF programs
-- Author:       Fernando Lahoz Bernad
--
-- Description:  Data path for a BPF processor that implements:
--                 - Forwarding on EX stage
--                 - Exceptions
--                 - Buffer, registers and memory writes effective on high edge
--                 - WB stage effective on low edge
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

use work.bpf.all;

entity BPF_Core is
    port (
        clk : in std_logic;

        -- Signals to test exception control
        --IF_gen_exception : in std_logic;
        --ID_gen_exception : in std_logic;
        --EX_gen_exception : in std_logic;
        --MEM_gen_exception : in std_logic;

        -- Signals to control execution
        CORE_reset : in std_logic;
        CORE_sleep : in std_logic;
        CORE_reg_dst : in std_logic_vector (3 downto 0);
        CORE_reg_write : in std_logic;
        CORE_reg_input : in std_logic_vector (63 downto 0);

        CORE_sleeping : out std_logic;
        CORE_finish : out std_logic;
        CORE_exception : out std_logic;
        CORE_output : out std_logic_vector (63 downto 0);

        -- Signals to communicate with data memory
        DMEM_addr : out std_logic_vector (63 downto 0);
        DMEM_input : out std_logic_vector (63 downto 0);
        DMEM_write_en : out std_logic;
        DMEM_read_en : out std_logic;
        DMEM_size : out std_logic_vector (1 downto 0);

        DMEM_atomic : out std_logic;
        DMEM_op : out std_logic_vector (3 downto 0);
        DMEM_cmpxchg_token : out std_logic_vector (63 downto 0);
        
        DMEM_ready : in std_logic;
        DMEM_error : in std_logic;
        DMEM_output : in std_logic_vector (63 downto 0);

        -- Signals to communicate with instruction memory
        IMEM_addr : out std_logic_vector (11 downto 0);
        IMEM_read_en : out std_logic;
        IMEM_output : in std_logic_vector (63 downto 0);

        -- Signals to communicate with map interface
          -- MAP Unit bus
        HFU_MAP_ena : out std_logic;
        HFU_MAP_id : out std_logic_vector(0 downto 0);
        HFU_MAP_output : in std_logic_vector(31 downto 0);

        HFU_MAP_req : out std_logic;
        HFU_MAP_granted : in std_logic;
        HFU_MAP_bus_frame : out std_logic
    );
end BPF_Core;

architecture Behavioral of BPF_Core is

    component Register_N is
        generic ( SIZE : positive := 64 );
        port (
            clk : in std_logic;
            reset : in std_logic;
            load : in std_logic;
            input : in std_logic_vector (SIZE - 1 downto 0);
            output : out std_logic_vector (SIZE - 1 downto 0)
        );
    end component;

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
            get_params : in std_logic_vector (1 downto 0);
            output_A : out std_logic_vector (63 downto 0);
            output_B : out std_logic_vector (63 downto 0);
            output_R0 : out std_logic_vector (63 downto 0)
        );
    end component;

    component BPF_ALU is
        port (
            clk : in std_logic;
            reset : in std_logic;
            alu_en : in std_logic;
            operand_A : in std_logic_vector (63 downto 0);
            operand_B : in std_logic_vector (63 downto 0);
            op_alu : in std_logic_vector (3 downto 0);
            op_64b : in std_logic;
            signed_alu : in std_logic;
            sx_size : in std_logic_vector (1 downto 0);
            alu_ready : out std_logic;
            output : out std_logic_vector (63 downto 0)
        );
    end component;

    component BPF_Branch_Checker is
        port (
            operand_A : in std_logic_vector (63 downto 0);
            operand_B : in std_logic_vector (63 downto 0);
            op_cmp : in std_logic_vector (3 downto 0);
            op_64b : in std_logic;
            taken : out std_logic
        );
    end component;

    component BPF_Byte_Mask is
        port (
            input : in std_logic_vector (63 downto 0);
            size : in std_logic_vector (1 downto 0);
            sign_extend : in std_logic;
            output : out std_logic_vector (63 downto 0)
        );
    end component;

    -- Control Unit --
    component BPF_Control_Unit is
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
    end component;

    -- Forwarding unit --
    component BPF_Forwarding_Unit is
        port (
            EX_dst : in std_logic_vector (3 downto 0);
            EX_src : in std_logic_vector (3 downto 0);
            EX_call : in std_logic; 

            MEM_reg_write : in std_logic;
            MEM_write_r0 : in std_logic;
            MEM_dst : in std_logic_vector (3 downto 0);
    
            WB_reg_write : in std_logic;
            WB_write_r0 : in std_logic;
            WB_mem_to_reg : in std_logic;
            WB_dst : in std_logic_vector (3 downto 0);

            EX_fw_A_from : out std_logic_vector (1 downto 0);
            EX_fw_B_from : out std_logic_vector (1 downto 0);
            EX_fw_token_from : out std_logic_vector (1 downto 0)
        );
    end component;

    -- Exception unit --
    component BPF_Exception_Unit is
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
    end component;

    -- HFU --
    component BPF_Helper_Functions_Unit is
        port (
            clk : in std_logic;
            reset : in std_logic;
    
            function_id : in std_logic_vector (31 downto 0);
            go_ID : in std_logic; -- Must be ON the cycle call is on ID stage and can continue to EX
            go_EX : in std_logic; -- Must be ON the cycle call is on EX stage and can continue to MEM
    
            num_params : out std_logic_vector (2 downto 0); -- Info for Hazard Unit
            error_function_id : out std_logic; -- Info for Exception Unit
    
            -- Five function parameters
            p1, p2, p3, p4, p5 : in std_logic_vector (63 downto 0);
    
            await_EX : out std_logic;
            await_MEM : out std_logic;
            error_execution : out std_logic; -- Info for Exception Unit
            result : out std_logic_vector (63 downto 0);

            -- MAP Unit bus
            HFU_MAP_ena : out std_logic;
            HFU_MAP_id : out std_logic_vector(0 downto 0);
            HFU_MAP_output : in std_logic_vector(31 downto 0);

            HFU_MAP_req : out std_logic;
            HFU_MAP_granted : in std_logic;
            HFU_MAP_bus_frame : out std_logic
        );
    end component;
    
    component Buffer_IF_ID is
        port (
            clk : in std_logic;
            reset : in std_logic;
            load : in std_logic;

            IF_IR : in std_logic_vector (63 downto 0);
            IF_PC1 : in std_logic_vector (11 downto 0);
            IF_discard : in std_logic;
            IF_call_2 : in std_logic;

            ID_IR : out std_logic_vector (63 downto 0);
            ID_PC1 : out std_logic_vector (11 downto 0);
            ID_discard : out std_logic;
            ID_call_2 : out std_logic
        );
    end component;

    component Buffer_ID_EX is
        port (
            clk : in std_logic;
            reset : in std_logic;
            load : in std_logic;
            ID_branch : in std_logic;
            ID_64b_imm : in std_logic;
            ID_alu64 : in std_logic;
            ID_addr_calc : in std_logic;
            ID_write_en : in std_logic;
            ID_read_en : in std_logic;
            ID_force_imm : in std_logic;
            ID_sign_ext : in std_logic;
            ID_value_size : in std_logic_vector (1 downto 0);
            ID_mem_to_reg : in std_logic;
            ID_reg_write : in std_logic;
            ID_atomic : in std_logic;
            ID_write_r0 : in std_logic;
            ID_alu_en : in std_logic;
            ID_call : in std_logic;

            ID_PC_taken : in std_logic_vector (63 downto 0);
            ID_A : in std_logic_vector (63 downto 0);
            ID_B : in std_logic_vector (63 downto 0);
            ID_imm32 : in std_logic_vector (31 downto 0);
            ID_offset : in std_logic_vector (15 downto 0);
            ID_opcode : in std_logic_vector (7 downto 0);
            ID_dst : in std_logic_vector (3 downto 0);
            ID_src : in std_logic_vector (3 downto 0);

            EX_branch : out std_logic;
            EX_64b_imm : out std_logic;
            EX_alu64 : out std_logic;
            EX_addr_calc : out std_logic;
            EX_write_en : out std_logic;
            EX_read_en : out std_logic;
            EX_force_imm : out std_logic;
            EX_sign_ext : out std_logic;
            EX_value_size : out std_logic_vector (1 downto 0);
            EX_mem_to_reg : out std_logic;
            EX_reg_write : out std_logic;
            EX_atomic : out std_logic;
            EX_write_r0 : out std_logic;
            EX_alu_en : out std_logic;
            EX_call : out std_logic;

            EX_PC_taken : out std_logic_vector (63 downto 0);
            EX_A : out std_logic_vector (63 downto 0);
            EX_B : out std_logic_vector (63 downto 0);
            EX_imm32 : out std_logic_vector (31 downto 0);
            EX_offset : out std_logic_vector (15 downto 0);
            EX_opcode : out std_logic_vector (7 downto 0);
            EX_dst : out std_logic_vector (3 downto 0);
            EX_src : out std_logic_vector (3 downto 0)
        );
    end component;

    component Buffer_EX_MEM is
        port (
            clk : in std_logic;
            reset : in std_logic;
            load : in std_logic;
            EX_write_en : in std_logic;
            EX_read_en : in std_logic;
            EX_sign_ext : in std_logic;
            EX_value_size : in std_logic_vector (1 downto 0);
            EX_mem_to_reg : in std_logic;
            EX_reg_write : in std_logic;
            EX_atomic : in std_logic;
            EX_write_r0 : in std_logic;
            EX_call : in std_logic;

            EX_cmpxchg_token : in std_logic_vector (63 downto 0);
            EX_data : in std_logic_vector (63 downto 0);
            EX_C : in std_logic_vector (63 downto 0);
            EX_atomic_op : in std_logic_vector (3 downto 0);
            EX_dst : in std_logic_vector (3 downto 0);

            MEM_write_en : out std_logic;
            MEM_read_en : out std_logic;
            MEM_sign_ext : out std_logic;
            MEM_value_size : out std_logic_vector (1 downto 0);
            MEM_mem_to_reg : out std_logic;
            MEM_reg_write : out std_logic;
            MEM_atomic : out std_logic;
            MEM_write_r0 : out std_logic;
            MEM_call : out std_logic;

            MEM_cmpxchg_token : out std_logic_vector (63 downto 0);
            MEM_data : out std_logic_vector (63 downto 0);
            MEM_C : out std_logic_vector (63 downto 0);
            MEM_atomic_op : out std_logic_vector (3 downto 0);
            MEM_dst : out std_logic_vector (3 downto 0)
        );
    end component;

    component Buffer_MEM_WB is
        port (
            clk : in std_logic;
            reset : in std_logic;
            load : in std_logic;
            MEM_mem_to_reg : in std_logic;
            MEM_reg_write : in std_logic;
            MEM_sign_ext : in std_logic;
            MEM_value_size : in std_logic_vector (1 downto 0);
            MEM_write_r0 : in std_logic;
            MEM_ex_value : in std_logic_vector (63 downto 0);
            MEM_dst : in std_logic_vector (3 downto 0);
            WB_mem_to_reg : out std_logic;
            WB_reg_write : out std_logic;
            WB_sign_ext : out std_logic;
            WB_value_size : out std_logic_vector (1 downto 0);
            WB_write_r0 : out std_logic;
            WB_ex_value : out std_logic_vector (63 downto 0);
            WB_dst : out std_logic_vector (3 downto 0)
        );
    end component;

    signal reset : std_logic;
    signal load_PC, load_IF, load_ID, load_EX, load_MEM : std_logic;

    signal block_IF, block_ID, block_EX, block_MEM : std_logic;

    -- IF signals
    signal IF_PC_input, IF_PC, IF_PC_plus_1 : std_logic_vector (11 downto 0);
    signal IF_IR, ID_A, ID_B, ID_R0 : std_logic_vector (63 downto 0);
    signal IF_imm32 : std_logic_vector (31 downto 0);

    -- ID signals
    signal ID_discard_IF, ID_discard, ID_jump_or_taken_branch, ID_discard_ID : std_logic;
    signal ID_PC_plus_1, ID_jump_offset, ID_PC_taken, PC_taken : std_logic_vector (11 downto 0);
    signal ID_IR, ID_PC_taken_or_cmpxchg_token : std_logic_vector (63 downto 0);

    signal ID_opcode : std_logic_vector (7 downto 0);
    signal ID_dst_reg, ID_src_reg : std_logic_vector (3 downto 0);
    signal ID_offset : std_logic_vector (15 downto 0);
    signal ID_imm32 : std_logic_vector (31 downto 0);

    signal ID_jump, ID_branch, ID_32b_jump, ID_64b_imm, ID_alu64 : std_logic;
    signal ID_addr_calc, ID_write_en, ID_read_en, ID_force_imm, ID_sign_ext : std_logic;
    signal ID_value_size : std_logic_vector (1 downto 0);
    signal ID_mem_to_reg, ID_reg_write, ID_finish, ID_atomic, ID_write_r0 : std_logic;
    signal ID_alu_en, ID_use_dst, ID_use_src, ID_call, ID_call_2 : std_logic;
    signal ID_num_params : std_logic_vector (2 downto 0);

    signal ID_call_error : std_logic;

    -- EX signals
    signal EX_taken, EX_taken_branch, EX_atomic_fetch : std_logic;
    signal EX_PC_taken : std_logic_vector (11 downto 0);
    signal EX_cmpxchg_token, EX_A, EX_B, EX_imm64 : std_logic_vector (63 downto 0);
    signal EX_imm32 : std_logic_vector (31 downto 0);
    signal EX_offset : std_logic_vector (15 downto 0);
    signal EX_opcode : std_logic_vector (7 downto 0);
    signal EX_dst, EX_src, EX_dst_reg : std_logic_vector (3 downto 0);

    signal EX_branch, EX_64b_imm, EX_alu64, EX_write_r0 : std_logic;
    signal EX_addr_calc, EX_write_en, EX_read_en, EX_force_imm, EX_sign_ext : std_logic;
    signal EX_value_size : std_logic_vector (1 downto 0);
    signal EX_mem_to_reg, EX_reg_write, EX_atomic : std_logic;
    signal EX_alu_en, EX_use_dst, EX_use_src, EX_call : std_logic;

    signal EX_source, EX_signed_alu, EX_alu_ready, EX_await_call, EX_volatile_taken_branch, EX_saved_taken_branch : std_logic;
    signal EX_op, EX_atomic_op : std_logic_vector (3 downto 0);

    signal EX_operand_A, EX_operand_B : std_logic_vector (63 downto 0);
    signal EX_fw_operand_A, EX_fw_operand_B, EX_fw_cmpxchg_token, EX_B_source, EX_stx_data : std_logic_vector (63 downto 0);
    signal EX_fw_A_from, EX_fw_B_from, EX_fw_token_from : std_logic_vector (1 downto 0);

    signal EX_base_addr, EX_sx_offset, EX_addr, EX_alu_output, EX_C : std_logic_vector (63 downto 0);

    signal EX_alu_op : std_logic_vector (3 downto 0);

    -- MEM signals
    signal MEM_write_en, MEM_read_en, MEM_sign_ext, MEM_write_r0 : std_logic;
    signal MEM_value_size : std_logic_vector (1 downto 0);
    signal MEM_mem_to_reg, MEM_reg_write, MEM_atomic, MEM_call : std_logic;
    signal MEM_cmpxchg_token, MEM_data, MEM_C : std_logic_vector (63 downto 0);
    signal MEM_atomic_op, MEM_dst : std_logic_vector (3 downto 0);

    signal MEM_ex_value : std_logic_vector (63 downto 0);
    signal MEM_mem_ready : std_logic;

    signal MEM_await_call : std_logic;
    signal MEM_call_value : std_logic_vector (63 downto 0);

    signal MEM_call_error : std_logic;

    -- WB signals
    signal WB_dst_reg, WB_reg_bank_dst_reg : std_logic_vector (3 downto 0);
    signal WB_reg_value, WB_reg_bank_input : std_logic_vector (63 downto 0);
    signal WB_mem_to_reg, WB_reg_write, WB_reg_bank_reg_write : std_logic;

    signal WB_sign_ext, WB_write_r0 : std_logic;
    signal WB_value_size : std_logic_vector (1 downto 0);
    signal WB_ex_value, WB_mem_value, WB_mem_raw_value : std_logic_vector (63 downto 0);


    -- Flow control: start, sleep, stop, exceptions...

      -- Flags
    signal FLAG_finish, FLAG_exception, FLAG_sleep : std_logic;
    signal CTRL_saved_finish, CTRL_saved_exception : std_logic;

    signal CTRL_flush_stage, CTRL_exception_stage : std_logic_vector (1 downto 0);
    signal CTRL_flushed, CTRL_flush_pipeline, CTRL_exception : std_logic;

    signal CTRL_PC : std_logic_vector (11 downto 0);

    signal ID_make_noop, EX_make_noop, MEM_make_noop, WB_make_noop : std_logic;
    signal WB_is_noop, MEM_is_noop, EX_is_noop, ID_is_noop : std_logic;

    signal CTRL_block_IF, CTRL_block_ID, CTRL_block_EX, CTRL_block_MEM : std_logic;

    signal IF_gen_exception_in, ID_gen_exception_in, EX_gen_exception_in, MEM_gen_exception_in : std_logic;


      -- Saved PC through stages that can produce exception
    signal ID_PC, EX_PC, MEM_PC : std_logic_vector (11 downto 0);


      -- Static signals for components
    signal buffer_IF_discard : std_logic;
    signal register_bank_get_params : std_logic_vector(1 downto 0);

    signal buffer_ID_branch, buffer_ID_write_en, buffer_ID_read_en : std_logic;
    signal buffer_ID_reg_write, buffer_ID_atomic, buffer_ID_write_r0 : std_logic;
    signal buffer_ID_alu_en, buffer_ID_call : std_logic;

    signal buffer_EX_write_en, buffer_EX_read_en : std_logic;
    signal buffer_EX_reg_write, buffer_EX_write_r0 : std_logic;

    signal buffer_MEM_reg_write, buffer_MEM_write_r0 : std_logic;

    signal go_ID, go_EX : std_logic;

begin

    reset <= CORE_reset;

    ----------------------------------------------------------------------------

    load_PC <= not (block_IF or block_ID or block_EX or block_MEM or CTRL_block_IF);
    load_IF <= not (block_ID or block_EX or block_MEM or CTRL_block_ID);
    load_ID <= not (block_EX or block_MEM or CTRL_block_EX);
    load_EX <= not (block_MEM or CTRL_block_MEM);
    load_MEM <= not block_MEM;

     --If HFU parameters p4 & p5 are wanted to be accesed from forwarding system
     --Hazard Unit should be changed in that case, in order to gain on cycle when
     --call instruction with num_params >= 4 goes after producer of p4 or p5.
    --load_MEM <= not block_MEM; -- Only when core is active and no exception is produced in MEM stage


    block_EX <= '1' when EX_alu_ready = '0' or EX_await_call = '1' else '0';
    block_MEM <= '1' when MEM_mem_ready = '0' or MEM_await_call = '1' else '0';

    ----------------------------------------------------------------------------
    PC: Register_N ------------------------------------------------------- IF --
        generic map ( SIZE => 12 )
        port map (
            clk => clk, reset => reset, load => load_PC,    
            input => IF_PC_input, output => IF_PC
        );

    IF_PC_plus_1 <= IF_PC + "000000000001";

    -- Inst_RAM -- -- -- -- --
    IMEM_addr <= IF_PC;
    IMEM_read_en <= load_IF;
    IF_IR <= IMEM_output;
    -- -- -- -- -- -- -- -- --

    IF_imm32 <= IF_IR(63 downto 32);

    ----------------------------------------------------------------------------
    buffer_IF_ID_block: Buffer_IF_ID ----------------------------------------- ID --
        port map (
            clk => clk,
            reset => reset,
            load => load_IF,
            IF_IR => IF_IR,
            IF_PC1 => IF_PC_plus_1,
            IF_discard => buffer_IF_discard,
            IF_call_2 => ID_call,
            
            ID_IR => ID_IR,
            ID_PC1 => ID_PC_plus_1,
            ID_discard => ID_discard,
            ID_call_2 => ID_call_2
        );

    buffer_IF_discard <= ID_discard_IF or ID_jump_or_taken_branch or ID_make_noop;

    ID_opcode <= ID_IR(7 downto 0);
    ID_dst_reg <= ID_IR(11 downto 8);
    ID_src_reg <= ID_IR(15 downto 12);
    ID_offset <= ID_IR(31 downto 16);
    ID_imm32 <= ID_IR(63 downto 32);


    ID_discard_ID <= ID_discard or EX_taken_branch;

    
       -- call instruction must block IF in order to inject a partial NOOP without it affecting PC
    block_IF <= ID_call;

    -- control unit --
    control_unit_block: BPF_Control_Unit 
        port map (
            opcode => ID_opcode,
            dst => ID_dst_reg,
            src => ID_src_reg,
            offset => ID_offset,
            immediate => ID_imm32,
            discard => ID_discard_ID,

            ID_num_params => ID_num_params,

            -- Producer on EX info
            EX_reg_write => EX_reg_write,
            EX_write_r0 => EX_write_r0,
            EX_mem_to_reg => EX_mem_to_reg,
            EX_call => EX_call,
            EX_dst => EX_dst_reg,
        
            ID_jump => ID_jump,
            ID_branch => ID_branch,
            ID_32b_jump => ID_32b_jump,
            ID_64b_imm => ID_64b_imm,
            ID_alu64 => ID_alu64,
            ID_addr_calc => ID_addr_calc,
            ID_write_en => ID_write_en,
            ID_read_en => ID_read_en,
            ID_force_imm => ID_force_imm,
            ID_sign_ext => ID_sign_ext,
            ID_value_size => ID_value_size,
            ID_mem_to_reg => ID_mem_to_reg,
            ID_reg_write => ID_reg_write,
            ID_discard_IF => ID_discard_IF,
            ID_finish => ID_finish,
            ID_atomic => ID_atomic,
            ID_write_r0 => ID_write_r0,
            ID_alu_en => ID_alu_en,
            ID_call => ID_call,

            block_ID => block_ID
        );

    WB_reg_bank_dst_reg <= WB_dst_reg when CORE_reg_write = '0' else CORE_reg_dst;
    WB_reg_bank_input <= WB_reg_value when CORE_reg_write = '0' else CORE_reg_input;
    WB_reg_bank_reg_write <= WB_reg_write or CORE_reg_write;

    register_bank_block: BPF_Register_Bank
        port map (
            clk => clk,
            reset => reset,

            reg_A => ID_dst_reg,
            reg_B => ID_src_reg,
            reg_W => WB_reg_bank_dst_reg,
            input => WB_reg_bank_input,
            write_en => WB_reg_bank_reg_write,
            r0_write_en => WB_write_r0,
            get_params => register_bank_get_params,
            output_A => ID_A,
            output_B => ID_B,
            output_R0 => ID_R0
        );
    
    register_bank_get_params <= (1 => ID_call_2, 0 => ID_call);

    -- Jump logic and next PC --
    ID_jump_or_taken_branch <= ID_jump or EX_taken_branch;
    IF_PC_input <= IF_PC_plus_1 when ID_jump_or_taken_branch = '0' else PC_taken;
    PC_taken <= ID_PC_taken when EX_taken_branch = '0' else EX_PC_taken;
    ID_PC_taken <= ID_PC_plus_1 + ID_jump_offset;
    ID_jump_offset <= ID_offset(11 downto 0) when ID_32b_jump = '0' else ID_imm32(11 downto 0);


    ID_PC_taken_or_cmpxchg_token <= (51 downto 0 => '0') & ID_PC_taken when ID_branch = '1' else ID_R0;

    ----------------------------------------------------------------------------
    buffer_ID_EX_block: Buffer_ID_EX ----------------------------------------- EX --
        port map (
            clk => clk, reset => reset, load => load_ID,
            
            ID_branch => buffer_ID_branch,
            ID_64b_imm => ID_64b_imm,
            ID_alu64 => ID_alu64,
            ID_addr_calc => ID_addr_calc,
            ID_write_en => buffer_ID_write_en,
            ID_read_en => buffer_ID_read_en,
            ID_force_imm => ID_force_imm,
            ID_sign_ext => ID_sign_ext,
            ID_value_size => ID_value_size,
            ID_mem_to_reg => ID_mem_to_reg,
            ID_reg_write => buffer_ID_reg_write,
            ID_atomic => buffer_ID_atomic,
            ID_write_r0 => buffer_ID_write_r0,
            ID_alu_en => buffer_ID_alu_en,
            ID_call => buffer_ID_call,
            
            ID_PC_taken => ID_PC_taken_or_cmpxchg_token, ID_A => ID_A,
            ID_B => ID_B, ID_imm32 => ID_imm32, ID_offset => ID_offset,
            ID_opcode => ID_opcode, ID_dst => ID_dst_reg, ID_src => ID_src_reg,

            EX_branch => EX_branch, EX_64b_imm => EX_64b_imm, EX_alu64 => EX_alu64,
            EX_addr_calc => EX_addr_calc, EX_write_en => EX_write_en, EX_read_en => EX_read_en,
            EX_force_imm => EX_force_imm, EX_sign_ext => EX_sign_ext, EX_value_size => EX_value_size,
            EX_mem_to_reg => EX_mem_to_reg, EX_reg_write => EX_reg_write, EX_atomic => EX_atomic,
            EX_write_r0 => EX_write_r0, EX_alu_en => EX_alu_en, EX_call => EX_call,

            EX_PC_taken => EX_cmpxchg_token, EX_A => EX_A, EX_B => EX_B,
            EX_imm32 => EX_imm32, EX_offset => EX_offset, EX_opcode => EX_opcode,
            EX_dst => EX_dst, EX_src => EX_src
        );

    buffer_ID_branch <= ID_branch           and not (block_ID or EX_make_noop); -- Bubble
    buffer_ID_write_en <= ID_write_en       and not (block_ID or EX_make_noop); -- Bubble
    buffer_ID_read_en <= ID_read_en         and not (block_ID or EX_make_noop); -- Bubble
    buffer_ID_reg_write <= ID_reg_write     and not (block_ID or EX_make_noop); -- Bubble
    buffer_ID_atomic <= ID_atomic           and not (block_ID or EX_make_noop); -- Bubble
    buffer_ID_write_r0 <= ID_write_r0       and not (block_ID or EX_make_noop); -- Bubble
    buffer_ID_alu_en <= ID_alu_en           and not (block_ID or EX_make_noop); -- Bubble
    buffer_ID_call <= ID_call               and not (block_ID or EX_make_noop); -- Bubble
      -- --

    EX_source <= EX_opcode(3);
    EX_signed_alu <= EX_offset(0);
    EX_op <= EX_opcode(7 downto 4);
    EX_atomic_op <= EX_imm64(7 downto 4);

    EX_pc_taken <= EX_cmpxchg_token(11 downto 0);

    -- Operands --
    forwarding_unit_block: BPF_Forwarding_Unit
        port map (
            EX_dst => EX_dst,
            EX_src => EX_src,
            EX_call => EX_call,

            MEM_reg_write => MEM_reg_write,
            MEM_write_r0 => MEM_write_r0,
            MEM_dst => MEM_dst,
    
            WB_reg_write => WB_reg_write,
            WB_write_r0 => WB_write_r0,
            WB_mem_to_reg => WB_mem_to_reg,
            WB_dst => WB_dst_reg,

            EX_fw_A_from => EX_fw_A_from,
            EX_fw_B_from => EX_fw_B_from,
            EX_fw_token_from => EX_fw_token_from
        );

    EX_imm64 <= (31 downto 0 => EX_imm32(31)) & EX_imm32 when EX_64b_imm = '0' else
            ID_imm32 & EX_imm32;


    EX_fw_cmpxchg_token <= EX_cmpxchg_token when EX_fw_token_from = BPF_NO_FW else
                           MEM_ex_value     when EX_fw_token_from = BPF_FW_FROM_MEM else
                           WB_mem_value     when EX_fw_token_from = BPF_FW_FROM_WB_M else
                           WB_ex_value      when EX_fw_token_from = BPF_FW_FROM_WB_E;

    EX_fw_operand_A <= EX_A         when EX_fw_A_from = BPF_NO_FW else
                       MEM_ex_value when EX_fw_A_from = BPF_FW_FROM_MEM else
                       WB_mem_value when EX_fw_A_from = BPF_FW_FROM_WB_M else
                       WB_ex_value  when EX_fw_A_from = BPF_FW_FROM_WB_E;

    -- Operands must be truncated on stage EX after forwarding cause 32 bit
    -- operations assume 0 extended values and not always come from ID stage.
    EX_operand_A <= EX_fw_operand_A when EX_alu64 = '1' else (31 downto 0 => '0') & EX_fw_operand_A(31 downto 0);
    
    
    EX_fw_operand_B <= EX_B         when EX_fw_B_from = BPF_NO_FW else
                       MEM_ex_value when EX_fw_B_from = BPF_FW_FROM_MEM else
                       WB_mem_value when EX_fw_B_from = BPF_FW_FROM_WB_M else
                       WB_ex_value  when EX_fw_B_from = BPF_FW_FROM_WB_E;

    EX_B_source <= EX_imm64 when (EX_source = BPF_FROM_IMM or EX_force_imm = '1') and EX_call = '0' else EX_fw_operand_B;

    EX_operand_B <= EX_B_source when EX_alu64 = '1' else (31 downto 0 => '0') & EX_B_source(31 downto 0);

    EX_stx_data <= EX_imm64 when EX_force_imm = '1' else
                   EX_fw_operand_A when EX_call = '1' else
                   EX_fw_operand_B;

    -- Units --
    branch_checker_block: BPF_Branch_Checker
        port map (
            operand_A => EX_operand_A, operand_B => EX_operand_B,
            op_cmp => EX_op, op_64b => EX_alu64, taken => EX_taken
        );


    EX_alu_op <= BPF_MOV when EX_64b_imm = '1' or EX_call = '1' else EX_op;
    
    alu_block: BPF_ALU
        port map (
            clk => clk,
            reset => reset,
            alu_en => EX_alu_en,

            operand_A => EX_operand_A,
            operand_B => EX_operand_B,
            op_alu => EX_alu_op,
            op_64b => EX_alu64,
            signed_alu => EX_signed_alu,
            sx_size => EX_value_size,
            alu_ready => EX_alu_ready,
            output => EX_alu_output
        );

    -- Addr calc --
    EX_sx_offset <= (47 downto 0 => EX_offset(15)) & EX_offset;

    EX_base_addr <= EX_fw_operand_A when EX_write_en = '1' else EX_fw_operand_B;
    
    EX_addr <= EX_base_addr + EX_sx_offset;


    EX_C <= EX_addr when EX_addr_calc = '1' else EX_alu_output;

    -- dst reg in case of atomic op with fetch --
    EX_atomic_fetch <= EX_write_en and EX_read_en;
    EX_dst_reg <= EX_src when EX_atomic_fetch = '1' else EX_dst;

    
    -- Make branches remember if it was taken (in case of sleep while being on EX)
    SAVE_TAKEN: process (clk)
    begin
        if (clk'event and clk = '1') then
            if (reset = '1') then
                EX_saved_taken_branch <= '0';
            else
                if (EX_volatile_taken_branch = '1' and CTRL_block_IF = '1') then
                    EX_saved_taken_branch <= '1';
                elsif (CTRL_block_IF = '0') then 
                    EX_saved_taken_branch <= '0';
                end if;
            end if;
        end if;
    end process;

    EX_volatile_taken_branch <= EX_branch and EX_taken; 
    
    EX_taken_branch <= EX_volatile_taken_branch or EX_saved_taken_branch;

    ----------------------------------------------------------------------------
    buffer_EX_MEM_block: Buffer_EX_MEM -------------------------------------- MEM --
        port map (
            clk => clk, reset => reset, load => load_EX,

            EX_write_en => buffer_EX_write_en,
            EX_read_en => buffer_EX_read_en,
            EX_sign_ext => EX_sign_ext,
            EX_value_size => EX_value_size,
            EX_mem_to_reg => EX_mem_to_reg,
            EX_reg_write => buffer_EX_reg_write,
            EX_atomic => EX_atomic,
            EX_write_r0 => buffer_EX_write_r0,
            EX_call => EX_call,

            EX_cmpxchg_token => EX_fw_cmpxchg_token,
            EX_data => EX_stx_data,
            EX_C => EX_C,
            EX_atomic_op => EX_atomic_op,
            EX_dst => EX_dst_reg,

            MEM_write_en => MEM_write_en, MEM_read_en => MEM_read_en, MEM_sign_ext => MEM_sign_ext,
            MEM_value_size => MEM_value_size, MEM_mem_to_reg => MEM_mem_to_reg,
            MEM_reg_write => MEM_reg_write, MEM_atomic => MEM_atomic, MEM_write_r0 => MEM_write_r0,
            MEM_call => MEM_call,
            MEM_cmpxchg_token => MEM_cmpxchg_token, MEM_data => MEM_data,
            MEM_C => MEM_C, MEM_atomic_op => MEM_atomic_op, MEM_dst => MEM_dst
        );

    buffer_EX_write_en <= EX_write_en                   and not (block_EX or MEM_make_noop); -- Bubble
    buffer_EX_read_en <= EX_read_en                     and not (block_EX or MEM_make_noop); -- Bubble
    buffer_EX_reg_write <= EX_reg_write                 and not (block_EX or MEM_make_noop); -- Bubble
    buffer_EX_write_r0 <= EX_write_r0                   and not (block_EX or MEM_make_noop); -- Bubble

    -- Data memmory interface -- -- -- -- -- --
    DMEM_addr <= MEM_C;
    DMEM_input <= MEM_data;
    DMEM_write_en <= MEM_write_en;
    DMEM_read_en <= MEM_read_en;
    DMEM_size <= MEM_value_size;

    DMEM_atomic <= MEM_atomic;
    DMEM_op <= MEM_atomic_op;
    DMEM_cmpxchg_token <= MEM_cmpxchg_token;
    
    MEM_mem_ready <= DMEM_ready;
    WB_mem_raw_value <= DMEM_output;
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

    MEM_ex_value <= MEM_call_value when MEM_call = '1' else MEM_C;

    ----------------------------------------------------------------------------
    buffer_MEM_WB_block: Buffer_MEM_WB --------------------------------------- WB --
        port map (
            clk => clk, reset => reset, load => load_MEM,

            MEM_mem_to_reg => MEM_mem_to_reg,
            MEM_reg_write => buffer_MEM_reg_write,
            MEM_sign_ext => MEM_sign_ext,
            MEM_value_size => MEM_value_size,
            MEM_write_r0 => buffer_MEM_write_r0,
            MEM_ex_value => MEM_ex_value,
            MEM_dst => MEM_dst,

            WB_mem_to_reg => WB_mem_to_reg, WB_reg_write => WB_reg_write,
            WB_sign_ext => WB_sign_ext, WB_value_size => WB_value_size, WB_write_r0 => WB_write_r0,
            WB_ex_value => WB_ex_value, WB_dst => WB_dst_reg
        );

    buffer_MEM_reg_write <= MEM_reg_write      and not (block_MEM or WB_make_noop); -- Bubble
    buffer_MEM_write_r0 <= MEM_write_r0        and not (block_MEM or WB_make_noop); -- Bubble

    mem_byte_mask_block: BPF_Byte_Mask
        port map (
            input => WB_mem_raw_value,
            size => WB_value_size,
            sign_extend => WB_sign_ext,
            output => WB_mem_value
        );

    WB_reg_value <= WB_mem_value when WB_mem_to_reg = '1' else WB_ex_value;


    ----------------------------------------------------------------------------
    -- HELPER FUNCTIONS UNIT ---------------------------------------------------
    ----------------------------------------------------------------------------

    helper_functions_unit_block: BPF_Helper_Functions_Unit 
        port map (
            clk => clk,
            reset => reset,
    
            function_id => ID_imm32,

            -- Only signal when its going to advance, otherwise it could generate
            -- incorrect state inside HFU
            go_ID => go_ID,
            go_EX => go_EX,
    
            num_params => ID_num_params,
            error_function_id => ID_call_error,
    
            -- Five function parameters
            p1 => MEM_cmpxchg_token,
            p2 => MEM_data,
            p3 => MEM_C,
            p4 => EX_A,
            p5 => EX_B,
    
            await_EX => EX_await_call,
            await_MEM  => MEM_await_call,
            error_execution => MEM_call_error,
            result => MEM_call_value,

            -- MAP Unit bus
            HFU_MAP_ena => HFU_MAP_ena,
            HFU_MAP_id => HFU_MAP_id,
            HFU_MAP_output => HFU_MAP_output,

            HFU_MAP_req => HFU_MAP_req,
            HFU_MAP_granted => HFU_MAP_granted,
            HFU_MAP_bus_frame => HFU_MAP_bus_frame
        );

    go_ID <= ID_call and load_ID;
    go_EX <= EX_call and load_EX;

    ----------------------------------------------------------------------------
    -- EXTERNAL FLOW CONTROL AND EXCEPTIONS ------------------------------------
    ----------------------------------------------------------------------------

    exception_unit_block: BPF_Exception_Unit 
        port map (
            IF_gen_exception => IF_gen_exception_in,
            ID_gen_exception => ID_gen_exception_in,
            EX_gen_exception => EX_gen_exception_in,
            MEM_gen_exception => MEM_gen_exception_in,

            opcode => ID_opcode,
            dst => ID_dst_reg,
            src => ID_src_reg,
            offset => ID_offset,
            immediate => ID_imm32,
            discard_ID => ID_discard_ID,
            
            exception => CTRL_exception,
            exception_stage => CTRL_exception_stage
        );
    
    IF_gen_exception_in <= '0';
    ID_gen_exception_in <= ID_call_error;
    EX_gen_exception_in <= '0';
    MEM_gen_exception_in <= MEM_call_error or DMEM_error;

    -- This processor sleeps while signal is active, but awakes if it is not active without latency
    FLAG_sleep <= CORE_sleep; 

    -- Unlike sleep flag, exception and finish force the processor to stop and excecution cannot be
    -- resumed without a previous reset
    FLAGS_SYNC: process (clk)
    begin
        if (clk'event and clk = '1') then
            if (reset = '1') then
                CTRL_saved_exception <= '0';
                CTRL_saved_finish <= '0';
            else
                if (CTRL_exception = '1') then 
                    CTRL_saved_exception <= '1';
                end if;  
                if (ID_finish = '1') then
                    CTRL_saved_finish <= '1';
                end if; 
            end if;        
        end if;
    end process;

    FLAG_exception <= CTRL_saved_exception or CTRL_exception;
    FLAG_finish <= CTRL_saved_finish or ID_finish; 


    -- If active, pipeline is stopped at flush_stage and subsequent stages continue until they are done
    CTRL_flush_pipeline <= FLAG_exception or FLAG_finish or FLAG_sleep;

    CTRL_flush_stage <= CTRL_exception_stage when FLAG_exception = '1' else
                        BPF_STAGE_ID when FLAG_finish = '1' else BPF_STAGE_ID;

    -- Decoder
    ID_make_noop <= CTRL_flush_pipeline when CTRL_flush_stage = BPF_STAGE_IF else '0';
    EX_make_noop <= CTRL_flush_pipeline when CTRL_flush_stage = BPF_STAGE_ID else '0';
    MEM_make_noop <= CTRL_flush_pipeline when CTRL_flush_stage = BPF_STAGE_EX else '0';
    WB_make_noop <= CTRL_flush_pipeline when CTRL_flush_stage = BPF_STAGE_MEM else '0';

    -- Output on exception is PC of the instruction that generated exception

    PC_if_save: Register_N generic map ( SIZE => 12 ) port map (
            clk => clk, reset => reset, load => load_IF,    
            input => IF_PC, output => ID_PC
        );

    PC_ex_save: Register_N generic map ( SIZE => 12 ) port map (
            clk => clk, reset => reset, load => load_ID,    
            input => ID_PC, output => EX_PC
        );

    PC_mem_save: Register_N generic map ( SIZE => 12 ) port map (
            clk => clk, reset => reset, load => load_EX,    
            input => EX_PC, output => MEM_PC
        );

    CTRL_PC <= IF_PC when CTRL_exception_stage = BPF_STAGE_IF else
               ID_PC when CTRL_exception_stage = BPF_STAGE_ID else
               EX_PC when CTRL_exception_stage = BPF_STAGE_EX else
               MEM_PC when CTRL_exception_stage = BPF_STAGE_MEM;

    CORE_output <= (51 downto 0 => '0') & CTRL_PC when FLAG_exception = '1' and ID_make_noop = '0' else ID_R0;


    -- Notify of exception, sleeping or program finished when pipeline is flushed
    
    ID_is_noop <= not (ID_64b_imm or ID_jump or ID_branch or ID_write_en or ID_read_en or ID_reg_write or ID_write_r0); 
    
    EX_is_noop <= not (EX_branch or EX_write_en or EX_read_en or EX_reg_write or EX_write_r0); 

    MEM_is_noop <= not (MEM_write_en or MEM_read_en or MEM_reg_write or MEM_write_r0); 

    WB_is_noop <= not (WB_reg_write or WB_write_r0);


    CTRL_flushed <= (WB_is_noop and WB_make_noop) or
                    (WB_is_noop and MEM_is_noop and MEM_make_noop) or
                    (WB_is_noop and MEM_is_noop and EX_is_noop and EX_make_noop) or
                    (WB_is_noop and MEM_is_noop and EX_is_noop and ID_is_noop and ID_make_noop);


    CORE_sleeping <= CTRL_flushed and FLAG_sleep         and not FLAG_exception and not FLAG_finish;
    CORE_finish <= CTRL_flushed and FLAG_finish          and not (FLAG_exception and not ID_make_noop); -- IF exceptions do not prevail against finish flag
    CORE_exception <= CTRL_flushed and FLAG_exception    and not (FLAG_finish and ID_make_noop);

    -- Block previous stages
    CTRL_block_IF <= ID_make_noop or EX_make_noop or MEM_make_noop or WB_make_noop;
    CTRL_block_ID <= EX_make_noop or MEM_make_noop or WB_make_noop;
    CTRL_block_EX <= MEM_make_noop or WB_make_noop;
    CTRL_block_MEM <= WB_make_noop;


end Behavioral;
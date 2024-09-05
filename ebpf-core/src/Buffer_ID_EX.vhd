--------------------------------------------------------------------------------
-- Project Name: A basic processor core for running BPF programs
-- Author:       Fernando Lahoz Bernad
--
-- Description:  Register buffer for transition between stages ID-EX
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity Buffer_ID_EX is
    port (
        clk : in std_logic;
        reset : in std_logic;
        load : in std_logic;

        -- Input control signals
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
        
        -- Input values
        ID_PC_taken : in std_logic_vector (63 downto 0);
        ID_A : in std_logic_vector (63 downto 0);
        ID_B : in std_logic_vector (63 downto 0);
        ID_imm32 : in std_logic_vector (31 downto 0);
        ID_offset : in std_logic_vector (15 downto 0);
        ID_opcode : in std_logic_vector (7 downto 0);
        ID_dst : in std_logic_vector (3 downto 0);
        ID_src : in std_logic_vector (3 downto 0);

        -- Output
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
end Buffer_ID_EX;

architecture Behavioral of Buffer_ID_EX is
begin
    SYNC_PROC: process (clk)
    begin
        if (clk'event and clk = '1') then
            if (reset = '1') then
                EX_branch <= '0';
                EX_64b_imm <= '0';
                EX_alu64 <= '0';
                EX_addr_calc <= '0';
                EX_write_en <= '0';
                EX_read_en <= '0';
                EX_force_imm <= '0';
                EX_sign_ext <= '0';
                EX_value_size <= ( others => '0');
                EX_mem_to_reg <= '0';
                EX_reg_write <= '0';
                EX_atomic <= '0';
                EX_write_r0 <= '0';
                EX_alu_en <= '0';
                EX_call <= '0';

                EX_PC_taken <= ( others => '0');
                EX_A <= ( others => '0');
                EX_B <= ( others => '0');
                EX_imm32 <= ( others => '0');
                EX_offset <= ( others => '0');
                EX_opcode <= ( others => '0');
                EX_dst <= ( others => '0');
                EX_src <= ( others => '0');
            elsif (load = '1') then 
                EX_branch <= ID_branch;
                EX_64b_imm <= ID_64b_imm;
                EX_alu64 <= ID_alu64;
                EX_addr_calc <= ID_addr_calc;
                EX_write_en <= ID_write_en;
                EX_read_en <= ID_read_en;
                EX_force_imm <= ID_force_imm;
                EX_sign_ext <= ID_sign_ext;
                EX_value_size <= ID_value_size;
                EX_mem_to_reg <= ID_mem_to_reg;
                EX_reg_write <= ID_reg_write;
                EX_atomic <= ID_atomic;
                EX_write_r0 <= ID_write_r0;
                EX_alu_en <= ID_alu_en;
                EX_call <= ID_call;

                EX_PC_taken <= ID_PC_taken;
                EX_A <= ID_A;
                EX_B <= ID_B;
                EX_imm32 <= ID_imm32;
                EX_offset <= ID_offset;
                EX_opcode <= ID_opcode;
                EX_dst <= ID_dst;
                EX_src <= ID_src;
            end if;        
        end if;
   end process;
end Behavioral;
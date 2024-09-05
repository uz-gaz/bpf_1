--------------------------------------------------------------------------------
-- Project Name: A basic processor core for running BPF programs
-- Author:       Fernando Lahoz Bernad
--
-- Description:  Register buffer for transition between stages EX-MEM
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity Buffer_EX_MEM is
    port (
        clk : in std_logic;
        reset : in std_logic;
        load : in std_logic;

        -- Input control signals
        EX_write_en : in std_logic;
        EX_read_en : in std_logic;
        EX_sign_ext : in std_logic;
        EX_value_size : in std_logic_vector (1 downto 0);
        EX_mem_to_reg : in std_logic;
        EX_reg_write : in std_logic;
        EX_atomic : in std_logic;
        EX_write_r0 : in std_logic;
        EX_call : in std_logic;

        -- Input values
        EX_cmpxchg_token : in std_logic_vector (63 downto 0);
        EX_data : in std_logic_vector (63 downto 0);
        EX_C : in std_logic_vector (63 downto 0);
        EX_atomic_op : in std_logic_vector (3 downto 0);
        EX_dst : in std_logic_vector (3 downto 0);

        -- Output
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
end Buffer_EX_MEM;

architecture Behavioral of Buffer_EX_MEM is
begin
    SYNC_PROC: process (clk)
    begin
        if (clk'event and clk = '1') then
            if (reset = '1') then
                MEM_write_en <= '0';
                MEM_read_en <= '0';
                MEM_sign_ext <= '0';
                MEM_value_size <= ( others => '0');
                MEM_mem_to_reg <= '0';
                MEM_reg_write <= '0';
                MEM_atomic <= '0';
                MEM_write_r0 <= '0';
                MEM_call <= '0';

                MEM_cmpxchg_token <= ( others => '0');
                MEM_data <= ( others => '0');
                MEM_C <= ( others => '0');
                MEM_atomic_op <= ( others => '0');
                MEM_dst <= ( others => '0');
            elsif (load = '1') then 
                MEM_write_en <= EX_write_en;
                MEM_read_en <= EX_read_en;
                MEM_sign_ext <= EX_sign_ext;
                MEM_value_size <= EX_value_size;
                MEM_mem_to_reg <= EX_mem_to_reg;
                MEM_reg_write <= EX_reg_write;
                MEM_atomic <= EX_atomic;
                MEM_write_r0 <= EX_write_r0;
                MEM_call <= EX_call;

                MEM_cmpxchg_token <= EX_cmpxchg_token;
                MEM_data <= EX_data;
                MEM_C <= EX_C;
                MEM_atomic_op <= EX_atomic_op;
                MEM_dst <= EX_dst;
            end if;        
        end if;
   end process;
end Behavioral;
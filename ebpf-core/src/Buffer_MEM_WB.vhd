--------------------------------------------------------------------------------
-- Project Name: A basic processor core for running BPF programs
-- Author:       Fernando Lahoz Bernad
--
-- Description:  Register buffer for transition between stages MEM-WB
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity Buffer_MEM_WB is
    port (
        clk : in std_logic;
        reset : in std_logic;
        load : in std_logic;

        -- Input control signals
        MEM_mem_to_reg : in std_logic;
        MEM_reg_write : in std_logic;
        MEM_sign_ext : in std_logic;
        MEM_value_size : in std_logic_vector (1 downto 0);
        MEM_write_r0 : in std_logic;
        
        -- Input values
        --MEM_mem_value : in std_logic_vector (63 downto 0); -- Inside Mem_Interface module
        MEM_ex_value : in std_logic_vector (63 downto 0);
        MEM_dst : in std_logic_vector (3 downto 0);

        -- Output
        WB_mem_to_reg : out std_logic;
        WB_reg_write : out std_logic;
        WB_sign_ext : out std_logic;
        WB_value_size : out std_logic_vector (1 downto 0);
        WB_write_r0 : out std_logic;

        --WB_mem_value : out std_logic_vector (63 downto 0);
        WB_ex_value : out std_logic_vector (63 downto 0);
        WB_dst : out std_logic_vector (3 downto 0)
    );
end Buffer_MEM_WB;

architecture Behavioral of Buffer_MEM_WB is
begin
    SYNC_PROC: process (clk)
    begin
        if (clk'event and clk = '1') then
            if (reset = '1') then
                WB_mem_to_reg <= '0';
                WB_reg_write <= '0';
                WB_sign_ext <= '0';
                WB_value_size <= "00";
                WB_write_r0 <= '0';
                
                --WB_mem_value <= ( others => '0');
                WB_ex_value <= ( others => '0');
                WB_dst <= ( others => '0');
            elsif (load = '1') then 
                WB_mem_to_reg <= MEM_mem_to_reg;
                WB_reg_write <= MEM_reg_write;
                WB_sign_ext <= MEM_sign_ext;
                WB_value_size <= MEM_value_size;
                WB_write_r0 <= MEM_write_r0;
                
                --WB_mem_value <= MEM_mem_value;
                WB_ex_value <= MEM_ex_value;
                WB_dst <= MEM_dst;
            end if;        
        end if;
   end process;
end Behavioral;
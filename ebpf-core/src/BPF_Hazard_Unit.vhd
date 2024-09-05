--------------------------------------------------------------------------------
-- Project Name: A basic processor core for running BPF programs
-- Author:       Fernando Lahoz Bernad
--
-- Description:  Hazard unit for a BPF processor. Only reports data hazards!!!!!
--               Control and structural hazards are directly handled by
--               data path jumping logic and ready signals.
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

use work.bpf.all;

entity BPF_Hazard_Unit is
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
end BPF_Hazard_Unit;

architecture Behavioral of BPF_Hazard_Unit is
    signal ID_dst_consumed_from_EX, ID_src_consumed_from_EX : std_logic;
    signal ID_r0_consumed_from_EX: std_logic;
    signal ID_call_r1_2_3_consumed_from_EX, ID_call_r4_5_consumed_from_EX : std_logic;
begin

    -- Stop (on ID) if data is produced on MEM stage but that instruction is currently on EX stage
    ID_r0_consumed_from_EX <= '1' when EX_reg_write = '1' and EX_dst = "0000" and ID_use_r0 = '1' else
                              '1' when EX_write_r0 = '1' and ID_use_r0 = '1' else '0';
    
    ID_dst_consumed_from_EX <= '1' when EX_reg_write = '1' and EX_dst = ID_dst and ID_use_dst = '1' else
                               '1' when EX_write_r0 = '1' and ID_dst = "0000" and ID_use_dst = '1' else '0';

    ID_src_consumed_from_EX <= '1' when EX_reg_write = '1' and EX_dst = ID_src and ID_use_src = '1' else
                               '1' when EX_write_r0 = '1' and ID_src = "0000" and ID_use_src = '1' else '0';


    ID_call_r1_2_3_consumed_from_EX <= '1' when ID_call = '1' and EX_reg_write = '1' and (EX_dst > 0 and EX_dst <= 3 and EX_dst <= ID_num_params) else '0';
    
    ID_call_r4_5_consumed_from_EX <= '1' when ID_call = '1' and EX_reg_write = '1' and (EX_dst > 3 and EX_dst <= 5 and EX_dst <= ID_num_params) else '0';


    block_ID <= '1' when ID_dst_consumed_from_EX = '1' and EX_mem_producer = '1' else
                '1' when ID_src_consumed_from_EX = '1' and EX_mem_producer = '1' else
                '1' when ID_r0_consumed_from_EX = '1' and EX_mem_producer = '1' else
                '1' when ID_call_r1_2_3_consumed_from_EX = '1' and EX_mem_producer = '1' else
                '1' when ID_call_r4_5_consumed_from_EX = '1' else '0'; -- ensure call instruction will consume r4 and r5 from register bank

end Behavioral;
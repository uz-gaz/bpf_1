--------------------------------------------------------------------------------
-- Project Name: A basic processor core for running BPF programs
-- Author:       Fernando Lahoz Bernad
--
-- Description:  Forwarding unit for a BPF processor.
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

use work.bpf.all;

entity BPF_Forwarding_Unit is
    port (
        -- Consumer info
        EX_dst : in std_logic_vector (3 downto 0);
        EX_src : in std_logic_vector (3 downto 0);
        EX_call : in std_logic; 

        -- Producer on EX info -> fw from MEM stage
        MEM_reg_write : in std_logic;
        MEM_write_r0 : in std_logic;
        MEM_dst : in std_logic_vector (3 downto 0);

        -- Producer on MEM info -> fw from WB stage
        WB_reg_write : in std_logic;
        WB_write_r0 : in std_logic;
        WB_mem_to_reg : in std_logic;
        WB_dst : in std_logic_vector (3 downto 0);

        -- Output
        EX_fw_A_from : out std_logic_vector (1 downto 0);
        EX_fw_B_from : out std_logic_vector (1 downto 0);
        EX_fw_token_from : out std_logic_vector (1 downto 0)
    );
end BPF_Forwarding_Unit;

architecture Behavioral of BPF_Forwarding_Unit is
    signal consume_A_from_MEM, consume_B_from_MEM, consume_token_from_MEM : std_logic;
    signal consume_A_from_WB, consume_B_from_WB, consume_token_from_WB : std_logic;
begin

    consume_A_from_MEM <= '1' when MEM_reg_write = '1' and MEM_dst = "0010" and EX_call = '1' else -- call uses A as r2 placeholder instead of dst
                          '1' when MEM_reg_write = '1' and MEM_dst = EX_dst and EX_call = '0' else
                          '1' when MEM_write_r0 = '1' and EX_dst = "0000" and EX_call = '0' else '0';

    consume_B_from_MEM <= '1' when MEM_reg_write = '1' and MEM_dst = "0011" and EX_call = '1' else -- call uses B as r3 placeholder instead of src
                          '1' when MEM_reg_write = '1' and MEM_dst = EX_src and EX_call = '0' else
                          '1' when MEM_write_r0 = '1' and EX_src = "0000" and EX_call = '0' else '0';

    consume_token_from_MEM <= '1' when MEM_reg_write = '1' and MEM_dst = "0001" and EX_call = '1' else -- call uses token as r1 placeholder instead of r0
                              '1' when MEM_reg_write = '1' and MEM_dst = "0000" and EX_call = '0' else
                              '1' when MEM_write_r0 = '1' and EX_call = '0' else '0';


    consume_A_from_WB <= '1' when WB_reg_write = '1' and WB_dst = "0010" and EX_call = '1' else
                         '1' when WB_reg_write = '1' and WB_dst = EX_dst and EX_call = '0' else
                         '1' when WB_write_r0 = '1' and EX_dst = "0000" and EX_call = '0' else '0';
      
    consume_B_from_WB <= '1' when WB_reg_write = '1' and WB_dst = "0011" and EX_call = '1' else
                         '1' when WB_reg_write = '1' and WB_dst = EX_src and EX_call = '0' else
                         '1' when WB_write_r0 = '1' and EX_src = "0000" and EX_call = '0' else '0';

    consume_token_from_WB <= '1' when WB_reg_write = '1' and WB_dst = "0001" and EX_call = '1' else
                             '1' when WB_reg_write = '1' and WB_dst = "0000" and EX_call = '0' else
                             '1' when WB_write_r0 = '1' and EX_call = '0' else '0';


    EX_fw_A_from <= BPF_FW_FROM_MEM when consume_A_from_MEM = '1' else
                    BPF_FW_FROM_WB_E when consume_A_from_WB = '1' and WB_mem_to_reg = '0' else 
                    BPF_FW_FROM_WB_M when consume_A_from_WB = '1' and WB_mem_to_reg = '1' else BPF_NO_FW;
                    
    EX_fw_B_from <= BPF_FW_FROM_MEM when consume_B_from_MEM = '1' else
                    BPF_FW_FROM_WB_E when consume_B_from_WB = '1' and WB_mem_to_reg = '0' else 
                    BPF_FW_FROM_WB_M when consume_B_from_WB = '1' and WB_mem_to_reg = '1' else BPF_NO_FW;

    EX_fw_token_from <= BPF_FW_FROM_MEM when consume_token_from_MEM = '1' else
                        BPF_FW_FROM_WB_E when consume_token_from_WB = '1' and WB_mem_to_reg = '0' else 
                        BPF_FW_FROM_WB_M when consume_token_from_WB = '1' and WB_mem_to_reg = '1' else BPF_NO_FW;

end Behavioral;
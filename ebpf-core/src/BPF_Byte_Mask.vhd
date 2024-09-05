--------------------------------------------------------------------------------
-- Project Name: A basic processor core for running BPF programs
-- Author:       Fernando Lahoz Bernad
--
-- Description:  Module to select less significant bits and sign extend if
--               wanted. Size is coded the same way it is inside eBPF's opcode
--               size bits for MEM class instructions. That means:
--                   
--                    size | mask width
--                    ---- + -----------
--                      00 | 4 bytes
--                      01 | 2 bytes
--                      10 | 1 byte
--                      11 | 8 bytes
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

use work.bpf.all;

entity BPF_Byte_Mask is
    port (
        input : in std_logic_vector (63 downto 0);
        size : in std_logic_vector (1 downto 0);
        sign_extend : in std_logic;
        
        output : out std_logic_vector (63 downto 0)
    );
end BPF_Byte_Mask;

architecture Behavioral of BPF_Byte_Mask is

    signal or_mask, and_mask : std_logic_vector (63 downto 0);
    signal sx_8b, sx_16b, sx_32b : std_logic;

    signal or_mask_15_8, or_mask_31_16, or_mask_63_32 : std_logic;
    signal and_mask_15_8, and_mask_31_16, and_mask_63_32 : std_logic; 

begin

    sx_8b  <= sign_extend and input(7);
    sx_16b <= sign_extend and input(15);
    sx_32b <= sign_extend and input(31);

    or_mask_63_32 <= '1' when (sx_8b = '1' and size = BPF_SIZE8) else
                     '1' when (sx_16b = '1' and size = BPF_SIZE16) else
                     '1' when (sx_32b = '1' and size = BPF_SIZE32) else '0';

    or_mask_31_16 <= '1' when (sx_8b = '1' and size = BPF_SIZE8) else
                     '1' when (sx_16b = '1' and size = BPF_SIZE16) else '0';
    
    or_mask_15_8 <= '1' when (sx_8b = '1' and size = BPF_SIZE8) else '0';

    or_mask <= (63 downto 32 => or_mask_63_32,
                31 downto 16 => or_mask_31_16,
                15 downto 8 => or_mask_15_8,
                others => '0');

    and_mask_63_32 <= '1' when (size = BPF_SIZE64) else '0';

    and_mask_31_16 <= '1' when (size = BPF_SIZE32) else
                      '1' when (size = BPF_SIZE64) else '0';
    
    and_mask_15_8 <= '1' when (size = BPF_SIZE16) else
                     '1' when (size = BPF_SIZE32) else
                     '1' when (size = BPF_SIZE64) else '0';

    and_mask <= (63 downto 32 => and_mask_63_32,
                 31 downto 16 => and_mask_31_16,
                 15 downto 8 => and_mask_15_8,
                 others => '1');

    output <= (input and and_mask) or or_mask;
    
end Behavioral;